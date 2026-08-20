import os
import re

backend_path = "/Users/sayarpaul/Project/Toolhub_Naiyo_Backend/routes/ocr.py"

with open(backend_path, "r") as f:
    content = f.read()

target = """    elif doc_type == "ITR" or "ITR" in doc_type:
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
        if income_match: structured["Total Income"] = income_match.group(1).strip()"""

replacement = """    elif doc_type == "ITR" or "ITR" in doc_type:
        pan_match = re.search(r'PAN\\s+([A-Z]{5}[0-9]{4}[A-Z])', extracted_text)
        name_match = re.search(r'Name\\s+(.+?)(?=\\s+Address)', extracted_text, re.DOTALL)
        address_match = re.search(r'Address\\s+(.+?)(?=\\s+Status)', extracted_text, re.DOTALL)
        status_match = re.search(r'Status\\s+(.+?)(?=\\s+Form Number)', extracted_text)
        form_number_match = re.search(r'Form Number\\s+(.+?)(?=\\s+Filed)', extracted_text)
        filed_us_match = re.search(r'Filed u/s\\s+(.+?)(?=\\s+e-Filing)', extracted_text)
        ack_match = re.search(r'e-Filing Acknowledgement Number\\s+(\\d+)', extracted_text)
        ay_match = re.search(r'Assessment Year\\s+(\\d{4}-\\d{2})', extracted_text)
        
        # New robust financial fields matching "Label <number> <value>"
        income_match = re.search(r'Total Income\\s+(?:1A\\s+)?([\\d,]+\\.?\\d*)', extracted_text)
        loss_match = re.search(r'Current Year business loss, if any\\s+(?:1\\s+)?([\\d,]+\\.?\\d*)', extracted_text)
        mat_match = re.search(r'Book Profit under MAT, where applicable\\s+(?:2\\s+)?([\\d,]+\\.?\\d*)', extracted_text)
        amt_match = re.search(r'Adjusted Total Income under AMT, where applicable\\s+(?:3\\s+)?([\\d,]+\\.?\\d*)', extracted_text)
        net_tax_match = re.search(r'Net tax payable\\s+(?:4\\s+)?([\\d,]+\\.?\\d*)', extracted_text)
        interest_match = re.search(r'Interest and Fee Payable\\s+(?:5\\s+)?([\\d,]+\\.?\\d*)', extracted_text)
        total_tax_match = re.search(r'Total tax, interest and Fee payable\\s+(?:6\\s+)?([\\d,]+\\.?\\d*)', extracted_text)
        taxes_paid_match = re.search(r'Taxes Paid\\s+(?:7\\s+)?([\\d,]+\\.?\\d*)', extracted_text)
        payable_refundable_match = re.search(r'\\(\\+\\) Tax Payable /\\(-\\) Refundable \\(6-7\\)\\s+(?:8\\s+)?([\\d,\\-]+\\.?\\d*)', extracted_text)
        
        if pan_match: structured["PAN Number"] = pan_match.group(1).strip()
        if name_match: structured["Name"] = name_match.group(1).strip()
        if address_match: structured["Address"] = address_match.group(1).strip()
        if status_match: structured["Status"] = status_match.group(1).strip()
        if form_number_match: structured["Form Number"] = form_number_match.group(1).strip()
        if filed_us_match: structured["Filed u/s"] = filed_us_match.group(1).strip()
        if ack_match: structured["Acknowledgement Number"] = ack_match.group(1).strip()
        if ay_match: structured["Assessment Year"] = ay_match.group(1).strip()
        
        if income_match: structured["Total Income"] = income_match.group(1).strip()
        if loss_match: structured["Current Year business loss"] = loss_match.group(1).strip()
        if mat_match: structured["Book Profit under MAT"] = mat_match.group(1).strip()
        if amt_match: structured["Adjusted Total Income under AMT"] = amt_match.group(1).strip()
        if net_tax_match: structured["Net tax payable"] = net_tax_match.group(1).strip()
        if interest_match: structured["Interest and Fee Payable"] = interest_match.group(1).strip()
        if total_tax_match: structured["Total tax, interest and Fee payable"] = total_tax_match.group(1).strip()
        if taxes_paid_match: structured["Taxes Paid"] = taxes_paid_match.group(1).strip()
        if payable_refundable_match: structured["Tax Payable / Refundable"] = payable_refundable_match.group(1).strip()"""

if target in content:
    content = content.replace(target, replacement)
    with open(backend_path, "w") as f:
        f.write(content)
    print("Successfully patched backend OCR logic for extended ITR extraction")
else:
    print("Target string not found in the file.")
