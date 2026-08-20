import os
import re

backend_path = "/Users/sayarpaul/Project/Toolhub_Naiyo_Backend/routes/ocr.py"

with open(backend_path, "r") as f:
    content = f.read()

target = """        udyam_units = []
        units_match = re.search(r'(?i)(unit\\(s\\)\\s*details|sn\\s*unit\\s*name|sn[\\s\\n]*unit|building\\s*village)', extracted_text)
        units_block_idx = units_match.start() if units_match else -1
        
        if units_block_idx != -1:
            end_match = re.search(r'(?i)(official\\s*address|name\\s*of\\s*premises)', extracted_text[units_block_idx:])
            end_idx = units_block_idx + end_match.start() if end_match else len(extracted_text)
            units_text = extracted_text[units_block_idx:end_idx]
            
            expected_idx = 1
            matches = re.finditer(r'\\b(\\d{1,2})[\\s\\.\\|]*([A-Za-z].*?)(?=\\b\\d{1,2}[\\s\\.\\|]*[A-Za-z]|$)', units_text, re.DOTALL)
            for match in matches:
                if int(match.group(1)) == expected_idx:
                    text = match.group(2).strip()
                    text = re.sub(r'(?i)\\b(Mobile|Email|Date of|National Industry|Classification|Official Address|—\\|).*', '', text, flags=re.DOTALL)
                    if len(text) > 5:
                        udyam_units.append(f"{match.group(1)} {text.strip()}")
                        expected_idx += 1
                    
        udyam_investment = []
        invest_match = re.search(r'(?i)(itr\\s*type|investment\\s*in\\s*plant)', extracted_text)
        invest_block_idx = invest_match.start() if invest_match else -1
        
        if invest_block_idx != -1:
            end_match = re.search(r'(?i)(unit\\(s\\)\\s*details|bank\\s*details|sn\\s*unit)', extracted_text[invest_block_idx:])
            end_idx = invest_block_idx + end_match.start() if end_match else len(extracted_text)
            invest_text = extracted_text[invest_block_idx:end_idx]
            
            expected_idx = 1
            matches = re.finditer(r'\\b(\\d{1,2})[\\s\\.\\|]*(20\\d{2}.*?)(?=\\b\\d{1,2}[\\s\\.\\|]*20\\d{2}|$)', invest_text, re.DOTALL)
            for match in matches:
                if int(match.group(1)) == expected_idx:
                    text = match.group(2).strip()
                    text = re.sub(r'(?i)\\b(Unit\\(s\\)|Official Address|SN Unit).*', '', text, flags=re.DOTALL)
                    udyam_investment.append(f"{match.group(1)} {text.strip()}")
                    expected_idx += 1"""

replacement = """        # Resilient Units Extraction - search entire text for "1 | NAME" or "2. | NAME"
        udyam_units = []
        unit_matches = re.finditer(r'\\b(\\d{1,2})[\\s\\.\\|]+([A-Z][A-Z\\s]+)(?=\\n|$|Flat|Village|OFFICAL)', extracted_text)
        seen_units = set()
        for match in unit_matches:
            unit_num = match.group(1)
            unit_name = match.group(2).strip()
            # Clean up trailing noise
            unit_name = re.sub(r'\\s*\\|.*', '', unit_name).strip()
            if len(unit_name) > 3 and unit_name not in seen_units:
                udyam_units.append(f"Unit {unit_num}: {unit_name}")
                seen_units.add(unit_name)
                
        # Resilient Investment Extraction - search entire text for "2024-25 Micro 08/04/2024"
        udyam_investment = []
        invest_matches = re.finditer(r'\\b(20\\d{2}-\\d{2}[\\s\\|A-Za-z]+?\\d{2}/\\d{2}/\\d{4})\\b', extracted_text)
        for match in invest_matches:
            inv_text = match.group(1).strip()
            # Clean up pipe characters and excess spaces
            inv_text = re.sub(r'[\\|]+', ' ', inv_text)
            inv_text = re.sub(r'\\s+', ' ', inv_text)
            if inv_text not in udyam_investment:
                udyam_investment.append(inv_text)"""

if target in content:
    content = content.replace(target, replacement)
    with open(backend_path, "w") as f:
        f.write(content)
    print("Successfully patched backend OCR logic for robust Udyam units and investment")
else:
    print("Target string not found in the file.")
