import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import '../../data/cover_letter_model.dart';
import 'package:intl/intl.dart';

class CoverLetterPreviewScreen extends StatelessWidget {
  final CoverLetterData data;

  const CoverLetterPreviewScreen({super.key, required this.data});

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          if (data.templateType == 'Creative') {
            return _buildCreativeTemplate();
          } else if (data.templateType == 'Direct') {
            return _buildDirectTemplate();
          } else {
            return _buildProfessionalTemplate();
          }
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildProfessionalTemplate() {
    final date = DateFormat('MMMM d, yyyy').format(DateTime.now());
    final manager = data.hiringManager.isNotEmpty ? data.hiringManager : 'Hiring Manager';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        pw.Text(data.fullName.toUpperCase(), style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text(
          [
            data.email,
            data.phone,
            if (data.linkedIn.isNotEmpty) data.linkedIn,
            if (data.address.isNotEmpty) data.address,
          ].where((s) => s.isNotEmpty).join('  |  '),
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 24),
        pw.Divider(),
        pw.SizedBox(height: 24),
        
        // Date & Addressee
        pw.Text(date),
        pw.SizedBox(height: 16),
        pw.Text(manager, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text(data.companyName),
        pw.SizedBox(height: 24),
        
        // Body
        pw.Text('Dear $manager,'),
        pw.SizedBox(height: 16),
        pw.Text('Please accept this letter as an expression of my interest in the ${data.targetRole} position at ${data.companyName}. With ${data.yearsExperience} of experience in the field and a strong background in ${data.keySkills}, I am confident in my ability to make an immediate and positive impact on your team.'),
        pw.SizedBox(height: 12),
        pw.Text('Throughout my career, I have consistently demonstrated a commitment to delivering high-quality results. My expertise in ${data.keySkills} has allowed me to successfully lead projects, optimize processes, and contribute to the overarching goals of my previous employers. I am particularly drawn to ${data.companyName} because of your reputation for innovation and excellence, and I am eager to bring my diverse skill set to your organization.'),
        pw.SizedBox(height: 12),
        pw.Text('I would welcome the opportunity to discuss how my background, skills, and enthusiasm align with the needs of your team. Thank you for your time and consideration.'),
        pw.SizedBox(height: 24),
        
        // Sign-off
        pw.Text('Sincerely,'),
        pw.SizedBox(height: 24),
        pw.Text(data.fullName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  pw.Widget _buildCreativeTemplate() {
    final date = DateFormat('MMMM d, yyyy').format(DateTime.now());
    final manager = data.hiringManager.isNotEmpty ? data.hiringManager : 'Hiring Manager';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 1,
              child: pw.Container(
                color: PdfColors.blue800,
                padding: pw.EdgeInsets.all(24),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(data.fullName, style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                    pw.SizedBox(height: 8),
                    pw.Text(data.targetRole, style: pw.TextStyle(fontSize: 14, color: PdfColors.white)),
                    pw.SizedBox(height: 40),
                    pw.Text('CONTACT', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                    pw.SizedBox(height: 8),
                    pw.Text(data.email, style: pw.TextStyle(fontSize: 10, color: PdfColors.white)),
                    pw.Text(data.phone, style: pw.TextStyle(fontSize: 10, color: PdfColors.white)),
                    if (data.linkedIn.isNotEmpty) pw.Text(data.linkedIn, style: pw.TextStyle(fontSize: 10, color: PdfColors.white)),
                    if (data.address.isNotEmpty) pw.Text(data.address, style: pw.TextStyle(fontSize: 10, color: PdfColors.white)),
                  ],
                ),
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Container(
                padding: pw.EdgeInsets.all(24),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(date, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.SizedBox(height: 16),
                    pw.Text('To: $manager\n${data.companyName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 24),
                    pw.Text('Dear $manager,'),
                    pw.SizedBox(height: 16),
                    pw.Text('I have been following ${data.companyName} closely and was thrilled to see the opening for the ${data.targetRole} role. As a creative and driven professional with ${data.yearsExperience} of experience, I am excited about the prospect of bringing my unique perspective to your innovative team.'),
                    pw.SizedBox(height: 12),
                    pw.Text('My journey has equipped me with a robust set of skills, specifically in ${data.keySkills}. I thrive in dynamic environments where I can leverage these skills to build impactful solutions and push creative boundaries. I admire ${data.companyName}\'s commitment to pushing the envelope, and I am eager to contribute to that mission.'),
                    pw.SizedBox(height: 12),
                    pw.Text('I would love to connect and discuss how my blend of technical expertise and creative problem-solving can help ${data.companyName} achieve its upcoming goals. Thank you for considering my application.'),
                    pw.SizedBox(height: 24),
                    pw.Text('Best regards,'),
                    pw.SizedBox(height: 24),
                    pw.Text(data.fullName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildDirectTemplate() {
    final date = DateFormat('MMMM d, yyyy').format(DateTime.now());
    final manager = data.hiringManager.isNotEmpty ? data.hiringManager : 'Hiring Manager';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        pw.Center(
          child: pw.Text(data.fullName.toUpperCase(), style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            [
              data.email,
              data.phone,
              if (data.linkedIn.isNotEmpty) data.linkedIn,
            ].where((s) => s.isNotEmpty).join(' | '),
            style: pw.TextStyle(fontSize: 9),
          ),
        ),
        pw.SizedBox(height: 32),
        
        pw.Text(date),
        pw.SizedBox(height: 12),
        pw.Text('Re: ${data.targetRole} Position at ${data.companyName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 24),
        
        pw.Text('Dear $manager,'),
        pw.SizedBox(height: 16),
        pw.Text('I am writing to express my strong interest in the ${data.targetRole} position at ${data.companyName}.'),
        pw.SizedBox(height: 12),
        pw.Text('With ${data.yearsExperience} of experience and a deep understanding of ${data.keySkills}, I have a proven track record of delivering high-impact results. I am a fast learner, highly adaptable, and ready to hit the ground running to help your team succeed from day one.'),
        pw.SizedBox(height: 12),
        pw.Text('I am confident that my practical experience and drive make me a perfect fit for this role. I have attached my resume for your review and look forward to the opportunity to discuss my qualifications further.'),
        pw.SizedBox(height: 24),
        pw.Text('Sincerely,'),
        pw.SizedBox(height: 24),
        pw.Text(data.fullName),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: true,
        title: Text('Preview', style: AppTextStyles.heroTitle.copyWith(fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(format),
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        initialPageFormat: PdfPageFormat.a4,
      ),
    );
  }
}
