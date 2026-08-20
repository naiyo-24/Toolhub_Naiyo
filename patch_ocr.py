import os
import re

backend_path = "/Users/sayarpaul/Project/Toolhub_Naiyo_Backend/routes/ocr.py"

with open(backend_path, "r") as f:
    content = f.read()

# We want to replace the list-based extraction of units and investments with raw block extraction, and add bank details.
target = """        udyam_units = []
        units_block_idx = extracted_text.lower().find("unit(s) details")
        if units_block_idx != -1:
            end_idx = extracted_text.lower().find("official address", units_block_idx)
            if end_idx == -1: end_idx = len(extracted_text)
            units_text = extracted_text[units_block_idx:end_idx]
            for line in units_text.split('\\n'):
                line = line.strip()
                if re.match(r'^\\d+[\\s\\.\\|]+[A-Za-z]', line):
                    udyam_units.append(line)
                    
        udyam_investment = []
        invest_block_idx = extracted_text.lower().find("itr type")
        if invest_block_idx != -1:
            end_idx = extracted_text.lower().find("unit(s) details", invest_block_idx)
            if end_idx == -1: end_idx = len(extracted_text)
            invest_text = extracted_text[invest_block_idx:end_idx]
            for line in invest_text.split('\\n'):
                line = line.strip()
                if re.search(r'\\b20\\d{2}\\b', line):
                    udyam_investment.append(line)
                    
        def extract_between(text, start_label, end_labels):"""

replacement = """        def extract_between(text, start_label, end_labels):
            start_idx = text.lower().find(start_label.lower())
            if start_idx == -1: return None
            start_idx += len(start_label)
            end_idx = len(text)
            for end_label in end_labels:
                idx = text.lower().find(end_label.lower(), start_idx)
                if idx != -1 and idx < end_idx: end_idx = idx
            extracted = text[start_idx:end_idx].strip()
            extracted = re.sub(r'^[\\s:\\-,|]+', '', extracted)
            extracted = re.sub(r'[\\s.,|]+$', '', extracted)
            return extracted.strip() if extracted else None
            
        udyam_bank = extract_between(extracted_text, "Bank Account Number", ["Employment Details", "Unit(s) Details", "Investment in Plant"])
        udyam_units = extract_between(extracted_text, "District", ["Official address of Enterprise", "Name of Premises/"])
        if not udyam_units: udyam_units = extract_between(extracted_text, "Unit(s) Details", ["Official address of Enterprise", "Name of Premises/"])
        
        udyam_investment = extract_between(extracted_text, "ITR Type", ["Unit(s) Details", "Bank Details", "Official address"])
        if not udyam_investment: udyam_investment = extract_between(extracted_text, "Investment in Plant", ["Unit(s) Details", "Bank Details"])
        
        def _extract_between_placeholder(text, start_label, end_labels):"""

target2 = """        if udyam_investment: structured["Investment Data"] = udyam_investment
        if udyam_units: structured["Units Data"] = udyam_units
        if udyam_address: structured["Official Address"] = udyam_address"""

replacement2 = """        if udyam_bank: structured["Bank Details"] = udyam_bank
        if udyam_investment: structured["Investment Data"] = udyam_investment
        if udyam_units: structured["Units Data"] = udyam_units
        if udyam_address: structured["Official Address"] = udyam_address"""

if target in content and target2 in content:
    content = content.replace(target, replacement)
    content = content.replace(target2, replacement2)
    # Fix the duplicate extract_between issue by removing the placeholder
    content = content.replace("        def _extract_between_placeholder(text, start_label, end_labels):", "        # extract_between already defined above")
    
    # We also need to remove the original extract_between definition that follows our replacement
    # because we moved it up.
    original_extract_between = """        def extract_between(text, start_label, end_labels):
            start_idx = text.lower().find(start_label.lower())
            if start_idx == -1: return None
            start_idx += len(start_label)
            end_idx = len(text)
            for end_label in end_labels:
                idx = text.lower().find(end_label.lower(), start_idx)
                if idx != -1 and idx < end_idx: end_idx = idx
            extracted = text[start_idx:end_idx].strip()
            extracted = re.sub(r'^[\\s:\\-,|]+', '', extracted)
            extracted = re.sub(r'[\\s.,|]+$', '', extracted)
            return extracted.strip() if extracted else None"""
            
    content = content.replace("        # extract_between already defined above\\n" + original_extract_between, "")

    with open(backend_path, "w") as f:
        f.write(content)
    print("Successfully patched backend OCR logic for full Udyam details")
else:
    print("Target string not found in the file.")
    if target not in content: print("target 1 not found")
    if target2 not in content: print("target 2 not found")
