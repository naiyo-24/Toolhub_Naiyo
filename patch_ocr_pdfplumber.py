import os

backend_path = "/Users/sayarpaul/Project/Toolhub_Naiyo_Backend/routes/ocr.py"

with open(backend_path, "r") as f:
    content = f.read()

target = """    if doc.file_name.lower().endswith('.pdf'):
        from pdf2image import convert_from_bytes
        import io
        try:
            images = convert_from_bytes(file_bytes)
            for img in images:
                text = pytesseract.image_to_string(img)
                extracted_text += text + "\\n"
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to process PDF: {str(e)}")"""

replacement = """    if doc.file_name.lower().endswith('.pdf'):
        import pdfplumber
        import io
        try:
            with pdfplumber.open(io.BytesIO(file_bytes)) as pdf:
                for page in pdf.pages:
                    text = page.extract_text(layout=True)
                    if text:
                        extracted_text += text + "\\n"
            
            # Fallback to Tesseract OCR if the PDF is purely a scanned image with no digital text
            if len(extracted_text.strip()) < 50:
                from pdf2image import convert_from_bytes
                images = convert_from_bytes(file_bytes)
                extracted_text = ""
                for img in images:
                    text = pytesseract.image_to_string(img)
                    extracted_text += text + "\\n"
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to process PDF: {str(e)}")"""

if target in content:
    content = content.replace(target, replacement)
    with open(backend_path, "w") as f:
        f.write(content)
    print("Successfully patched backend OCR logic to use pdfplumber")
else:
    print("Target string not found in the file.")
