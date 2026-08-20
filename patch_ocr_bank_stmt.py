import os
import re

backend_path = "/Users/sayarpaul/Project/Toolhub_Naiyo_Backend/routes/ocr.py"

with open(backend_path, "r") as f:
    content = f.read()

target = """    elif doc_type == "UDYAM" or "UDYAM" in doc_type:"""

replacement = """    elif doc_type == "BANK STATEMENT" or "BANK STATEMENT" in doc_type:
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
        nomination = extract_bank_val(r'Nomination\\s+(?:Status|Registered)', extracted_text)
        
        # Populate structured data
        if cust_name: structured["Customer Name"] = cust_name
        if cust_id: structured["Customer ID"] = cust_id
        if acc_num: structured["Account Number"] = acc_num
        if acc_type: structured["Account Type"] = acc_type
        if bank_name: structured["Bank Name"] = bank_name
        if branch_name: structured["Branch Name"] = branch_name
        if ifsc: structured["IFSC Code"] = ifsc
        if acc_holder_type: structured["Account Holder Type"] = acc_holder_type
        if address: structured["Customer Address"] = address
        if mobile: structured["Mobile Number"] = mobile
        if currency: structured["Currency"] = currency
        if start_date: structured["Statement Start Date"] = start_date
        if end_date: structured["Statement End Date"] = end_date
        if opening_bal: structured["Opening Balance"] = opening_bal
        if closing_bal: structured["Closing Balance"] = closing_bal
        if lien_amt: structured["Lien Amount"] = lien_amt
        if nomination: structured["Nomination Status"] = nomination

    elif doc_type == "UDYAM" or "UDYAM" in doc_type:"""

if target in content:
    content = content.replace(target, replacement)
    with open(backend_path, "w") as f:
        f.write(content)
    print("Successfully patched backend OCR logic for Bank Statement extraction")
else:
    print("Target string not found in the file.")
