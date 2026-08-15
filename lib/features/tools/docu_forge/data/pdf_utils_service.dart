import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'local_storage_service.dart';

class PdfUtilsService {
  static Future<String> generatePdfThumbnail(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final page = await Printing.raster(bytes, dpi: 72).first;
      final imageBytes = await page.toPng();
      
      final outPath = await LocalStorageService.getPdfStoragePath();
      final thumbFile = File('$outPath/Thumb_${DateTime.now().millisecondsSinceEpoch}.png');
      await thumbFile.writeAsBytes(imageBytes);
      return thumbFile.path;
    } catch (e) {
      debugPrint('Thumbnail Gen Error: $e');
      return '';
    }
  }

  static Future<File?> mergePdfs(List<File> files) async {
    try {
      final PdfDocument document = PdfDocument();
      
      for (var file in files) {
        final PdfDocument loadedDocument = PdfDocument(inputBytes: await file.readAsBytes());
        // Append all pages from loaded document
        for (int i = 0; i < loadedDocument.pages.count; i++) {
          final PdfPage page = loadedDocument.pages[i];
          
          // Match the size and remove margins to prevent clipping
          document.pageSettings.size = page.size;
          document.pageSettings.margins.all = 0;
          
          final PdfPage newPage = document.pages.add();
          newPage.graphics.drawPdfTemplate(page.createTemplate(), const Offset(0, 0));
        }
        loadedDocument.dispose();
      }

      final outPath = await LocalStorageService.getPdfStoragePath();
      final outFile = File('$outPath/Merged_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await outFile.writeAsBytes(await document.save());
      document.dispose();
      
      return outFile;
    } catch (e) {
      debugPrint('Merge Error: $e');
      return null;
    }
  }

  static Future<File?> protectPdf(File file, String userPassword, String ownerPassword) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());
      
      final PdfSecurity security = document.security;
      security.userPassword = userPassword;
      security.ownerPassword = ownerPassword;
      security.algorithm = PdfEncryptionAlgorithm.aesx256Bit;

      final outPath = await LocalStorageService.getPdfStoragePath();
      final outFile = File('$outPath/Protected_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await outFile.writeAsBytes(await document.save());
      document.dispose();
      
      return outFile;
    } catch (e) {
      debugPrint('Protect Error: $e');
      return null;
    }
  }

  static Future<File?> removePassword(File file, String password) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes(), password: password);
      
      // Clear passwords to remove security
      document.security.userPassword = '';
      document.security.ownerPassword = '';
      
      final outPath = await LocalStorageService.getPdfStoragePath();
      final outFile = File('$outPath/Unlocked_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await outFile.writeAsBytes(await document.save());
      document.dispose();
      
      return outFile;
    } catch (e) {
      debugPrint('Remove Password Error: $e');
      return null; // Usually means incorrect password
    }
  }

  static Future<File?> watermarkPdfText(File file, String watermarkText) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());
      
      final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 40);
      final Size watermarkSize = font.measureString(watermarkText);

      for (int i = 0; i < document.pages.count; i++) {
        final PdfPage page = document.pages[i];
        final PdfGraphics graphics = page.graphics;

        graphics.save();
        graphics.setTransparency(0.25);
        graphics.translateTransform(page.size.width / 2, page.size.height / 2);
        graphics.rotateTransform(-45);
        
        graphics.drawString(
          watermarkText, 
          font, 
          brush: PdfBrushes.red, 
          bounds: Rect.fromLTWH(
            -watermarkSize.width / 2, 
            -watermarkSize.height / 2, 
            watermarkSize.width, 
            watermarkSize.height
          )
        );
        graphics.restore();
      }

      final outPath = await LocalStorageService.getPdfStoragePath();
      final outFile = File('$outPath/Watermarked_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await outFile.writeAsBytes(await document.save());
      document.dispose();
      
      return outFile;
    } catch (e) {
      debugPrint('Watermark Error: $e');
      return null;
    }
  }

  static Future<File?> watermarkPdfImage(File file, File imageFile) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());
      final PdfBitmap image = PdfBitmap(await imageFile.readAsBytes());

      for (int i = 0; i < document.pages.count; i++) {
        final PdfPage page = document.pages[i];
        final PdfGraphics graphics = page.graphics;

        graphics.save();
        graphics.setTransparency(0.25); // 25% opacity
        
        // Draw image in the center, at 50% of page width
        final double width = page.size.width * 0.5;
        final double height = (image.height / image.width) * width;
        final double x = (page.size.width - width) / 2;
        final double y = (page.size.height - height) / 2;

        graphics.drawImage(image, Rect.fromLTWH(x, y, width, height));
        graphics.restore();
      }
      
      final outPath = await LocalStorageService.getPdfStoragePath();
      final outFile = File('$outPath/Watermarked_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await outFile.writeAsBytes(await document.save());
      document.dispose();
      
      return outFile;
    } catch (e) {
      debugPrint('Watermark Image Error: $e');
      return null;
    }
  }

  static Future<File?> imagesToPdf(List<File> images) async {
    try {
      final PdfDocument document = PdfDocument();
      
      for (var file in images) {
        final bytes = await file.readAsBytes();
        final PdfBitmap image = PdfBitmap(bytes);
        
        final PdfPage page = document.pages.add();
        final Size pageSize = page.getClientSize();
        
        page.graphics.drawImage(image, Rect.fromLTWH(0, 0, pageSize.width, pageSize.height));
      }

      final outPath = await LocalStorageService.getPdfStoragePath();
      final outFile = File('$outPath/ImagesToPDF_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await outFile.writeAsBytes(await document.save());
      document.dispose();
      
      return outFile;
    } catch (e) {
      debugPrint('Images to PDF Error: $e');
      return null;
    }
  }

  static Future<File?> appendImageToPdf(File originalPdf, File imageFile) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: await originalPdf.readAsBytes());
      
      final bytes = await imageFile.readAsBytes();
      final PdfBitmap image = PdfBitmap(bytes);
      
      final PdfPage page = document.pages.add();
      final Size pageSize = page.getClientSize();
      
      page.graphics.drawImage(image, Rect.fromLTWH(0, 0, pageSize.width, pageSize.height));

      // Overwrite the original file
      await originalPdf.writeAsBytes(await document.save());
      document.dispose();
      
      return originalPdf;
    } catch (e) {
      debugPrint('Append Image Error: $e');
      return null;
    }
  }

  static Future<File?> rebuildPdf(File originalFile, List<Map<String, dynamic>> layoutInstructions) async {
    try {
      final PdfDocument sourceDoc = PdfDocument(inputBytes: await originalFile.readAsBytes());
      final PdfDocument newDoc = PdfDocument();

      for (var instruction in layoutInstructions) {
        final originalIndex = instruction['originalIndex'] as int;
        final rotation = instruction['rotation'] as int;
        final Uint8List? editedImage = instruction['editedImage'] as Uint8List?;
        
        final PdfPage sourcePage = sourceDoc.pages[originalIndex];
        
        // Ensure the new page takes the source page's size
        final Size size = sourcePage.size;
        final PdfSection section = newDoc.sections!.add();
        section.pageSettings.size = size;
        
        // We set the margins to 0 so the template fills the page
        section.pageSettings.margins.all = 0;

        final PdfPage newPage = section.pages.add();

        // Apply rotation
        if (rotation == 90) {
          newPage.rotation = PdfPageRotateAngle.rotateAngle90;
        } else if (rotation == 180) {
          newPage.rotation = PdfPageRotateAngle.rotateAngle180;
        } else if (rotation == 270) {
          newPage.rotation = PdfPageRotateAngle.rotateAngle270;
        }

        if (editedImage != null) {
          // Draw the edited image instead of original vector template
          final PdfBitmap imageBitmap = PdfBitmap(editedImage);
          // Calculate destination rectangle to fit page size (which might be rotated)
          newPage.graphics.drawImage(imageBitmap, Rect.fromLTWH(0, 0, size.width, size.height));
        } else {
          // Draw original vector template
          newPage.graphics.drawPdfTemplate(sourcePage.createTemplate(), const Offset(0, 0));
        }
      }

      final outPath = await LocalStorageService.getPdfStoragePath();
      final outFile = File('$outPath/Edited_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await outFile.writeAsBytes(await newDoc.save());
      
      sourceDoc.dispose();
      newDoc.dispose();
      
      return outFile;
    } catch (e) {
      debugPrint('Rebuild Error: $e');
      return null;
    }
  }
}
