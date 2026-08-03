import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/widgets/universal_tool_card.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';

class DocuForgeScreen extends StatefulWidget {
  const DocuForgeScreen({super.key});

  @override
  State<DocuForgeScreen> createState() => _DocuForgeScreenState();
}

class _DocuForgeScreenState extends State<DocuForgeScreen> {
  String _searchQuery = '';
  bool _showAllTools = false;
  
  final List<Map<String, dynamic>> tools = [
      {'title': 'Resume Builder', 'subtitle': 'AI Resume Builder', 'icon': Icons.contact_page_rounded, 'color': AppColors.primaryPink, 'actionText': 'Build'},
      {'title': 'ATS Checker', 'subtitle': 'Resume ATS Checker', 'icon': Icons.fact_check_rounded, 'color': AppColors.primaryBlue, 'actionText': 'Check'},
      {'title': 'Cover Letter', 'subtitle': 'Generator via AI', 'icon': Icons.drafts_rounded, 'color': AppColors.primaryGreen, 'actionText': 'Generate'},
      {'title': 'Merge PDF', 'subtitle': 'Combine PDF files', 'icon': Icons.merge_type_rounded, 'color': AppColors.primaryYellow, 'actionText': 'Merge'},
      {'title': 'Split PDF', 'subtitle': 'Separate PDF pages', 'icon': Icons.call_split_rounded, 'color': AppColors.primaryPurple, 'actionText': 'Split'},
      {'title': 'Compress PDF', 'subtitle': 'Reduce PDF size', 'icon': Icons.compress_rounded, 'color': AppColors.primaryRed, 'actionText': 'Compress'},
      {'title': 'Image to PDF', 'subtitle': 'Convert images', 'icon': Icons.picture_as_pdf_rounded, 'color': AppColors.primaryBlue, 'actionText': 'Convert'},
      {'title': 'PDF to Image', 'subtitle': 'Extract images', 'icon': Icons.image_rounded, 'color': AppColors.primaryGreen, 'actionText': 'Convert'},
      {'title': 'Word to PDF', 'subtitle': 'Convert Word files', 'icon': Icons.description_rounded, 'color': AppColors.primaryPink, 'actionText': 'Convert'},
      {'title': 'PDF to Word', 'subtitle': 'Convert to Word', 'icon': Icons.article_rounded, 'color': AppColors.primaryYellow, 'actionText': 'Convert'},
      {'title': 'Excel to PDF', 'subtitle': 'Convert spreadsheets', 'icon': Icons.table_view_rounded, 'color': AppColors.primaryPurple, 'actionText': 'Convert'},
      {'title': 'PPT to PDF', 'subtitle': 'Convert presentations', 'icon': Icons.present_to_all_rounded, 'color': AppColors.primaryRed, 'actionText': 'Convert'},
      {'title': 'Digital Sign', 'subtitle': 'Sign documents', 'icon': Icons.draw_rounded, 'color': AppColors.primaryBlue, 'actionText': 'Sign'},
      {'title': 'Watermark PDF', 'subtitle': 'Add watermark', 'icon': Icons.branding_watermark_rounded, 'color': AppColors.primaryGreen, 'actionText': 'Add'},
      {'title': 'Document Scan', 'subtitle': 'Scan physical docs', 'icon': Icons.document_scanner_rounded, 'color': AppColors.primaryPink, 'actionText': 'Scan'},
      {'title': 'OCR Scanner', 'subtitle': 'Extract text', 'icon': Icons.document_scanner_outlined, 'color': AppColors.primaryYellow, 'actionText': 'Extract'},
      {'title': 'ID Card Gen', 'subtitle': 'Create ID cards', 'icon': Icons.badge_rounded, 'color': AppColors.primaryBlue, 'actionText': 'Generate'},
  ];

  void _showComingSoon(BuildContext context) {
    SnackbarUtils.showNeoSnackBar(context, message: 'This DocuForge feature is coming soon!');
  }

  @override
  Widget build(BuildContext context) {
    var filteredTools = tools.where((tool) {
      final title = (tool['title'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query);
    }).toList();

    if (_searchQuery.isEmpty && !_showAllTools) {
      filteredTools = filteredTools.take(6).toList();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: filteredTools.length,
                      itemBuilder: (context, index) {
                        final tool = filteredTools[index];
                        return _buildUtilityCard(context, tool);
                      },
                    ),
                    if (_searchQuery.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _showAllTools = !_showAllTools;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryYellow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(4, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              _showAllTools ? 'View Less' : 'View More',
                              style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: NeoCard(
        backgroundColor: const Color(0xFF00A2C7),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        borderRadius: 12,
        shadowOffset: const Offset(4, 4),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                  ],
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.black, size: 18),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Docu',
                        style: AppTextStyles.heroTitle.copyWith(fontSize: 22, color: Colors.white),
                      ),
                      Text(
                        'Forge',
                        style: AppTextStyles.logoText.copyWith(fontSize: 22, color: Colors.white, fontWeight: FontWeight.normal, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                  Text(
                    'ADVANCED DOCUMENT TOOLS',
                    style: AppTextStyles.caption.copyWith(fontSize: 9, letterSpacing: 2, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search DocuForge tools...',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.onSurface),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }

  Widget _buildUtilityCard(BuildContext context, Map<String, dynamic> tool) {
    final cardColor = tool['color'] as Color;

    return UniversalToolCard(
      title: tool['title'] as String,
      subtitle: tool['subtitle'] as String?,
      color: cardColor,
      icon: tool['icon'] as IconData,
      actionText: tool['actionText'] as String,
      onTap: () {
        if (tool['title'] == 'Resume Builder') {
          context.push('/resume-builder');
        } else if (tool['title'] == 'ATS Checker') {
          context.push('/ats-checker');
        } else if (tool['title'] == 'Cover Letter') {
          context.push('/cover-letter');
        } else if (tool['title'] == 'OCR Scanner') {
          context.push('/file-tools/ocr-scanner');
        } else if (tool['title'] == 'ID Card Gen') {
          context.push('/id-card-generator');
        } else if (['Merge PDF', 'Split PDF', 'Compress PDF', 'Image to PDF', 'PDF to Image', 'Word to PDF', 'PDF to Word', 'Excel to PDF', 'PPT to PDF', 'Document Scan', 'Digital Sign', 'Watermark PDF'].contains(tool['title'])) {
          
          final Map<String, dynamic> config = {
            'title': tool['title'],
            'icon': tool['icon'],
            'color': tool['color'],
          };

          if (tool['title'] == 'Merge PDF') {
            config.addAll({'multi': true, 'ext': ['pdf'], 'action': 'mergePdf'});
          } else if (tool['title'] == 'Split PDF') {
            config.addAll({'multi': false, 'ext': ['pdf'], 'action': 'splitPdf'});
          } else if (tool['title'] == 'Compress PDF') {
            config.addAll({'multi': false, 'ext': ['pdf'], 'action': 'compressPdf'});
          } else if (tool['title'] == 'Image to PDF') {
            config.addAll({'multi': true, 'ext': ['jpg', 'jpeg', 'png'], 'action': 'imagesToPdf'});
          } else if (tool['title'] == 'PDF to Image') {
            config.addAll({'multi': false, 'ext': ['pdf'], 'endpoint': '/docuforge/pdf-to-image', 'outExt': 'zip'});
          } else if (tool['title'] == 'Word to PDF') {
            config.addAll({'multi': false, 'ext': ['doc', 'docx'], 'endpoint': '/docuforge/word-to-pdf', 'outExt': 'pdf'});
          } else if (tool['title'] == 'PDF to Word') {
            config.addAll({'multi': false, 'ext': ['pdf'], 'endpoint': '/docuforge/pdf-to-word', 'outExt': 'docx'});
          } else if (tool['title'] == 'Excel to PDF') {
            config.addAll({'multi': false, 'ext': ['xls', 'xlsx'], 'endpoint': '/docuforge/excel-to-pdf', 'outExt': 'pdf'});
          } else if (tool['title'] == 'PPT to PDF') {
            config.addAll({'multi': false, 'ext': ['ppt', 'pptx'], 'endpoint': '/docuforge/ppt-to-pdf', 'outExt': 'pdf'});
          } else if (tool['title'] == 'Document Scan') {
            config.addAll({'multi': false, 'ext': ['jpg', 'jpeg', 'png'], 'action': 'documentScan', 'outExt': 'pdf'});
          } else if (tool['title'] == 'Digital Sign') {
            config.addAll({
              'twoInputs': true,
              'input1Label': 'Select PDF Document',
              'input1Ext': ['pdf'],
              'input2Label': 'Select Signature Image',
              'input2Ext': ['jpg', 'jpeg', 'png'],
              'action': 'digitalSign',
              'outExt': 'pdf'
            });
          } else if (tool['title'] == 'Watermark PDF') {
            config.addAll({
              'twoInputs': true,
              'input1Label': 'Select PDF Document',
              'input1Ext': ['pdf'],
              'input2Label': 'Select Watermark Image',
              'input2Ext': ['jpg', 'jpeg', 'png'],
              'action': 'watermarkPdf',
              'outExt': 'pdf'
            });
          } else {
            config.addAll({'multi': false, 'ext': ['pdf'], 'action': 'compressPdf'}); // fallback
          }
          
          context.push('/docuforge-tool', extra: config);
        } else {
          _showComingSoon(context);
        }
      },
    );
  }
}
