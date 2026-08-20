import os
import re

backend_path = "/Users/sayarpaul/Project/Toolhub_Naiyo_Backend/routes/ocr.py"

with open(backend_path, "r") as f:
    content = f.read()

target = """        # Currency, Lien, Balance
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
                address = re.sub(r'Period:.*?(?=\\s)', '', address).strip()"""

replacement = """        # Currency, Lien, Balance
        currency = None
        lien_amt = None
        closing_bal = None
        
        fin_match = re.search(r'\\b(INR|USD|EUR)\\b\\s+([\\d,\\.]+)\\s+([\\d,\\.]+)', extracted_text)
        if fin_match:
            currency = fin_match.group(1).strip()
            lien_amt = fin_match.group(2).strip()
            closing_bal = fin_match.group(3).strip()
        else:
            currency = extract_bank_val(r'Currency', extracted_text)
            lien_amt = extract_bank_val(r'Lien\\s+Amount', extracted_text)
            closing_bal = extract_bank_val(r'Closing\\s+Balance', extracted_text)

        # Dates
        start_date = extract_bank_val(r'(?:Statement\\s+(?:Start\\s+)?Date|From\\s+Date)', extracted_text)
        end_date = extract_bank_val(r'(?:Statement\\s+(?:End\\s+)?Date|To\\s+Date)', extracted_text)
        period_match = re.search(r'Period:\\s*(\\d{1,2}\\s+[A-Za-z]{3}\\s+\\d{4})\\s*-\\s*(\\d{1,2}\\s+[A-Za-z]{3}\\s+\\d{4})', extracted_text)
        if period_match:
            start_date = period_match.group(1).strip()
            end_date = period_match.group(2).strip()

        # IFSC Code
        ifsc_match = re.search(r'([A-Z]{4}0[A-Z0-9]{6})', extracted_text)
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
                address = re.sub(r'Period:\\s*\\d{1,2}\\s+[A-Za-z]{3}\\s+\\d{4}\\s*-\\s*\\d{1,2}\\s+[A-Za-z]{3}\\s+\\d{4}', '', address).strip()
                address = re.sub(r'\\s+', ' ', address).strip()"""

if target in content:
    content = content.replace(target, replacement)
    with open(backend_path, "w") as f:
        f.write(content)
    print("Successfully patched backend OCR logic for Bank Statement bugs")
else:
    print("Target string not found in the file.")
