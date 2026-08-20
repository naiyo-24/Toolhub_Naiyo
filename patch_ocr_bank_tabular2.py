import os
import re

backend_path = "/Users/sayarpaul/Project/Toolhub_Naiyo_Backend/routes/ocr.py"

with open(backend_path, "r") as f:
    content = f.read()

start_idx = content.find('elif doc_type == "BANK STATEMENT" or "BANK STATEMENT" in doc_type:')
end_idx = content.find('elif doc_type == "UDYAM" or "UDYAM" in doc_type:')

if start_idx != -1 and end_idx != -1:
    target = content[start_idx:end_idx]
    
    replacement = """elif doc_type == "BANK STATEMENT" or "BANK STATEMENT" in doc_type:
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
        opening_bal = extract_bank_val(r'Opening\\s+Balance', extracted_text)
        
        # Populate structured data unconditionally so they always appear in the UI
        structured["Customer Name"] = cust_name or "Not Found"
        structured["Customer ID"] = cust_id or "Not Found"
        structured["Account Number"] = acc_num or "Not Found"
        structured["Account Type"] = acc_type or "Not Found"
        structured["Bank Name"] = bank_name or "Not Found"
        structured["Branch Name"] = branch_name or "Not Found"
        structured["IFSC Code"] = ifsc or "Not Found"
        structured["Account Holder Type"] = acc_holder_type or "Not Found"
        structured["Customer Address"] = address or "Not Found"
        structured["Mobile Number"] = mobile or "Not Found"
        structured["Currency"] = currency or "Not Found"
        structured["Statement Start Date"] = start_date or "Not Found"
        structured["Statement End Date"] = end_date or "Not Found"
        structured["Opening Balance"] = opening_bal or "Not Found"
        structured["Closing Balance"] = closing_bal or "Not Found"
        structured["Lien Amount"] = lien_amt or "Not Found"
        structured["Nomination Status"] = nomination or "Not Found"

    """
    content = content[:start_idx] + replacement + content[end_idx:]
    with open(backend_path, "w") as f:
        f.write(content)
    print("Successfully patched backend OCR logic for table-based Bank Statement extraction")
else:
    print("Could not find start/end bounds")
