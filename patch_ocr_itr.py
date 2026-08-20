import os
import re

backend_path = "/Users/sayarpaul/Project/Toolhub_Naiyo_Backend/routes/ocr.py"

with open(backend_path, "r") as f:
    content = f.read()

target = """    elif doc_type == "UDYAM" or "UDYAM" in doc_type:"""

replacement = """    elif doc_type == "ITR" or "ITR" in doc_type:
        pan_match = re.search(r'PAN\\s+([A-Z]{5}[0-9]{4}[A-Z])', extracted_text)
        name_match = re.search(r'Name\\s+(.+?)(?=\\s+Address)', extracted_text, re.DOTALL)
        address_match = re.search(r'Address\\s+(.+?)(?=\\s+Status)', extracted_text, re.DOTALL)
        status_match = re.search(r'Status\\s+(.+?)(?=\\s+Form Number)', extracted_text)
        form_number_match = re.search(r'Form Number\\s+(.+?)(?=\\s+Filed)', extracted_text)
        filed_us_match = re.search(r'Filed u/s\\s+(.+?)(?=\\s+e-Filing)', extracted_text)
        ack_match = re.search(r'e-Filing Acknowledgement Number\\s+(\\d+)', extracted_text)
        ay_match = re.search(r'Assessment Year\\s+(\\d{4}-\\d{2})', extracted_text)
        income_match = re.search(r'Total Income\\s+(?:Rs\\.?\\s*)?([\\d,]+\\.?\\d*)', extracted_text)
        
        if pan_match: structured["PAN Number"] = pan_match.group(1).strip()
        if name_match: structured["Name"] = name_match.group(1).strip()
        if address_match: structured["Address"] = address_match.group(1).strip()
        if status_match: structured["Status"] = status_match.group(1).strip()
        if form_number_match: structured["Form Number"] = form_number_match.group(1).strip()
        if filed_us_match: structured["Filed u/s"] = filed_us_match.group(1).strip()
        if ack_match: structured["Acknowledgement Number"] = ack_match.group(1).strip()
        if ay_match: structured["Assessment Year"] = ay_match.group(1).strip()
        if income_match: structured["Total Income"] = income_match.group(1).strip()

    elif doc_type == "UDYAM" or "UDYAM" in doc_type:"""

if target in content:
    content = content.replace(target, replacement)
    with open(backend_path, "w") as f:
        f.write(content)
    print("Successfully patched backend OCR logic for ITR extraction")
else:
    print("Target string not found in the file.")
