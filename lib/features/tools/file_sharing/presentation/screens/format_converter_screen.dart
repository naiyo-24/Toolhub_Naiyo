import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tool_hub/core/api/api_client.dart';
import 'package:tool_hub/core/api/api_config.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import 'package:open_filex/open_filex.dart';

class FormatConverterScreen extends StatefulWidget {
  const FormatConverterScreen({super.key});

  @override
  State<FormatConverterScreen> createState() => _FormatConverterScreenState();
}

class _FormatConverterScreenState extends State<FormatConverterScreen> {
  File? _selectedFile;
  String? _selectedFormat;
  File? _convertedFile;
  bool _isLoading = false;

  final Map<String, List<String>> _allowedConversions = {
    'jpg': ['png', 'webp', 'bmp', 'tiff', 'gif', 'pdf'],
    'jpeg': ['png', 'webp', 'bmp', 'tiff', 'gif', 'pdf'],
    'png': ['jpg', 'webp', 'bmp', 'tiff', 'gif', 'pdf'],
    'webp': ['jpg', 'png', 'bmp', 'tiff', 'gif', 'pdf'],
    'heic': ['jpg', 'png', 'webp', 'bmp', 'tiff', 'gif', 'pdf'],
    'bmp': ['jpg', 'png', 'webp', 'tiff', 'gif', 'pdf'],
    'tiff': ['jpg', 'png', 'webp', 'bmp', 'gif', 'pdf'],
    'gif': ['jpg', 'png', 'webp', 'bmp', 'tiff', 'pdf'],
    'svg': ['jpg', 'png', 'webp', 'bmp', 'tiff', 'gif', 'pdf'],
    'avif': ['jpg', 'png', 'webp', 'bmp', 'tiff', 'gif', 'pdf'],
    'pdf': ['jpg', 'jpeg', 'png', 'webp'],
  };

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'heic', 'bmp', 'tiff', 'gif', 'svg', 'avif', 'pdf'],
    );
    if (result != null && result.files.single.path != null) {
      if (!mounted) return;
      
      final file = File(result.files.single.path!);
      final ext = file.path.split('.').last.toLowerCase();
      
      setState(() {
        _selectedFile = file;
        _selectedFormat = null;
        _convertedFile = null;
      });
      
      if (!_allowedConversions.containsKey(ext)) {
        SnackbarUtils.showNeoSnackBar(context, message: 'Format .$ext is not supported for conversion.');
        setState(() {
          _selectedFile = null;
        });
      }
    }
  }

  void _convertFile() async {
    if (_selectedFile == null || _selectedFormat == null) return;

    setState(() => _isLoading = true);

    try {
      final ext = _selectedFile!.path.split('.').last.toLowerCase();
      final targetExt = _selectedFormat!;
      
      String endpoint = '';
      FormData formData;
      bool expectsZip = false;

      if (ext == 'pdf') {
        // PDF to Image
        endpoint = '${ApiConfig.baseUrl}/docuforge/pdf-to-image';
        formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(_selectedFile!.path),
          'output_format': targetExt,
        });
        expectsZip = true;
      } else if (targetExt == 'pdf') {
        // Image to PDF
        endpoint = '${ApiConfig.baseUrl}/docuforge/image-to-pdf';
        formData = FormData.fromMap({
          'images': [await MultipartFile.fromFile(_selectedFile!.path)],
        });
      } else {
        // Image to Image
        endpoint = '${ApiConfig.baseUrl}/file-tools/image-convert';
        formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(_selectedFile!.path),
          'target_format': targetExt,
        });
      }

      final response = await ApiClient().dio.post(
        endpoint,
        data: formData,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      final tempDir = await getTemporaryDirectory();
      final outExt = expectsZip ? 'zip' : targetExt;
      final outFilename = 'converted_${DateTime.now().millisecondsSinceEpoch}.$outExt';
      final file = File('${tempDir.path}/$outFilename');
      await file.writeAsBytes(response.data);

      if (mounted) {
        setState(() {
          _convertedFile = file;
        });
        SnackbarUtils.showNeoSnackBar(
          context, 
          message: 'Conversion successful! Ready to save or share.',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showNeoSnackBar(context, message: 'Failed to convert file: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _shareFile() async {
    if (_convertedFile == null) return;
    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(_convertedFile!.path)], text: 'Check out my converted file!');
  }

  void _downloadFile() async {
    if (_convertedFile == null) return;
    final ext = _convertedFile!.path.split('.').last.toLowerCase();
    try {
      if (['jpg', 'jpeg', 'png', 'webp', 'bmp', 'heic', 'gif'].contains(ext)) {
        final hasAccess = await Gal.hasAccess();
        if (!hasAccess) {
          await Gal.requestAccess();
        }
        await Gal.putImage(_convertedFile!.path);
        if (mounted) {
          SnackbarUtils.showNeoSnackBar(context, message: 'Image saved to Gallery!', isError: false);
        }
      } else {
        // For PDFs and ZIPs, use OpenFilex to let the user view/save it.
        final result = await OpenFilex.open(_convertedFile!.path);
        if (result.type != ResultType.done && mounted) {
          SnackbarUtils.showNeoSnackBar(context, message: result.message);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showNeoSnackBar(context, message: 'Failed to save file: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> availableTargets = [];
    if (_selectedFile != null) {
      final ext = _selectedFile!.path.split('.').last.toLowerCase();
      availableTargets = _allowedConversions[ext] ?? [];
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Format Converter'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const NeoCard(
              backgroundColor: AppColors.primaryYellow,
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.sync_alt, size: 48),
                  SizedBox(height: 16),
                  Text('Universal Converter', style: AppTextStyles.screenHeading),
                  SizedBox(height: 8),
                  Text(
                    'Convert images and PDFs to your desired format easily.',
                    style: AppTextStyles.bodyText,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _pickFile,
              child: NeoCard(
                backgroundColor: _selectedFile == null ? Colors.white : AppColors.primaryGreen,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      _selectedFile == null ? Icons.upload_file : Icons.check_circle,
                      size: 40,
                      color: _selectedFile == null ? Colors.black54 : Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedFile == null ? 'Tap to select file' : _selectedFile!.path.split('/').last,
                      style: AppTextStyles.buttonText.copyWith(
                        color: _selectedFile == null ? Colors.black : Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            if (_selectedFile != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFormat,
                    hint: const Text('Select target format', style: AppTextStyles.bodyText),
                    isExpanded: true,
                    items: availableTargets.map((format) {
                      return DropdownMenuItem(
                        value: format,
                        child: Text(format.toUpperCase(), style: AppTextStyles.bodyText),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedFormat = val;
                        _convertedFile = null;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: (_isLoading || _selectedFormat == null) ? null : _convertFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : const Text('CONVERT FILE', style: AppTextStyles.buttonText),
              ),
              if (_convertedFile != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _downloadFile,
                        icon: const Icon(Icons.download_rounded, color: Colors.white),
                        label: const Text('DOWNLOAD', style: AppTextStyles.buttonText),
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
              ],
            ],
          ],
        ),
      ),
    );
  }
}
