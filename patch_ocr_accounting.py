import os
import re

backend_path = "/Users/sayarpaul/Project/Toolhub_Naiyo_Backend/routes/ocr.py"

with open(backend_path, "r") as f:
    content = f.read()

target = """        # Fallback: Heuristically sum up transaction lines if no summary exists
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
                total_credit = f"{sum_cr:,.2f}\""""

replacement = """        # Fallback: Mathematical accounting heuristics to sum up transaction lines
        if not total_debit or not total_credit:
            sum_dr = 0.0
            sum_cr = 0.0
            prev_bal = None
            
            lines = extracted_text.split('\\n')
            for line in lines:
                # Remove dates so they don't get parsed as amounts
                clean_line = re.sub(r'\\d{1,2}[/\\-]\\d{1,2}[/\\-]\\d{2,4}', '', line)
                clean_line = re.sub(r'\\d{1,2}\\s+[A-Za-z]{3}\\s+\\d{4}', '', clean_line)
                
                # Find all amounts (e.g. 12,345.50)
                amounts_str = re.findall(r'\\b\\d+[\\d,]*\\.\\d{2}\\b', clean_line)
                if len(amounts_str) >= 2:
                    amounts = [float(a.replace(',', '')) for a in amounts_str]
                    bal = amounts[-1]
                    txn_amt = amounts[0]
                    
                    if len(amounts) >= 3:
                        # Format: [Withdrawal, Deposit, Balance] or [Debit, Credit, Balance]
                        val1, val2 = amounts[-3], amounts[-2]
                        if val1 > 0 and val2 == 0:
                            sum_dr += val1
                        elif val2 > 0 and val1 == 0:
                            sum_cr += val2
                        else:
                            # Trust math if both are non-zero (rare)
                            if prev_bal is not None:
                                diff = bal - prev_bal
                                if abs(diff - txn_amt) < 0.1: sum_cr += txn_amt
                                elif abs(diff - (-txn_amt)) < 0.1: sum_dr += txn_amt
                    else:
                        # Format: [Amount, Balance]
                        if prev_bal is not None:
                            diff = bal - prev_bal
                            if abs(diff - txn_amt) < 0.1:
                                sum_cr += txn_amt
                            elif abs(diff - (-txn_amt)) < 0.1:
                                sum_dr += txn_amt
                            else:
                                # Fallback to text markers if math fails
                                if re.search(r'\\bDR\\b|DEBIT|WITHDRAWAL', line, re.IGNORECASE):
                                    sum_dr += txn_amt
                                elif re.search(r'\\bCR\\b|CREDIT|DEPOSIT', line, re.IGNORECASE):
                                    sum_cr += txn_amt
                        else:
                            # Fallback if no previous balance
                            if re.search(r'\\bDR\\b|DEBIT|WITHDRAWAL', line, re.IGNORECASE):
                                sum_dr += txn_amt
                            elif re.search(r'\\bCR\\b|CREDIT|DEPOSIT', line, re.IGNORECASE):
                                sum_cr += txn_amt
                                
                    prev_bal = bal
                    
            if not total_debit and sum_dr > 0:
                total_debit = f"{sum_dr:,.2f}"
            if not total_credit and sum_cr > 0:
                total_credit = f"{sum_cr:,.2f}\""""

if target in content:
    content = content.replace(target, replacement)
    
    # We should also calculate Net Cash Flow!
    # Let's add it dynamically to the end of the extraction block.
    insert_idx = content.find('structured["Total Credit (Deposits)"] = total_credit or "Not Found"')
    if insert_idx != -1:
        insert_text = """
        # Calculate Net Cash Flow
        try:
            td = float(total_debit.replace(',', '')) if total_debit else 0.0
            tc = float(total_credit.replace(',', '')) if total_credit else 0.0
            if td > 0 or tc > 0:
                net_flow = tc - td
                structured["Net Cash Flow"] = f"{net_flow:,.2f}"
            else:
                structured["Net Cash Flow"] = "Not Found"
        except:
            structured["Net Cash Flow"] = "Not Found"
        """
        content = content[:insert_idx + 69] + insert_text + content[insert_idx + 69:]
        
    with open(backend_path, "w") as f:
        f.write(content)
    print("Successfully patched backend OCR logic for Advanced Total Accounting")
else:
    print("Target string not found in the file.")
