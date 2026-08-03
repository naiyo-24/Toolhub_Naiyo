import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_file/cross_file.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import '../providers/file_tools_providers.dart';

class OcrScannerScreen extends ConsumerStatefulWidget {
  const OcrScannerScreen({super.key});

  @override
  ConsumerState<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends ConsumerState<OcrScannerScreen> {
  List<PlatformFile> _selectedFiles = [];
  bool _isLoading = false;
  String _resultMessage = '';
  bool _isHandwritingMode = false;
  
  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
    );
    if (result != null) {
      setState(() {
        _selectedFiles = result.files;
        _resultMessage = '';
        
      });
    }
  }

  Future<void> _executeAction() async {
    if (_selectedFiles.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _resultMessage = '';
      
    });

    try {
      final service = ref.read(fileToolsServiceProvider);
      
      final xfile = XFile(_selectedFiles.first.path!);
      final result = _isHandwritingMode 
          ? await service.extractHandwritingOcr(xfile)
          : await service.extractOcr(xfile);
      
      setState(() {
        _isLoading = false;
        _resultMessage = 'Extracted Text:\n\n${result['extracted_text'] ?? 'No text found.'}';
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _resultMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('OCR Text', style: AppTextStyles.heroTitle.copyWith(fontSize: 20, color: Colors.white)),
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            NeoCard(
              backgroundColor: const Color(0xFFE0FBFC),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.black),
                      const SizedBox(width: 8),
                      Text('How to use', style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("1. Pick an image.\n2. Toggle Handwriting Mode if needed.\n3. Tap 'Extract Text' to scan.", style: AppTextStyles.bodyText.copyWith(fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            NeoCard(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.document_scanner_rounded, size: 64, color: AppColors.primaryGreen),
                const SizedBox(height: 16),
                Text('Extract Text from Images', style: AppTextStyles.heroTitle.copyWith(fontSize: 20)),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _pickFiles,
                    icon: const Icon(Icons.folder_open_rounded, color: Colors.black),
                    label: Text(_selectedFiles.isEmpty ? 'Select Image' : '${_selectedFiles.length} File(s) Selected', style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Handwriting Mode (Slower)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    Switch(
                      value: _isHandwritingMode,
                      onChanged: (val) {
                        setState(() {
                          _isHandwritingMode = val;
                        });
                      },
                      activeThumbColor: Colors.black,
                    ),
                  ],
                ),
                
                
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _selectedFiles.isEmpty || _isLoading ? null : _executeAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedFiles.isEmpty ? Colors.grey[300] : AppColors.primaryGreen,
                      foregroundColor: _selectedFiles.isEmpty ? Colors.grey[500] : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Text('Scan Image', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _selectedFiles.isEmpty ? Colors.grey[500] : Colors.white)),
                  ),
                ),
                if (_resultMessage.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _resultMessage.startsWith('Error') ? Colors.red[50] : Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _resultMessage.startsWith('Error') ? Colors.red : Colors.green),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_resultMessage.startsWith('Error'))
                          Text(_resultMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                        else ...[
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen),
                              const SizedBox(width: 8),
                              Text('Extracted Text', style: AppTextStyles.heroTitle.copyWith(fontSize: 18, color: AppColors.primaryGreen)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SelectableText(
                            _resultMessage.replaceFirst('Extracted Text:\n\n', ''), 
                            style: AppTextStyles.bodyText.copyWith(fontSize: 16)
                          ),
                        ]
                      ]
                    )
                  ),
                ],
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}
