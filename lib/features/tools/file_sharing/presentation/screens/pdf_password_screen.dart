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

class PdfPasswordScreen extends ConsumerStatefulWidget {
  const PdfPasswordScreen({super.key});

  @override
  ConsumerState<PdfPasswordScreen> createState() => _PdfPasswordScreenState();
}

class _PdfPasswordScreenState extends ConsumerState<PdfPasswordScreen> {
  List<PlatformFile> _selectedFiles = [];
  bool _isLoading = false;
  String _resultMessage = '';
  String? _savedFilePath;
  
  final _passwordController = TextEditingController();

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
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
    
    setState(() {
      _isLoading = true;
      _resultMessage = '';
      _savedFilePath = null;
    });

    try {
      final service = ref.read(fileToolsServiceProvider);
      
      if (_passwordController.text.isEmpty) throw Exception('Password cannot be empty');
      final xfile = XFile(_selectedFiles.first.path!);
      final bytes = await service.protectPdf(xfile, _passwordController.text);
      
      final dir = await getApplicationDocumentsDirectory();
      final target = '${dir.path}/protected_${_selectedFiles.first.name}';
      final file = File(target);
      await file.writeAsBytes(bytes);
      
      setState(() {
        _isLoading = false;
        _savedFilePath = target;
        _resultMessage = 'Action completed successfully!';
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
      
      // Use FilePicker to let the user choose where to save it
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Protected PDF',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: bytes,
      );

      if (outputFile != null) {
        // file_picker auto-writes the bytes on Android/iOS/Web. 
        // On Desktop, it only returns the path, so we must manually write it.
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
    Share.shareXFiles([XFile(_savedFilePath!)], text: 'Here is the protected PDF!');
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
        title: Text('PDF Password', style: AppTextStyles.heroTitle.copyWith(fontSize: 20, color: Colors.white)),
        backgroundColor: AppColors.primaryPurple,
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
                  Text("1. Pick a PDF.\n2. Enter a password.\n3. Tap 'Protect PDF' to lock it.\n4. You can then Open, Share or Download it.", style: AppTextStyles.bodyText.copyWith(fontSize: 14)),
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
                const Icon(Icons.lock_rounded, size: 64, color: AppColors.primaryPurple),
                const SizedBox(height: 16),
                Text('Password Protect PDF', style: AppTextStyles.heroTitle.copyWith(fontSize: 20)),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _pickFiles,
                    icon: const Icon(Icons.folder_open_rounded, color: Colors.black),
                    label: Text(_selectedFiles.isEmpty ? 'Select PDF' : '${_selectedFiles.length} File(s) Selected', style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _selectedFiles.isEmpty || _isLoading ? null : _executeAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedFiles.isEmpty ? Colors.grey[300] : AppColors.primaryPurple,
                      foregroundColor: _selectedFiles.isEmpty ? Colors.grey[500] : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Text('Protect PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _selectedFiles.isEmpty ? Colors.grey[500] : Colors.white)),
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
