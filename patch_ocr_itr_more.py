import os
import re

backend_path = "/Users/sayarpaul/Project/Toolhub_Naiyo_Backend/routes/ocr.py"

with open(backend_path, "r") as f:
    content = f.read()

target = """        payable_refundable_match = re.search(r'\\(\\+\\) Tax Payable /\\(-\\) Refundable \\(6-7\\)\\s+(?:8\\s+)?([\\d,\\-]+\\.?\\d*)', extracted_text)"""

replacement = """        payable_refundable_match = re.search(r'\\(\\+\\) Tax Payable /\\(-\\) Refundable \\(6-7\\)\\s+(?:8\\s+)?([\\d,\\-]+\\.?\\d*)', extracted_text)
        accreted_match = re.search(r'Accreted Income as per section 115TD\\s+(?:9\\s+)?([\\d,\\-]+\\.?\\d*)', extracted_text)
        add_tax_115td_match = re.search(r'Additional Tax payable u/s 115TD\\s+(?:10\\s+)?([\\d,\\-]+\\.?\\d*)', extracted_text)
        interest_115te_match = re.search(r'Interest payable u/s 115TE\\s+(?:11\\s+)?([\\d,\\-]+\\.?\\d*)', extracted_text)
        add_tax_int_payable_match = re.search(r'Additional Tax and interest payable\\s+(?:12\\s+)?([\\d,\\-]+\\.?\\d*)', extracted_text)
        tax_int_paid_match = re.search(r'Tax and interest paid\\s+(?:13\\s+)?([\\d,\\-]+\\.?\\d*)', extracted_text)
        payable_refundable_12_13_match = re.search(r'\\(\\+\\) Tax Payable /\\(-\\) Refundable \\(12-13\\)\\s+(?:14\\s+)?([\\d,\\-]+\\.?\\d*)', extracted_text)"""

target2 = """        if payable_refundable_match: structured["Tax Payable / Refundable"] = payable_refundable_match.group(1).strip()"""

replacement2 = """        if payable_refundable_match: structured["Tax Payable / Refundable (6-7)"] = payable_refundable_match.group(1).strip()
        if accreted_match: structured["Accreted Income (115TD)"] = accreted_match.group(1).strip()
        if add_tax_115td_match: structured["Additional Tax payable (115TD)"] = add_tax_115td_match.group(1).strip()
        if interest_115te_match: structured["Interest payable (115TE)"] = interest_115te_match.group(1).strip()
        if add_tax_int_payable_match: structured["Additional Tax and interest payable"] = add_tax_int_payable_match.group(1).strip()
        if tax_int_paid_match: structured["Tax and interest paid"] = tax_int_paid_match.group(1).strip()
        if payable_refundable_12_13_match: structured["Tax Payable / Refundable (12-13)"] = payable_refundable_12_13_match.group(1).strip()"""


if target in content and target2 in content:
    content = content.replace(target, replacement)
    content = content.replace(target2, replacement2)
    with open(backend_path, "w") as f:
        f.write(content)
    print("Successfully patched backend OCR logic for more ITR fields")
else:
    print("Target string not found in the file.")
