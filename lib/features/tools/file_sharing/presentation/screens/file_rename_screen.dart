import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';

class FileRenameScreen extends ConsumerStatefulWidget {
  const FileRenameScreen({super.key});

  @override
  ConsumerState<FileRenameScreen> createState() => _FileRenameScreenState();
}

class _FileRenameScreenState extends ConsumerState<FileRenameScreen> {
  List<PlatformFile> _selectedFiles = [];
  List<File> _renamedFiles = [];
  bool _isLoading = false;
  String _resultMessage = '';
  
  final _passwordController = TextEditingController(); // acts as base name

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        _selectedFiles = result.files;
        _renamedFiles = [];
        _resultMessage = '';
      });
    }
  }

  Future<void> _executeAction() async {
    if (_selectedFiles.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _resultMessage = '';
      _renamedFiles = [];
    });

    try {
      if (_passwordController.text.isEmpty) throw Exception('Base name cannot be empty');
      final baseName = _passwordController.text;
      
      int count = 1;
      List<File> successfullyRenamed = [];
      
      for (var f in _selectedFiles) {
        if (f.path == null) continue;
        final file = File(f.path!);
        final ext = f.name.split('.').last;
        final newPath = '${file.parent.path}/${baseName}_$count.$ext';
        final newFile = await file.rename(newPath);
        successfullyRenamed.add(newFile);
        count++;
      }
      
      setState(() {
        _isLoading = false;
        _renamedFiles = successfullyRenamed;
        _resultMessage = 'Successfully renamed ${count - 1} files!';
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _resultMessage = 'Error: $e';
      });
    }
  }

  Future<void> _handleFileAction(File file, String action) async {
    try {
      if (action == 'open') {
        await OpenFilex.open(file.path);
      } else if (action == 'share') {
        final filename = file.path.split('/').last;
        // ignore: deprecated_member_use
        await Share.shareXFiles([XFile(file.path)], text: 'Renamed file: $filename');
      } else if (action == 'download') {
        final filename = file.path.split('/').last;
        final bytes = await file.readAsBytes();
        final String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Renamed File',
          fileName: filename,
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process file: $e'), backgroundColor: Colors.red),
        );
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
        title: Text('Bulk Rename Files', style: AppTextStyles.heroTitle.copyWith(fontSize: 20, color: Colors.white)),
        backgroundColor: AppColors.primaryBlue,
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
                  Text("1. Pick multiple files.\n2. Enter a new base name.\n3. Tap 'Rename Multiple Files'.\n4. Open, Share, or Save your new files!", style: AppTextStyles.bodyText.copyWith(fontSize: 14)),
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
                  const Icon(Icons.drive_file_rename_outline_rounded, size: 64, color: AppColors.primaryBlue),
                  const SizedBox(height: 16),
                  Text('Rename Multiple Files', style: AppTextStyles.heroTitle.copyWith(fontSize: 20)),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _pickFiles,
                      icon: const Icon(Icons.folder_open_rounded, color: Colors.black),
                      label: Text(_selectedFiles.isEmpty ? 'Select Files' : '${_selectedFiles.length} File(s) Selected', style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
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
                        labelText: 'New Base Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  
                  if (_renamedFiles.isEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _selectedFiles.isEmpty || _isLoading ? null : _executeAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedFiles.isEmpty ? Colors.grey[300] : AppColors.primaryBlue,
                          foregroundColor: _selectedFiles.isEmpty ? Colors.grey[500] : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Colors.black, width: 2),
                          ),
                        ),
                        child: _isLoading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : Text('Rename Multiple Files', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _selectedFiles.isEmpty ? Colors.grey[500] : Colors.white)),
                      ),
                    ),
                  ],
                  
                  if (_resultMessage.isNotEmpty && _renamedFiles.isEmpty) ...[
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
                  
                  if (_renamedFiles.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Divider(color: Colors.black, thickness: 2),
                    const SizedBox(height: 16),
                    const Text('Renamed Files', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 16),
                    
                    ..._renamedFiles.map((file) {
                      final filename = file.path.split('/').last;
                      final sizeBytes = file.lengthSync();
                      
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _handleFileAction(file, 'open'),
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
                                  onPressed: () => _handleFileAction(file, 'share'),
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
                                  onPressed: () => _handleFileAction(file, 'download'),
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
