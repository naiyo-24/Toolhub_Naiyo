import os
import re

backend_path = "/Users/sayarpaul/Project/Toolhub_Naiyo_Backend/routes/ocr.py"

with open(backend_path, "r") as f:
    content = f.read()

target = """        # Resilient Bank Details Extraction
        udyam_bank = extract_between(extracted_text, "Bank Account Number", ["Employment Details", "Unit(s) Details", "Investment in Plant", "Official address of Enterprise"])
        if not udyam_bank: udyam_bank = extract_between(extracted_text, "Bank Details", ["Employment Details", "Unit(s) Details", "Official address"])
        
        # If block extraction fails, try a direct regex for IFSC and Account Number
        if not udyam_bank:
            bank_match = re.search(r'([A-Za-z\\s]+?)[\\s\\|\\n]+([A-Z]{4}0[A-Z0-9]{6})[\\s\\|\\n]+(\\d{9,18})', extracted_text)
            if bank_match:
                bank_name = re.sub(r'^[\\s\\|\\n]+', '', bank_match.group(1)).strip()
                # Clean up if it grabbed too much text before the bank name
                bank_name = bank_name.split('\\n')[-1].strip()
                udyam_bank = f"Bank: {bank_name}\\nIFSC: {bank_match.group(2)}\\nA/C: {bank_match.group(3)}"
"""

replacement = """        # Specific Extraction for Bank Details
        bank_name = None
        ifs_code = None
        bank_acc_num = None
        
        bank_match = re.search(r'([A-Za-z\\s]+?)[\\s\\|\\n]+([A-Z]{4}0[A-Z0-9]{6})[\\s\\|\\n]+(\\d{9,18})', extracted_text)
        if bank_match:
            b_name = re.sub(r'^[\\s\\|\\n]+', '', bank_match.group(1)).strip()
            # Clean up if it grabbed too much text before the bank name
            b_name = b_name.split('\\n')[-1].strip()
            # Remove header leftovers if any
            b_name = re.sub(r'(?i)\\b(Bank Name|IFS Code|Bank Account Number|Bank Details)\\b', '', b_name).strip()
            if b_name: bank_name = b_name
            ifs_code = bank_match.group(2)
            bank_acc_num = bank_match.group(3)
        else:
            # Fallback to block extraction if strict regex fails
            udyam_bank = extract_between(extracted_text, "Bank Account Number", ["Employment Details", "Unit(s) Details", "Investment in Plant"])
            if not udyam_bank: udyam_bank = extract_between(extracted_text, "Bank Details", ["Employment Details", "Unit(s) Details"])
"""

target2 = """        if udyam_bank: structured["Bank Details"] = udyam_bank"""

replacement2 = """        if bank_name: structured["Bank Name"] = bank_name
        if ifs_code: structured["IFS Code"] = ifs_code
        if bank_acc_num: structured["Bank Account Number"] = bank_acc_num
        elif udyam_bank: structured["Bank Details"] = udyam_bank""" # fallback

if target in content and target2 in content:
    content = content.replace(target, replacement)
    content = content.replace(target2, replacement2)
    with open(backend_path, "w") as f:
        f.write(content)
    print("Successfully patched backend OCR logic for separated bank details")
else:
    print("Target string not found in the file.")
