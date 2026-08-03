import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class PdfCompressorScreen extends ConsumerStatefulWidget {
  const PdfCompressorScreen({super.key});

  @override
  ConsumerState<PdfCompressorScreen> createState() => _PdfCompressorScreenState();
}

class _PdfCompressorScreenState extends ConsumerState<PdfCompressorScreen> {
  List<PlatformFile> _selectedFiles = [];
  bool _isLoading = false;
  String _resultMessage = '';
  String? _savedFilePath;
  
  String _compressionMode = 'quality'; // 'quality' or 'target_size'
  double _quality = 80;
  final _targetSizeController = TextEditingController();
  String _targetSizeUnit = 'KB';
  bool _extremeMode = false;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowCompression: false,
    );
    if (result != null) {
      setState(() {
        _selectedFiles = result.files;
        _resultMessage = '';
        _savedFilePath = null;
      });
    }
  }

  Future<void> _executeAction() async {
    if (_selectedFiles.isEmpty) return;
    
    if (_compressionMode == 'target_size' && _targetSizeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a target size.'), backgroundColor: Colors.red),
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
      
      final xfile = XFile(_selectedFiles.first.path!);
      
      int? targetKb;
      if (_compressionMode == 'target_size') {
        final val = double.tryParse(_targetSizeController.text) ?? 0;
        targetKb = _targetSizeUnit == 'MB' ? (val * 1024).toInt() : val.toInt();
        if (targetKb <= 0) throw Exception('Invalid target size.');
      }
      
      final bytes = await service.compressPdf(
        xfile, 
        _quality.toInt(), 
        targetSizeKb: targetKb,
        extremeMode: _extremeMode,
      );
      
      final dir = await getApplicationDocumentsDirectory();
      final target = '${dir.path}/compressed_${_selectedFiles.first.name}';
      final file = File(target);
      await file.writeAsBytes(bytes);
      
      int originalSize = 0;
      if (_selectedFiles.first.path != null) {
        try {
          originalSize = File(_selectedFiles.first.path!).lengthSync();
        } catch (_) {
          originalSize = _selectedFiles.first.size;
        }
      } else {
        originalSize = _selectedFiles.first.size;
      }
      final newSize = bytes.length;
      
      String formatSize(int bytes) {
        return bytes > 1000000 
            ? '${(bytes / 1000000).toStringAsFixed(2)} MB' 
            : '${(bytes / 1000).toStringAsFixed(2)} KB';
      }
      
      String resultText = '';
      if (newSize >= originalSize) {
        resultText = 'Notice: This PDF is already highly optimized and could not be compressed further without losing data.\nOriginal: ${formatSize(originalSize)}\nNew: ${formatSize(newSize)}';
      } else {
        final savedPercentage = 100 - ((newSize / originalSize) * 100);
        resultText = 'Success! Compressed by ${savedPercentage.toStringAsFixed(1)}%\nOriginal: ${formatSize(originalSize)}\nNew: ${formatSize(newSize)}';
      }
      
      setState(() {
        _isLoading = false;
        _savedFilePath = target;
        _resultMessage = resultText;
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
        dialogTitle: 'Save Compressed PDF',
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
    Share.shareXFiles([XFile(_savedFilePath!)], text: 'Here is the compressed PDF!');
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
        title: Text('Compress PDFs', style: AppTextStyles.heroTitle.copyWith(fontSize: 20, color: Colors.white)),
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
                  Text("1. Pick a PDF.\n2. Choose 'Quality Slider' or 'Target Size'.\n3. Tap 'Compress PDF' to reduce file size.", style: AppTextStyles.bodyText.copyWith(fontSize: 14)),
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
                Text('Compress PDF Size', style: AppTextStyles.heroTitle.copyWith(fontSize: 20)),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _pickFiles,
                    icon: const Icon(Icons.folder_open_rounded, color: Colors.black),
                    label: Builder(
                      builder: (context) {
                        if (_selectedFiles.isEmpty) return const Text('Select PDF', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold));
                        
                        final file = _selectedFiles.first;
                        int sizeInBytes = 0;
                        if (file.path != null) {
                          try {
                            sizeInBytes = File(file.path!).lengthSync();
                          } catch (_) {
                            sizeInBytes = file.size;
                          }
                        } else {
                          sizeInBytes = file.size;
                        }
                        
                        final sizeText = sizeInBytes > 1000000 
                            ? '${(sizeInBytes / 1000000).toStringAsFixed(2)} MB' 
                            : '${(sizeInBytes / 1000).toStringAsFixed(2)} KB';
                            
                        String displayName = file.name;
                        if (displayName.length > 20) {
                          displayName = '${displayName.substring(0, 10)}...${displayName.substring(displayName.length - 6)}';
                        }
                            
                        return Text(
                          '$displayName ($sizeText)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                        );
                      }
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
                if (_selectedFiles.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Radio<String>(
                        value: 'quality',
                        // ignore: deprecated_member_use
                        groupValue: _compressionMode,
                        activeColor: AppColors.primaryPink,
                        // ignore: deprecated_member_use
                        onChanged: (val) => setState(() => _compressionMode = val!),
                      ),
                      const Text('Quality Slider', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      Radio<String>(
                        value: 'target_size',
                        // ignore: deprecated_member_use
                        groupValue: _compressionMode,
                        activeColor: AppColors.primaryPink,
                        // ignore: deprecated_member_use
                        onChanged: (val) => setState(() => _compressionMode = val!),
                      ),
                      const Text('Target Size', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (_compressionMode == 'quality') ...[
                    Text('Quality: ${_quality.toInt()}%', style: AppTextStyles.sectionTitle.copyWith(fontSize: 14)),
                    Slider(
                      value: _quality,
                      min: 1,
                      max: 100,
                      divisions: 100,
                      activeColor: AppColors.primaryPink,
                      onChanged: (val) => setState(() => _quality = val),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _targetSizeController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              labelText: 'Enter Target Size',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _targetSizeUnit,
                              items: ['KB', 'MB'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _targetSizeUnit = val!;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Extreme Compression', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Warning: Converts pages to blurry images to forcefully reduce size.', style: TextStyle(fontSize: 12, color: Colors.red)),
                    value: _extremeMode,
                    activeThumbColor: AppColors.primaryPink,
                    onChanged: (val) => setState(() => _extremeMode = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
                
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _selectedFiles.isEmpty || _isLoading ? null : _executeAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedFiles.isEmpty ? Colors.grey[300] : AppColors.primaryPink,
                      foregroundColor: _selectedFiles.isEmpty ? Colors.grey[500] : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Text('Compress PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _selectedFiles.isEmpty ? Colors.grey[500] : Colors.white)),
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
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                onPressed: _openFile,
                                icon: const Icon(Icons.remove_red_eye_rounded, color: Colors.green),
                                tooltip: 'Open',
                              ),
                              IconButton(
                                onPressed: _shareFile,
                                icon: const Icon(Icons.share_rounded, color: Colors.green),
                                tooltip: 'Share',
                              ),
                              IconButton(
                                onPressed: _downloadFile,
                                icon: const Icon(Icons.download_rounded, color: Colors.green),
                                tooltip: 'Download',
                              ),
                            ],
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
