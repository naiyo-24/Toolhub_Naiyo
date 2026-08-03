import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/widgets/universal_tool_card.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';

class FileSharingScreen extends StatefulWidget {
  const FileSharingScreen({super.key});

  @override
  State<FileSharingScreen> createState() => _FileSharingScreenState();
}

class _FileSharingScreenState extends State<FileSharingScreen> {
  String _searchQuery = '';
  bool _showAllTools = false;
  
  final List<Map<String, dynamic>> tools = [
      {'title': 'File Share', 'subtitle': 'Share files securely', 'icon': Icons.share_rounded, 'color': AppColors.primaryPink, 'actionText': 'Share', 'route': '/file-tools/file-share'},
      {'title': 'Rename Files', 'subtitle': 'Batch rename files', 'icon': Icons.drive_file_rename_outline_rounded, 'color': AppColors.primaryBlue, 'actionText': 'Rename', 'route': '/file-tools/rename-files'},
      {'title': 'ZIP Extractor', 'subtitle': 'Extract ZIP files', 'icon': Icons.folder_zip_rounded, 'color': AppColors.primaryGreen, 'actionText': 'Extract', 'route': '/file-tools/zip-extractor'},
      {'title': 'ZIP Creator', 'subtitle': 'Create ZIP files', 'icon': Icons.archive_rounded, 'color': AppColors.primaryYellow, 'actionText': 'Create', 'route': '/file-tools/zip-creator'},
      {'title': 'Compress Image', 'subtitle': 'Reduce image size', 'icon': Icons.image_rounded, 'color': AppColors.primaryPurple, 'actionText': 'Compress', 'route': '/file-tools/image-compressor'},
      {'title': 'Compress PDF', 'subtitle': 'Reduce PDF size', 'icon': Icons.picture_as_pdf_rounded, 'color': AppColors.primaryRed, 'actionText': 'Compress', 'route': '/file-tools/pdf-compressor'},
      {'title': 'Merge PDF', 'subtitle': 'Combine PDF files', 'icon': Icons.merge_rounded, 'color': AppColors.primaryBlue, 'actionText': 'Merge', 'route': '/file-tools/merge-pdf'},
      {'title': 'PDF Password', 'subtitle': 'Lock PDF files', 'icon': Icons.password_rounded, 'color': AppColors.primaryGreen, 'actionText': 'Lock', 'route': '/file-tools/pdf-password'},
      {'title': 'OCR Text Scanner', 'subtitle': 'Extract text from images', 'icon': Icons.document_scanner_rounded, 'color': AppColors.primaryPink, 'actionText': 'Scan', 'route': '/file-tools/ocr-scanner'},
      {'title': 'Duplicate Finder', 'subtitle': 'Find duplicate files', 'icon': Icons.control_point_duplicate_rounded, 'color': AppColors.primaryYellow, 'actionText': 'Find', 'route': '/file-tools/duplicate-finder'},
      {'title': 'Storage Analyzer', 'subtitle': 'Analyze storage space', 'icon': Icons.storage_rounded, 'color': AppColors.primaryPurple, 'actionText': 'Analyze', 'route': '/file-tools/storage-analyzer'},
      {'title': 'Format Converter', 'subtitle': 'Convert images & PDFs', 'icon': Icons.sync_alt_rounded, 'color': AppColors.primaryPink, 'actionText': 'Convert', 'route': '/file-tools/format-converter'},
  ];

  void _showComingSoon(BuildContext context) {
    SnackbarUtils.showNeoSnackBar(context, message: 'This tool is coming soon!');
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
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
              onPressed: () => context.pop(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'File Sharing Tools',
                  style: AppTextStyles.heroTitle.copyWith(fontSize: 24),
                ),
                Text(
                  'Manage and share your files',
                  style: AppTextStyles.bodyText.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: NeoCard(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: Colors.black54),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search tools...',
                  hintStyle: AppTextStyles.bodyText.copyWith(color: Colors.black38),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilityCard(BuildContext context, Map<String, dynamic> tool) {
    return UniversalToolCard(
      title: tool['title'],
      subtitle: tool['subtitle'],
      icon: tool['icon'],
      color: tool['color'],
      actionText: tool['actionText'],
      onTap: () {
        if (tool.containsKey('route')) {
          context.push(tool['route']);
        } else {
          _showComingSoon(context);
        }
      },
    );
  }
}
