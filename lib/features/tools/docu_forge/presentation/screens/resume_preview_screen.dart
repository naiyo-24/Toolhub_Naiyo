import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import '../../data/resume_model.dart';

class ResumePreviewScreen extends StatelessWidget {
  final ResumeData resumeData;
  final String templateId;

  const ResumePreviewScreen({
    super.key,
    required this.resumeData,
    required this.templateId,
  });

  Future<pw.Document> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    if (templateId == 'modern') {
      _buildModernTemplate(pdf);
    } else if (templateId == 'minimal') {
      _buildMinimalTemplate(pdf);
    } else if (templateId == 'creative') {
      _buildCreativeTemplate(pdf);
    } else if (templateId == 'executive') {
      _buildExecutiveTemplate(pdf);
    } else {
      _buildClassicTemplate(pdf);
    }

    return pdf;
  }

  void _buildModernTemplate(pw.Document pdf) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                color: PdfColors.amber300,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(resumeData.fullName.toUpperCase(), style: const pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      [
                        resumeData.email,
                        resumeData.phone,
                        if (resumeData.linkedIn.isNotEmpty) resumeData.linkedIn,
                        if (resumeData.github.isNotEmpty) resumeData.github,
                      ].where((s) => s.isNotEmpty).join('  |  '),
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.black)
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Summary
              if (resumeData.summary.isNotEmpty) ...[
                pw.Text('PROFESSIONAL SUMMARY', style: const pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(resumeData.summary, style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 16),
              ],

              // Experience
              if (resumeData.experience.isNotEmpty) ...[
                pw.Text('EXPERIENCE', style: const pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Divider(color: PdfColors.black, thickness: 2),
                pw.SizedBox(height: 8),
                ...resumeData.experience.map((e) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(e['title'] ?? '', style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                          pw.Text(e['dates'] ?? '', style: const pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic)),
                        ]
                      ),
                      pw.Text(e['company'] ?? '', style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text(e['description'] ?? '', style: const pw.TextStyle(fontSize: 12)),
                    ]
                  ),
                )),
              ],

              // Projects
              if (resumeData.projects.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text('PROJECTS', style: const pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Divider(color: PdfColors.black, thickness: 2),
                pw.SizedBox(height: 8),
                ...resumeData.projects.map((p) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(p['title'] ?? '', style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                          if (p['link']?.isNotEmpty == true)
                            pw.Text(p['link']!, style: const pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic, color: PdfColors.blue)),
                        ]
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(p['description'] ?? '', style: const pw.TextStyle(fontSize: 12)),
                    ]
                  ),
                )),
              ],

              // Education
              if (resumeData.education.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text('EDUCATION', style: const pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Divider(color: PdfColors.black, thickness: 2),
                pw.SizedBox(height: 8),
                ...resumeData.education.map((e) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(e['degree'] ?? '', style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                          pw.Text(e['school'] ?? '', style: const pw.TextStyle(fontSize: 12)),
                        ]
                      ),
                      pw.Text(e['year'] ?? '', style: const pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic)),
                    ]
                  )
                )),
              ],

              // Skills
              if (resumeData.skills.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text('SKILLS', style: const pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Divider(color: PdfColors.black, thickness: 2),
                pw.SizedBox(height: 8),
                pw.Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: resumeData.skills.map((s) => pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200, borderRadius: pw.BorderRadius.all(pw.Radius.circular(4))),
                    child: pw.Text(s, style: const pw.TextStyle(fontSize: 12)),
                  )).toList(),
                )
              ]
            ],
          );
        },
      )
    );
  }

  void _buildMinimalTemplate(pw.Document pdf) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Text(resumeData.fullName, style: const pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text(
                [
                  resumeData.email,
                  resumeData.phone,
                  if (resumeData.linkedIn.isNotEmpty) resumeData.linkedIn,
                  if (resumeData.github.isNotEmpty) resumeData.github,
                ].where((s) => s.isNotEmpty).join(' • '),
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)
              ),
              pw.SizedBox(height: 24),
              
              // Summary
              if (resumeData.summary.isNotEmpty) ...[
                pw.Text('Summary', style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                pw.SizedBox(height: 8),
                pw.Text(resumeData.summary, style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5)),
                pw.SizedBox(height: 16),
              ],
              
              // Experience
              if (resumeData.experience.isNotEmpty) ...[
                pw.Text('Experience', style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                pw.SizedBox(height: 12),
                ...resumeData.experience.map((e) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 16),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(e['title'] ?? '', style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          pw.Text(e['dates'] ?? '', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                        ]
                      ),
                      pw.Text(e['company'] ?? '', style: const pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, color: PdfColors.grey800)),
                      pw.SizedBox(height: 4),
                      pw.Text(e['description'] ?? '', style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5)),
                    ]
                  ),
                )),
              ],

              // Projects
              if (resumeData.projects.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text('Projects', style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                pw.SizedBox(height: 12),
                ...resumeData.projects.map((p) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 16),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(p['title'] ?? '', style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          if (p['link']?.isNotEmpty == true)
                            pw.Text(p['link']!, style: const pw.TextStyle(fontSize: 10, color: PdfColors.blue)),
                        ]
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(p['description'] ?? '', style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5)),
                    ]
                  ),
                )),
              ],

              // Education
              if (resumeData.education.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text('Education', style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                pw.SizedBox(height: 12),
                ...resumeData.education.map((e) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(e['degree'] ?? '', style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          pw.Text(e['school'] ?? '', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800)),
                        ]
                      ),
                      pw.Text(e['year'] ?? '', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                    ]
                  )
                )),
              ],

              // Skills
              if (resumeData.skills.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text('Skills', style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                pw.SizedBox(height: 8),
                pw.Text(resumeData.skills.join(' • '), style: const pw.TextStyle(fontSize: 10)),
              ]
            ],
          );
        },
      )
    );
  }

  void _buildClassicTemplate(pw.Document pdf) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(resumeData.fullName, style: const pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(
                [
                  resumeData.email,
                  resumeData.phone,
                  if (resumeData.linkedIn.isNotEmpty) resumeData.linkedIn,
                  if (resumeData.github.isNotEmpty) resumeData.github,
                ].where((s) => s.isNotEmpty).join(' | '),
                style: const pw.TextStyle(fontSize: 11)
              ),
              pw.SizedBox(height: 16),
              
              if (resumeData.summary.isNotEmpty) ...[
                pw.Text(resumeData.summary, style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center),
                pw.SizedBox(height: 16),
              ],

              if (resumeData.experience.isNotEmpty) ...[
                pw.Divider(thickness: 1),
                pw.Text('EXPERIENCE', style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 8),
                ...resumeData.experience.map((e) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('${e['title']} - ${e['company']}', style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          pw.Text(e['dates'] ?? '', style: const pw.TextStyle(fontSize: 11)),
                        ]
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(e['description'] ?? '', style: const pw.TextStyle(fontSize: 10)),
                    ]
                  ),
                )),
              ],
              
              if (resumeData.projects.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 1),
                pw.Text('PROJECTS', style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 8),
                ...resumeData.projects.map((p) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(p['title'] ?? '', style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          if (p['link']?.isNotEmpty == true)
                            pw.Text(p['link']!, style: const pw.TextStyle(fontSize: 11, color: PdfColors.blue)),
                        ]
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(p['description'] ?? '', style: const pw.TextStyle(fontSize: 10)),
                    ]
                  ),
                )),
              ],

              if (resumeData.education.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 1),
                pw.Text('EDUCATION', style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 8),
                ...resumeData.education.map((e) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('${e['degree']} - ${e['school']}', style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.Text(e['year'] ?? '', style: const pw.TextStyle(fontSize: 11)),
                    ]
                  )
                )),
              ],

              if (resumeData.skills.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 1),
                pw.Text('SKILLS', style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 8),
                pw.Text(resumeData.skills.join(', '), style: const pw.TextStyle(fontSize: 10)),
              ]
            ],
          );
        },
      )
    );
  }

  void _buildCreativeTemplate(pw.Document pdf) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Sidebar
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(24),
                  color: PdfColors.teal800,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(resumeData.fullName, style: const pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                      pw.SizedBox(height: 16),
                      pw.Text('CONTACT', style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal200)),
                      pw.SizedBox(height: 4),
                      pw.Text(resumeData.email, style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
                      pw.Text(resumeData.phone, style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
                      if (resumeData.linkedIn.isNotEmpty)
                        pw.Text(resumeData.linkedIn, style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
                      if (resumeData.github.isNotEmpty)
                        pw.Text(resumeData.github, style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
                      pw.SizedBox(height: 24),
                      
                      if (resumeData.skills.isNotEmpty) ...[
                        pw.Text('SKILLS', style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal200)),
                        pw.SizedBox(height: 4),
                        ...resumeData.skills.map((s) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 2),
                          child: pw.Text('• $s', style: const pw.TextStyle(fontSize: 9, color: PdfColors.white))
                        )),
                        pw.SizedBox(height: 24),
                      ],
                      
                      if (resumeData.education.isNotEmpty) ...[
                        pw.Text('EDUCATION', style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal200)),
                        pw.SizedBox(height: 4),
                        ...resumeData.education.map((e) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 8),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(e['degree'] ?? '', style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                              pw.Text(e['school'] ?? '', style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
                              pw.Text(e['year'] ?? '', style: const pw.TextStyle(fontSize: 8, color: PdfColors.teal200)),
                            ]
                          )
                        )),
                      ],
                    ],
                  ),
                ),
              ),
              // Main Body
              pw.Expanded(
                flex: 2,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(32),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (resumeData.summary.isNotEmpty) ...[
                        pw.Text('PROFILE', style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                        pw.SizedBox(height: 8),
                        pw.Text(resumeData.summary, style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5)),
                        pw.SizedBox(height: 24),
                      ],
                      if (resumeData.experience.isNotEmpty) ...[
                        pw.Text('EXPERIENCE', style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                        pw.SizedBox(height: 12),
                        ...resumeData.experience.map((e) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 16),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(e['title'] ?? '', style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                              pw.Text('${e['company']} | ${e['dates']}', style: const pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
                              pw.SizedBox(height: 4),
                              pw.Text(e['description'] ?? '', style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5)),
                            ]
                          ),
                        )),
                      ],
                      if (resumeData.projects.isNotEmpty) ...[
                        pw.SizedBox(height: 8),
                        pw.Text('PROJECTS', style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                        pw.SizedBox(height: 12),
                        ...resumeData.projects.map((p) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 16),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(p['title'] ?? '', style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                                  if (p['link']?.isNotEmpty == true)
                                    pw.Text(p['link']!, style: const pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.teal700)),
                                ]
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(p['description'] ?? '', style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5)),
                            ]
                          ),
                        )),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      )
    );
  }

  void _buildExecutiveTemplate(pw.Document pdf) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(resumeData.fullName.toUpperCase(), style: const pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  [
                    resumeData.email,
                    resumeData.phone,
                    if (resumeData.linkedIn.isNotEmpty) resumeData.linkedIn,
                    if (resumeData.github.isNotEmpty) resumeData.github,
                  ].where((s) => s.isNotEmpty).join('  |  '),
                  style: const pw.TextStyle(fontSize: 9)
                ),
              ),
              pw.SizedBox(height: 24),
              
              if (resumeData.summary.isNotEmpty) ...[
                pw.Text('EXECUTIVE SUMMARY', style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.Divider(thickness: 0.5, color: PdfColors.grey500),
                pw.SizedBox(height: 8),
                pw.Text(resumeData.summary, style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5)),
                pw.SizedBox(height: 20),
              ],
              
              if (resumeData.experience.isNotEmpty) ...[
                pw.Text('PROFESSIONAL EXPERIENCE', style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.Divider(thickness: 0.5, color: PdfColors.grey500),
                pw.SizedBox(height: 8),
                ...resumeData.experience.map((e) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 16),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(e['company'] ?? '', style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          pw.Text(e['dates'] ?? '', style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        ]
                      ),
                      pw.Text(e['title'] ?? '', style: const pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
                      pw.SizedBox(height: 4),
                      pw.Text(e['description'] ?? '', style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5)),
                    ]
                  ),
                )),
              ],
              
              if (resumeData.projects.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text('KEY PROJECTS', style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.Divider(thickness: 0.5, color: PdfColors.grey500),
                pw.SizedBox(height: 8),
                ...resumeData.projects.map((p) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(p['title'] ?? '', style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          if (p['link']?.isNotEmpty == true)
                            pw.Text(p['link']!, style: const pw.TextStyle(fontSize: 10, color: PdfColors.blue)),
                        ]
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(p['description'] ?? '', style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5)),
                    ]
                  ),
                )),
              ],
              
              if (resumeData.education.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text('EDUCATION', style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.Divider(thickness: 0.5, color: PdfColors.grey500),
                pw.SizedBox(height: 8),
                ...resumeData.education.map((e) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(e['school'] ?? '', style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          pw.Text(e['degree'] ?? '', style: const pw.TextStyle(fontSize: 10)),
                        ]
                      ),
                      pw.Text(e['year'] ?? '', style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ]
                  )
                )),
              ],
              
              if (resumeData.skills.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text('CORE COMPETENCIES', style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.Divider(thickness: 0.5, color: PdfColors.grey500),
                pw.SizedBox(height: 8),
                pw.Text(resumeData.skills.join('  |  '), style: const pw.TextStyle(fontSize: 10)),
              ]
            ],
          );
        },
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        elevation: 0,
        centerTitle: true,
        title: Text('Preview Resume', style: AppTextStyles.heroTitle.copyWith(fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: PdfPreview(
        build: (format) async {
          final doc = await _generatePdf(format);
          return doc.save();
        },
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }
}
