import os
import re

backend_path = "/Users/sayarpaul/Project/Toolhub_Naiyo_Backend/routes/ocr.py"

with open(backend_path, "r") as f:
    content = f.read()

# Fix 1: Read all pages of the PDF, not just the first page!
target1 = "images = convert_from_bytes(file_bytes, first_page=1, last_page=1)"
replacement1 = "images = convert_from_bytes(file_bytes)"

# Fix 2: Improve Bank Details Extraction using resilient regex
target2 = """        udyam_bank = extract_between(extracted_text, "Bank Account Number", ["Employment Details", "Unit(s) Details", "Investment in Plant", "Official address of Enterprise"])
        if not udyam_bank: udyam_bank = extract_between(extracted_text, "Bank Details", ["Employment Details", "Unit(s) Details", "Official address"])"""

replacement2 = """        # Resilient Bank Details Extraction
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

if target1 in content:
    content = content.replace(target1, replacement1)
    if target2 in content:
        content = content.replace(target2, replacement2)
    with open(backend_path, "w") as f:
        f.write(content)
    print("Successfully patched backend OCR logic for PDF pages and bank details")
else:
    print("Target string 1 not found in the file.")
    if target1 not in content: print("target 1 missing")
