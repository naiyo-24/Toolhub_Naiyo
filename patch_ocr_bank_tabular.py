import os
import re

backend_path = "/Users/sayarpaul/Project/Toolhub_Naiyo_Backend/routes/ocr.py"

with open(backend_path, "r") as f:
    content = f.read()

target = """    elif doc_type == "BANK STATEMENT" or "BANK STATEMENT" in doc_type:
        def extract_bank_val(label_pattern, text):
            # Generalized regex: Looks for the label, optional colon/dash, then captures the rest of the line or until a double space
            match = re.search(label_pattern + r'\\s*[:\\-]?\\s*([^\\n]+)', text, re.IGNORECASE)
            if not match: return None
            val = match.group(1).strip()
            # Clean up trailing artifacts like another field starting on the same line
            val = re.sub(r'\\s{2,}.*', '', val)
            return val if val else None

        # Extract Fields
        cust_name = extract_bank_val(r'(?:Customer\\s+Name|Name)', extracted_text)
        cust_id = extract_bank_val(r'(?:Customer\\s+ID|Cust\\s+ID)', extracted_text)
        acc_num = extract_bank_val(r'(?:Account\\s+Number|A/c\\s+No\\.?)', extracted_text)
        acc_type = extract_bank_val(r'(?:Account\\s+Type|A/c\\s+Type)', extracted_text)
        bank_name = extract_bank_val(r'Bank\\s+Name', extracted_text)
        branch_name = extract_bank_val(r'(?:Branch\\s+Name|Branch)', extracted_text)
        ifsc = extract_bank_val(r'(?:IFSC\\s*Code|IFSC)', extracted_text)
        acc_holder_type = extract_bank_val(r'Account\\s+Holder\\s+Type', extracted_text)
        address = extract_bank_val(r'(?:Customer\\s+Address|Address)', extracted_text)
        mobile = extract_bank_val(r'(?:Mobile\\s+Number|Mobile|Phone)', extracted_text)
        currency = extract_bank_val(r'Currency', extracted_text)
        start_date = extract_bank_val(r'(?:Statement\\s+(?:Start\\s+)?Date|From\\s+Date)', extracted_text)
        end_date = extract_bank_val(r'(?:Statement\\s+(?:End\\s+)?Date|To\\s+Date)', extracted_text)
        opening_bal = extract_bank_val(r'Opening\\s+Balance', extracted_text)
        closing_bal = extract_bank_val(r'Closing\\s+Balance', extracted_text)
        lien_amt = extract_bank_val(r'Lien\\s+Amount', extracted_text)
        nomination = extract_bank_val(r'Nomination\\s+(?:Status|Registered)', extracted_text)"""

replacement = """    elif doc_type == "BANK STATEMENT" or "BANK STATEMENT" in doc_type:
        def extract_bank_val(label_pattern, text):
            match = re.search(label_pattern + r'\\s*[:\\-]?\\s*([^\\n]+)', text, re.IGNORECASE)
            if not match: return None
            val = match.group(1).strip()
            val = re.sub(r'\\s{2,}.*', '', val)
            return val if val else None

        # Bank Name (Generalized or Explicit)
        bank_name_match = re.search(r'Account Statement\\s+(.*?[Bb]ank)', extracted_text)
        bank_name = bank_name_match.group(1).strip() if bank_name_match else extract_bank_val(r'Bank\\s+Name', extracted_text)

        # Customer Name (Table format or Label format)
        cust_name_match = re.search(r'Name Holding Status Customer ID\\s*\\n\\s*([A-Za-z\\s]+?)\\s+(?:Primary|Joint)', extracted_text)
        cust_name = cust_name_match.group(1).strip() if cust_name_match else extract_bank_val(r'(?:Customer\\s+Name|Name)', extracted_text)

        # Account Holder Type
        holder_type_match = re.search(r'([A-Za-z]+\\s+Holder)\\s+[A-Z0-9X]+', extracted_text)
        acc_holder_type = holder_type_match.group(1).strip() if holder_type_match else extract_bank_val(r'Account\\s+Holder\\s+Type', extracted_text)

        # Customer ID
        cust_id_match = re.search(r'(?:Primary|Joint) Holder\\s+([A-Z0-9X]+)', extracted_text)
        cust_id = cust_id_match.group(1).strip() if cust_id_match else extract_bank_val(r'(?:Customer\\s+ID|Cust\\s+ID)', extracted_text)

        # Account Number
        acc_num_match = re.search(r'Account No[^\\n]*\\n\\s*(\\d{9,18})', extracted_text)
        if not acc_num_match: acc_num_match = re.search(r'\\b(\\d{10,18})\\b', extracted_text)
        acc_num = acc_num_match.group(1).strip() if acc_num_match else extract_bank_val(r'(?:Account\\s+Number|A/c\\s+No\\.?)', extracted_text)

        # Account Type
        acc_type_match = re.search(r'Account No[^\\n]*\\n\\s*\\d{9,18}\\s+([A-Za-z\\s]+?)\\s+(?:INR|USD)', extracted_text, re.DOTALL)
        acc_type = acc_type_match.group(1).replace('\\n', ' ').strip() if acc_type_match else extract_bank_val(r'(?:Account\\s+Type|A/c\\s+Type)', extracted_text)
        if acc_type: acc_type = re.sub(r'\\s+', ' ', acc_type)

        # Currency, Lien, Balance
        currency = extract_bank_val(r'Currency', extracted_text)
        lien_amt = extract_bank_val(r'Lien\\s+Amount', extracted_text)
        closing_bal = extract_bank_val(r'Closing\\s+Balance', extracted_text)
        
        fin_match = re.search(r'\\b(INR|USD|EUR)\\b\\s+([\\d,\\.]+)\\s+([\\d,\\.]+)', extracted_text)
        if fin_match:
            if not currency: currency = fin_match.group(1).strip()
            if not lien_amt: lien_amt = fin_match.group(2).strip()
            if not closing_bal: closing_bal = fin_match.group(3).strip()

        # Dates
        start_date = extract_bank_val(r'(?:Statement\\s+(?:Start\\s+)?Date|From\\s+Date)', extracted_text)
        end_date = extract_bank_val(r'(?:Statement\\s+(?:End\\s+)?Date|To\\s+Date)', extracted_text)
        period_match = re.search(r'Period:\\s*([\\d\\sa-zA-Z]+?)\\s*-\\s*([\\d\\sa-zA-Z]+?)\\b', extracted_text)
        if period_match:
            if not start_date: start_date = period_match.group(1).strip()
            if not end_date: end_date = period_match.group(2).strip()

        # IFSC Code
        ifsc_match = re.search(r'IFSC\\s*(?:Code)?\\s*[:\\-]?\\s*([A-Z]{4}0[A-Z0-9]{6})', extracted_text, re.IGNORECASE)
        ifsc = ifsc_match.group(1).strip() if ifsc_match else extract_bank_val(r'(?:IFSC\\s*Code|IFSC)', extracted_text)

        # Nomination
        nomination_match = re.search(r'Nomination\\s+(?:Registered|Status)\\s*[:\\-]?\\s*([A-Za-z]+)', extracted_text, re.IGNORECASE)
        nomination = nomination_match.group(1).strip() if nomination_match else extract_bank_val(r'Nomination\\s+(?:Status|Registered)', extracted_text)

        # Mobile Number
        mobile_match = re.search(r'Mob\\.No.*?([+0-9X\\s]{10,})', extracted_text)
        mobile = mobile_match.group(1).strip() if mobile_match else extract_bank_val(r'(?:Mobile\\s+Number|Mobile|Phone)', extracted_text)

        # Address
        address = extract_bank_val(r'(?:Customer\\s+Address|Address)', extracted_text)
        if not address:
            address_match = re.search(r'Date:.*?\\n(.*?)(?=\\nMob\\.No)', extracted_text, re.DOTALL)
            if address_match:
                address = address_match.group(1).replace('\\n', ' ').strip()
                address = re.sub(r'\\s+', ' ', address)
                address = re.sub(r'Period:.*?(?=\\s)', '', address).strip()

        # Branch and Opening Balance not explicitly in IndusInd Header, fallback to generic
        branch_name = extract_bank_val(r'(?:Branch\\s+Name|Branch)', extracted_text)
        opening_bal = extract_bank_val(r'Opening\\s+Balance', extracted_text)"""

if target in content:
    content = content.replace(target, replacement)
    with open(backend_path, "w") as f:
        f.write(content)
    print("Successfully patched backend OCR logic for table-based Bank Statement extraction")
else:
    print("Target string not found in the file.")
