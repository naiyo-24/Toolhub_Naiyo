import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import '../providers/file_tools_providers.dart';

class MergePdfScreen extends ConsumerStatefulWidget {
  const MergePdfScreen({super.key});

  @override
  ConsumerState<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends ConsumerState<MergePdfScreen> {
  final List<PlatformFile> _selectedFiles = [];
  bool _isLoading = false;
  String _resultMessage = '';
  String? _savedFilePath;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() {
        _selectedFiles.addAll(result.files);
        _resultMessage = '';
        _savedFilePath = null;
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _executeAction() async {
    if (_selectedFiles.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 2 PDFs to merge!'), backgroundColor: Colors.red),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _resultMessage = '';
      _savedFilePath = null;
    });

    try {
      final service = ref.read(fileToolsServiceProvider);
      
      final xfiles = _selectedFiles.map((f) => XFile(f.path!)).toList();
      final bytes = await service.mergePdf(xfiles);
      
      final dir = await getApplicationDocumentsDirectory();
      final target = '${dir.path}/merged_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(target);
      await file.writeAsBytes(bytes);
      
      setState(() {
        _isLoading = false;
        _savedFilePath = target;
        _resultMessage = 'PDFs merged successfully!';
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _resultMessage = 'Error: $e';
      });
    }
  }

  Future<void> _downloadFile() async {
    if (_savedFilePath == null) return;
    try {
      final fileName = _savedFilePath!.split('/').last;
      final bytes = await File(_savedFilePath!).readAsBytes();
      
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Merged PDF',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: bytes,
      );

      if (outputFile != null) {
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          await File(outputFile).writeAsBytes(bytes);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File saved successfully!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _shareFile() {
    if (_savedFilePath == null) return;
    // ignore: deprecated_member_use
    Share.shareXFiles([XFile(_savedFilePath!)], text: 'Here is the merged PDF!');
  }

  void _openFile() {
    if (_savedFilePath == null) return;
    OpenFilex.open(_savedFilePath!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Merge PDFs', style: AppTextStyles.heroTitle.copyWith(fontSize: 20, color: Colors.white)),
        backgroundColor: AppColors.primaryPink,
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
                  Text("1. Tap 'Add PDFs' to select files.\n2. Tap 'Merge PDFs' when you have 2 or more files.\n3. Open, Share, or Download the result.", style: AppTextStyles.bodyText.copyWith(fontSize: 14)),
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
                const Icon(Icons.picture_as_pdf_rounded, size: 64, color: AppColors.primaryPink),
                const SizedBox(height: 16),
                Text('Merge multiple PDFs', textAlign: TextAlign.center, style: AppTextStyles.heroTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 32),
                
                if (_selectedFiles.isNotEmpty) ...[
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                    ),
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _selectedFiles.length,
                      separatorBuilder: (context, index) => const Divider(color: Colors.black, height: 1),
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                          title: Text(
                            _selectedFiles[index].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.black),
                            onPressed: () => _removeFile(index),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _pickFiles,
                    icon: const Icon(Icons.add_rounded, color: Colors.black),
                    label: Text(_selectedFiles.isEmpty ? 'Select PDFs' : 'Add More PDFs', style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _selectedFiles.length < 2 || _isLoading ? null : _executeAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedFiles.length < 2 ? Colors.grey[300] : AppColors.primaryPink,
                      foregroundColor: _selectedFiles.length < 2 ? Colors.grey[500] : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Text('Merge PDFs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _selectedFiles.length < 2 ? Colors.grey[500] : Colors.white)),
                  ),
                ),
                
                if (_resultMessage.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _resultMessage.startsWith('Error') ? Colors.red[50] : Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _resultMessage.startsWith('Error') ? Colors.red : Colors.green),
                    ),
                    child: Column(
                      children: [
                        Text(_resultMessage, textAlign: TextAlign.center, style: TextStyle(color: _resultMessage.startsWith('Error') ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                        
                        if (_savedFilePath != null) ...[
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _openFile,
                                  icon: const Icon(Icons.remove_red_eye_rounded, color: Colors.white),
                                  label: const Text('PREVIEW', style: AppTextStyles.buttonText),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryGreen,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: const BorderSide(color: Colors.black, width: 2),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _shareFile,
                                  icon: const Icon(Icons.share_rounded, color: Colors.black),
                                  label: const Text('SHARE', style: AppTextStyles.buttonText),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryYellow,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: const BorderSide(color: Colors.black, width: 2),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _downloadFile,
                              icon: const Icon(Icons.download_rounded, color: Colors.white),
                              label: const Text('DOWNLOAD', style: AppTextStyles.buttonText),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryPurple,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(color: Colors.black, width: 2),
                                ),
                              ),
                            ),
                          ),
                        ]
                      ]
                    ),
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
