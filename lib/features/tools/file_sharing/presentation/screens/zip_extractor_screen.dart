import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
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

class ZipExtractorScreen extends ConsumerStatefulWidget {
  const ZipExtractorScreen({super.key});

  @override
  ConsumerState<ZipExtractorScreen> createState() => _ZipExtractorScreenState();
}

class _ZipExtractorScreenState extends ConsumerState<ZipExtractorScreen> {
  List<PlatformFile> _selectedFiles = [];
  List<dynamic> _extractedFilesList = [];
  bool _isLoading = false;
  String _resultMessage = '';
  
  // Track loading state for individual file actions
  String? _processingFile;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['zip'],
      allowCompression: false,
    );
    if (result != null) {
      setState(() {
        _selectedFiles = result.files;
        _extractedFilesList = [];
        _resultMessage = '';
      });
    }
  }

  Future<void> _analyzeZip() async {
    if (_selectedFiles.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _resultMessage = '';
      _extractedFilesList = [];
    });

    try {
      final service = ref.read(fileToolsServiceProvider);
      final xfile = XFile(_selectedFiles.first.path!);
      
      final result = await service.extractZip(xfile); // No targetFile = get JSON list
      
      setState(() {
        _isLoading = false;
        if (result['extracted_files'] != null) {
          _extractedFilesList = result['extracted_files'];
          _resultMessage = 'Successfully read ZIP contents!';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _resultMessage = 'Error reading ZIP: $e';
      });
    }
  }
  
  Future<void> _handleFileAction(String filename, String action) async {
    if (_selectedFiles.isEmpty) return;
    
    setState(() {
      _processingFile = filename;
    });
    
    try {
      final service = ref.read(fileToolsServiceProvider);
      final xfile = XFile(_selectedFiles.first.path!);
      
      // Hit backend to extract just this one file
      final result = await service.extractZip(xfile, targetFile: filename);
      
      if (result['bytes'] != null) {
        final bytes = result['bytes'] as List<int>;
        
        final dir = await getApplicationDocumentsDirectory();
        // Just the file name, avoiding folders if the zip has folders
        final safeFilename = filename.split('/').last;
        final target = '${dir.path}/$safeFilename';
        
        final file = File(target);
        await file.writeAsBytes(bytes);
        
        if (action == 'open') {
          await OpenFilex.open(target);
        } else if (action == 'share') {
          // ignore: deprecated_member_use
          await Share.shareXFiles([XFile(target)], text: 'Extracted file: $safeFilename');
        } else if (action == 'download') {
          final String? outputFile = await FilePicker.platform.saveFile(
            dialogTitle: 'Save Extracted File',
            fileName: safeFilename,
            type: FileType.any,
            bytes: Uint8List.fromList(bytes),
          );

          if (outputFile != null) {
            if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
              await File(outputFile).writeAsBytes(bytes);
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File downloaded successfully!'), backgroundColor: Colors.green),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process file: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingFile = null;
        });
      }
    }
  }

  String _formatSize(int bytes) {
    return bytes > 1000000 
        ? '${(bytes / 1000000).toStringAsFixed(2)} MB' 
        : '${(bytes / 1000).toStringAsFixed(2)} KB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('ZIP Extractor', style: AppTextStyles.heroTitle.copyWith(fontSize: 20, color: Colors.white)),
        backgroundColor: AppColors.primaryYellow,
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
                  Text("1. Pick a .zip file.\n2. Tap 'Read ZIP Archive' to see files.\n3. Open, Share, or Download individual files.", style: AppTextStyles.bodyText.copyWith(fontSize: 14)),
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
                  const Icon(Icons.folder_zip_rounded, size: 64, color: AppColors.primaryYellow),
                  const SizedBox(height: 16),
                  Text('Extract ZIP Archive', style: AppTextStyles.heroTitle.copyWith(fontSize: 20)),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _pickFiles,
                      icon: const Icon(Icons.folder_open_rounded, color: Colors.black),
                      label: Text(
                        _selectedFiles.isEmpty 
                          ? 'Select ZIP File' 
                          : '${_selectedFiles.first.name} (${_formatSize(_selectedFiles.first.size)})', 
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)
                      ),
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
                  
                  if (_extractedFilesList.isEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _selectedFiles.isEmpty || _isLoading ? null : _analyzeZip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedFiles.isEmpty ? Colors.grey[300] : AppColors.primaryYellow,
                          foregroundColor: _selectedFiles.isEmpty ? Colors.grey[500] : Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Colors.black, width: 2),
                          ),
                        ),
                        child: _isLoading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                          : Text('Read ZIP Archive', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _selectedFiles.isEmpty ? Colors.grey[500] : Colors.black)),
                      ),
                    ),
                  ],
                  
                  if (_resultMessage.isNotEmpty && _extractedFilesList.isEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _resultMessage.startsWith('Error') ? Colors.red[50] : Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _resultMessage.startsWith('Error') ? Colors.red : Colors.green),
                      ),
                      child: Text(_resultMessage, textAlign: TextAlign.center, style: TextStyle(color: _resultMessage.startsWith('Error') ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                    ),
                  ],
                  
                  if (_extractedFilesList.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Divider(color: Colors.black, thickness: 2),
                    const SizedBox(height: 16),
                    Text('ZIP Contents (${_extractedFilesList.length} files)', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 16),
                    
                    ..._extractedFilesList.map((fileData) {
                      final filename = fileData['filename'] as String;
                      final sizeBytes = fileData['size_bytes'] as int;
                      final isProcessing = _processingFile == filename;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border: Border.all(color: Colors.black, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.insert_drive_file_rounded, color: Colors.blueGrey, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    filename,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  _formatSize(sizeBytes),
                                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            isProcessing 
                              ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _handleFileAction(filename, 'open'),
                                      icon: const Icon(Icons.remove_red_eye_rounded, size: 16, color: Colors.white),
                                      label: const Text('Open', style: TextStyle(fontSize: 12, color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        minimumSize: const Size(0, 36),
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _handleFileAction(filename, 'share'),
                                      icon: const Icon(Icons.share_rounded, size: 16, color: Colors.white),
                                      label: const Text('Share', style: TextStyle(fontSize: 12, color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        minimumSize: const Size(0, 36),
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _handleFileAction(filename, 'download'),
                                      icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
                                      label: const Text('Save', style: TextStyle(fontSize: 12, color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        minimumSize: const Size(0, 36),
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                    ),
                                  ],
                                ),
                          ],
                        ),
                      );
                    }),
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
