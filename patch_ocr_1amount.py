import os
import re

backend_path = "/Users/sayarpaul/Project/Toolhub_Naiyo_Backend/routes/ocr.py"

with open(backend_path, "r") as f:
    content = f.read()

target = """                        else:
                            # Fallback if no previous balance
                            if re.search(r'\\bDR\\b|DEBIT|WITHDRAWAL', line, re.IGNORECASE):
                                sum_dr += txn_amt
                            elif re.search(r'\\bCR\\b|CREDIT|DEPOSIT', line, re.IGNORECASE):
                                sum_cr += txn_amt
                                
                    prev_bal = bal"""

replacement = """                        else:
                            # Fallback if no previous balance
                            if re.search(r'\\bDR\\b|DEBIT|WITHDRAWAL', line, re.IGNORECASE):
                                sum_dr += txn_amt
                            elif re.search(r'\\bCR\\b|CREDIT|DEPOSIT', line, re.IGNORECASE):
                                sum_cr += txn_amt
                                
                    prev_bal = bal
                elif len(amounts_str) == 1:
                    # OCR often drops the balance or splits it across lines.
                    # If we only have 1 amount on the line, we can't use math. 
                    # We MUST fallback to keywords.
                    txn_amt = float(amounts_str[0].replace(',', ''))
                    if re.search(r'\\bDR\\b|DEBIT|WITHDRAWAL', line, re.IGNORECASE):
                        sum_dr += txn_amt
                    elif re.search(r'\\bCR\\b|CREDIT|DEPOSIT', line, re.IGNORECASE):
                        sum_cr += txn_amt
                    elif re.search(r'UPI|IMPS|NEFT|RTGS', line, re.IGNORECASE):
                        # Extreme fallback: If it's a known payment type but no DR/CR marker,
                        # and no math to verify it, it's very likely a debit (purchases).
                        # We leave this out to avoid false positives, but we capture the ones with markers.
                        pass"""

if target in content:
    content = content.replace(target, replacement)
    with open(backend_path, "w") as f:
        f.write(content)
    print("Successfully patched backend OCR logic to capture single-amount lines")
else:
    print("Target string not found in the file.")
