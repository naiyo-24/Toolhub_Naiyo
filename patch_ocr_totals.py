import os
import re

backend_path = "/Users/sayarpaul/Project/Toolhub_Naiyo_Backend/routes/ocr.py"

with open(backend_path, "r") as f:
    content = f.read()

target = """        # Populate structured data unconditionally so they always appear in the UI
        structured["Customer Name"] = cust_name or "Not Found"
        structured["Customer ID"] = cust_id or "Not Found\""""

replacement = """        # Calculate Universal Totals (Debits/Withdrawals and Credits/Deposits)
        total_debit = extract_bank_val(r'(?:Total\\s+Withdrawals?|Total\\s+Debits?|Total\\s+Amount\\s+Debited)', extracted_text)
        total_credit = extract_bank_val(r'(?:Total\\s+Deposits?|Total\\s+Credits?|Total\\s+Amount\\s+Credited)', extracted_text)

        # Fallback: Heuristically sum up transaction lines if no summary exists
        if not total_debit or not total_credit:
            sum_dr = 0.0
            sum_cr = 0.0
            
            # Simple heuristic: scan lines for numbers with trailing DR or CR
            # Or scan lines with 2/3 numbers at the end
            lines = extracted_text.split('\\n')
            for line in lines:
                # Remove dates so they don't get confused as amounts
                clean_line = re.sub(r'\\d{1,2}[/\\-]\\d{1,2}[/\\-]\\d{2,4}', '', line)
                clean_line = re.sub(r'\\d{1,2}\\s+[A-Za-z]{3}\\s+\\d{4}', '', clean_line)
                
                # Find all amounts (like 12,345.50 or 100.00)
                amounts = re.findall(r'\\b\\d+[\\d,]*\\.\\d{2}\\b', clean_line)
                
                if len(amounts) >= 2:
                    # Usually the last is balance, the others are dr/cr
                    # Try to look for DR/CR markers
                    if '/DR/' in line.upper() or ' DR ' in line.upper():
                        val = float(amounts[0].replace(',', ''))
                        sum_dr += val
                    elif '/CR/' in line.upper() or ' CR ' in line.upper():
                        val = float(amounts[0].replace(',', ''))
                        sum_cr += val
            
            if not total_debit and sum_dr > 0:
                total_debit = f"{sum_dr:,.2f}"
            if not total_credit and sum_cr > 0:
                total_credit = f"{sum_cr:,.2f}"

        # Populate structured data unconditionally so they always appear in the UI
        structured["Customer Name"] = cust_name or "Not Found"
        structured["Customer ID"] = cust_id or "Not Found"
        structured["Total Debit (Withdrawals)"] = total_debit or "Not Found"
        structured["Total Credit (Deposits)"] = total_credit or "Not Found\""""

if target in content:
    content = content.replace(target, replacement)
    with open(backend_path, "w") as f:
        f.write(content)
    print("Successfully patched backend OCR logic for Total Debits and Credits")
else:
    print("Target string not found in the file.")
