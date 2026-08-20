import os
import re

backend_path = "/Users/sayarpaul/Project/Toolhub_Naiyo_Backend/routes/ocr.py"

with open(backend_path, "r") as f:
    content = f.read()

# Replace the previous hardcoded row numbers with the universal row number skipper
target = """        # New robust financial fields matching "Label <number> <value>"
        income_match = re.search(r'Total Income\\s+(?:1A\\s+)?([\\d,]+\\.?\\d*)', extracted_text)
        loss_match = re.search(r'Current Year business loss, if any\\s+(?:1\\s+)?([\\d,]+\\.?\\d*)', extracted_text)
        mat_match = re.search(r'Book Profit under MAT, where applicable\\s+(?:2\\s+)?([\\d,]+\\.?\\d*)', extracted_text)
        amt_match = re.search(r'Adjusted Total Income under AMT, where applicable\\s+(?:3\\s+)?([\\d,]+\\.?\\d*)', extracted_text)
        net_tax_match = re.search(r'Net tax payable\\s+(?:4\\s+)?([\\d,]+\\.?\\d*)', extracted_text)
        interest_match = re.search(r'Interest and Fee Payable\\s+(?:5\\s+)?([\\d,]+\\.?\\d*)', extracted_text)
        total_tax_match = re.search(r'Total tax, interest and Fee payable\\s+(?:6\\s+)?([\\d,]+\\.?\\d*)', extracted_text)
        taxes_paid_match = re.search(r'Taxes Paid\\s+(?:7\\s+)?([\\d,]+\\.?\\d*)', extracted_text)
        payable_refundable_match = re.search(r'\\(\\+\\) Tax Payable /\\(-\\) Refundable \\(6-7\\)\\s+(?:8\\s+)?([\\d,\\-]+\\.?\\d*)', extracted_text)
        accreted_match = re.search(r'Accreted Income as per section 115TD\\s+(?:9\\s+)?([\\d,\\-]+\\.?\\d*)', extracted_text)
        add_tax_115td_match = re.search(r'Additional Tax payable u/s 115TD\\s+(?:10\\s+)?([\\d,\\-]+\\.?\\d*)', extracted_text)
        interest_115te_match = re.search(r'Interest payable u/s 115TE\\s+(?:11\\s+)?([\\d,\\-]+\\.?\\d*)', extracted_text)
        add_tax_int_payable_match = re.search(r'Additional Tax and interest payable\\s+(?:12\\s+)?([\\d,\\-]+\\.?\\d*)', extracted_text)
        tax_int_paid_match = re.search(r'Tax and interest paid\\s+(?:13\\s+)?([\\d,\\-]+\\.?\\d*)', extracted_text)
        payable_refundable_12_13_match = re.search(r'\\(\\+\\) Tax Payable /\\(-\\) Refundable \\(12-13\\)\\s+(?:14\\s+)?([\\d,\\-]+\\.?\\d*)', extracted_text)"""

replacement = """        # Universal row number skipper for OCR robustness (e.g. skips '1A ', '3. ', '14 ')
        row_skip = r'(?:\\d{1,2}[A-Za-z]?\\.?\\s+)?'
        
        income_match = re.search(r'Total Income\\s+' + row_skip + r'([\\d,]+\\.?\\d*)', extracted_text)
        loss_match = re.search(r'Current Year business loss, if any\\s+' + row_skip + r'([\\d,]+\\.?\\d*)', extracted_text)
        mat_match = re.search(r'Book Profit under MAT, where applicable\\s+' + row_skip + r'([\\d,]+\\.?\\d*)', extracted_text)
        amt_match = re.search(r'Adjusted Total Income under AMT, where applicable\\s+' + row_skip + r'([\\d,]+\\.?\\d*)', extracted_text)
        net_tax_match = re.search(r'Net tax payable\\s+' + row_skip + r'([\\d,]+\\.?\\d*)', extracted_text)
        interest_match = re.search(r'Interest and Fee Payable\\s+' + row_skip + r'([\\d,]+\\.?\\d*)', extracted_text)
        total_tax_match = re.search(r'Total tax, interest and Fee payable\\s+' + row_skip + r'([\\d,]+\\.?\\d*)', extracted_text)
        taxes_paid_match = re.search(r'Taxes Paid\\s+' + row_skip + r'([\\d,]+\\.?\\d*)', extracted_text)
        payable_refundable_match = re.search(r'\\(\\+\\) Tax Payable /\\(-\\) Refundable \\(6-7\\)\\s+' + row_skip + r'([\\d,\\-]+\\.?\\d*)', extracted_text)
        accreted_match = re.search(r'Accreted Income as per section 115TD\\s+' + row_skip + r'([\\d,\\-]+\\.?\\d*)', extracted_text)
        add_tax_115td_match = re.search(r'Additional Tax payable u/s 115TD\\s+' + row_skip + r'([\\d,\\-]+\\.?\\d*)', extracted_text)
        interest_115te_match = re.search(r'Interest payable u/s 115TE\\s+' + row_skip + r'([\\d,\\-]+\\.?\\d*)', extracted_text)
        add_tax_int_payable_match = re.search(r'Additional Tax and interest payable\\s+' + row_skip + r'([\\d,\\-]+\\.?\\d*)', extracted_text)
        tax_int_paid_match = re.search(r'Tax and interest paid\\s+' + row_skip + r'([\\d,\\-]+\\.?\\d*)', extracted_text)
        payable_refundable_12_13_match = re.search(r'\\(\\+\\) Tax Payable /\\(-\\) Refundable \\(12-13\\)\\s+' + row_skip + r'([\\d,\\-]+\\.?\\d*)', extracted_text)"""

if target in content:
    content = content.replace(target, replacement)
    with open(backend_path, "w") as f:
        f.write(content)
    print("Successfully patched backend OCR logic for universal row number skipping")
else:
    print("Target string not found in the file.")
