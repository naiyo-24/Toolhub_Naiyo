import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/features/tools/docu_forge/data/docuforge_service.dart';

class FormatConverterScreen extends StatefulWidget {
  const FormatConverterScreen({super.key});

  @override
  State<FormatConverterScreen> createState() => _FormatConverterScreenState();
}

class _FormatConverterScreenState extends State<FormatConverterScreen> {
  final DocuForgeService _service = DocuForgeService();
  bool _isProcessing = false;
  String _processingTitle = '';

  final List<Map<String, dynamic>> _tools = [
    {
      'title': 'Merge PDF',
      'icon': Icons.merge_type_rounded,
      'color': AppColors.primaryBlue,
      'multi': true,
      'ext': ['pdf'],
      'action': 'mergePdf',
    },
    {
      'title': 'Compress PDF',
      'icon': Icons.compress_rounded,
      'color': AppColors.primaryPink,
      'multi': false,
      'ext': ['pdf'],
      'action': 'compressPdf',
    },
    {
      'title': 'Split PDF',
      'icon': Icons.call_split_rounded,
      'color': AppColors.primaryYellow,
      'multi': false,
      'ext': ['pdf'],
      'action': 'splitPdf',
    },
    {
      'title': 'Image to PDF',
      'icon': Icons.image_rounded,
      'color': AppColors.primaryGreen,
      'multi': true,
      'ext': ['jpg', 'jpeg', 'png'],
      'action': 'imagesToPdf',
    },
    {
      'title': 'PDF to Image',
      'icon': Icons.picture_as_pdf_rounded,
      'color': AppColors.primaryRed,
      'multi': false,
      'ext': ['pdf'],
      'endpoint': '/docuforge/pdf-to-image',
      'outExt': 'zip',
    },
    {
      'title': 'Word to PDF',
      'icon': Icons.description_rounded,
      'color': AppColors.primaryBlue,
      'multi': false,
      'ext': ['doc', 'docx'],
      'endpoint': '/docuforge/word-to-pdf',
      'outExt': 'pdf',
    },
    {
      'title': 'PDF to Word',
      'icon': Icons.article_rounded,
      'color': AppColors.primaryPink,
      'multi': false,
      'ext': ['pdf'],
      'endpoint': '/docuforge/pdf-to-word',
      'outExt': 'docx',
    },
    {
      'title': 'Excel to PDF',
      'icon': Icons.table_chart_rounded,
      'color': AppColors.primaryGreen,
      'multi': false,
      'ext': ['xls', 'xlsx'],
      'endpoint': '/docuforge/excel-to-pdf',
      'outExt': 'pdf',
    },
    {
      'title': 'PPT to PDF',
      'icon': Icons.slideshow_rounded,
      'color': AppColors.primaryYellow,
      'multi': false,
      'ext': ['ppt', 'pptx'],
      'endpoint': '/docuforge/ppt-to-pdf',
      'outExt': 'pdf',
    },
  ];

  Future<void> _handleToolTap(Map<String, dynamic> tool) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: List<String>.from(tool['ext']),
      allowMultiple: tool['multi'],
    );

    if (result == null || result.files.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _processingTitle = tool['title'];
    });

    try {
      List<int> bytes;
      
      if (tool['action'] == 'mergePdf') {
        final files = result.paths.map((p) => File(p!)).toList();
        bytes = await _service.mergePdf(files);
      } else if (tool['action'] == 'compressPdf') {
        bytes = await _service.compressPdf(File(result.files.single.path!), 50);
      } else if (tool['action'] == 'splitPdf') {
        // Simplified: Just splits first 2 pages for demo, could prompt user for range
        bytes = await _service.splitPdf(File(result.files.single.path!), "1-2");
      } else if (tool['action'] == 'imagesToPdf') {
        final files = result.paths.map((p) => File(p!)).toList();
        bytes = await _service.imagesToPdf(files);
      } else {
        // Generic converter
        bytes = await _service.convertFile(File(result.files.single.path!), tool['endpoint']);
      }

      final ext = tool['outExt'] ?? 'pdf';
      final tempDir = await getTemporaryDirectory();
      final outPath = '${tempDir.path}/converted_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final file = File(outPath);
      await file.writeAsBytes(bytes);

      if (mounted) {
        SnackbarUtils.showNeoSnackBar(context, message: 'Conversion successful!');
        // ignore: deprecated_member_use
        Share.shareXFiles([XFile(outPath)], text: 'Converted File');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showNeoSnackBar(context, message: 'Failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: true,
        title: Text('Format Converter', style: AppTextStyles.heroTitle.copyWith(fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: _tools.length,
            itemBuilder: (context, index) {
              final tool = _tools[index];
              return InkWell(
                onTap: _isProcessing ? null : () => _handleToolTap(tool),
                child: NeoCard(
                  backgroundColor: tool['color'],
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(tool['icon'], size: 48, color: Colors.black),
                      const SizedBox(height: 16),
                      Text(
                        tool['title'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: NeoCard(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primaryBlue),
                      const SizedBox(height: 16),
                      Text('Processing $_processingTitle...', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
