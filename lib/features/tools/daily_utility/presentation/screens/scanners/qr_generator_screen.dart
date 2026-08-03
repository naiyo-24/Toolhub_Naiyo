import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';
import '../../providers/daily_utility_providers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:gal/gal.dart';

class QrGeneratorScreen extends ConsumerStatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  ConsumerState<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends ConsumerState<QrGeneratorScreen> {
  final _inputController = TextEditingController();
  String _qrData = '';
  bool _isGenerating = false;
  bool _isSaving = false;
  Uint8List? _qrImageBytes;

  Color _qrColor = Colors.black;
  Color _bgColor = Colors.white;
  Color _borderColor = Colors.black;
  
  File? _logoFile;
  String? _logoBase64;

  final List<Color> _qrColors = [
    Colors.black,
    const Color(0xFF003049), // Dark Blue
    const Color(0xFFD62828), // Dark Red
    const Color(0xFF2A9D8F), // Teal
  ];

  final List<Color> _bgColors = [
    Colors.white,
    const Color(0xFFFDF0D5), // Light Cream
    const Color(0xFFE0FBFC), // Light Blue
    const Color(0xFFFDE2E4), // Light Pink
  ];

  final List<Color> _borderColors = [
    Colors.black,
    AppColors.primaryBlue,
    AppColors.primaryPink,
    AppColors.primaryYellow,
  ];

  void _pickColor(Color currentColor, Function(Color) onColorChanged) {
    showDialog(
      context: context,
      builder: (context) {
        Color tempColor = currentColor;
        return AlertDialog(
          title: const Text('Pick a color!'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColor,
              onColorChanged: (color) {
                tempColor = color;
              },
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Got it'),
              onPressed: () {
                onColorChanged(tempColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickLogo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      setState(() {
        _logoFile = file;
        _logoBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _generateQrCode() async {
    if (_qrData.isEmpty) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      String hexColor(Color c) => '#${c.toARGB32().toRadixString(16).substring(2).padLeft(6, '0')}';

      final bytes = await ref.read(dailyUtilityServiceProvider).generateQr(
        qrType: 'text',
        data: _qrData,
        fillColor: hexColor(_qrColor),
        backColor: hexColor(_bgColor),
        borderColor: hexColor(_borderColor),
        borderWidth: 20, // 20px border
        logoBase64: _logoBase64,
      );

      setState(() {
        _qrImageBytes = bytes;
        _isGenerating = false;
      });
    } catch (e) {
      if (mounted) SnackbarUtils.showNeoSnackBar(context, message: 'Error generating QR Code from server.');
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _downloadQrCode() async {
    if (_qrImageBytes == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_code.png');
      await file.writeAsBytes(_qrImageBytes!);

      final xFile = XFile(file.path);
      await SharePlus.instance.share(ShareParams(files: [xFile], text: 'My Custom QR Code'));

    } catch (e) {
      if (mounted) SnackbarUtils.showNeoSnackBar(context, message: 'Error sharing QR Code.');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _saveToGallery() async {
    if (_qrImageBytes == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Check if we have permission first, and request if needed.
      bool hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        hasAccess = await Gal.requestAccess();
      }

      if (hasAccess) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/qr_code_save.png');
        await file.writeAsBytes(_qrImageBytes!);
        
        await Gal.putImage(file.path);
        
        if (mounted) SnackbarUtils.showNeoSnackBar(context, message: 'QR Code saved to Gallery successfully!');
      } else {
        if (mounted) SnackbarUtils.showNeoSnackBar(context, message: 'Storage permission denied.', isError: true);
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showNeoSnackBar(context, message: 'Error saving to Gallery.', isError: true);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryPurple,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'QR Code Generator',
          style: AppTextStyles.heroTitle.copyWith(fontSize: 20, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Instructions
            NeoCard(
              backgroundColor: const Color(0xFFFFF9E6), // Light yellow tint for instructions
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
                  Text(
                    '1. Enter the text, link, or data you want to embed in the QR code.\n'
                    '2. Customize colors for the QR code, background, and borders using the color palette.\n'
                    '3. (Optional) Upload a logo to automatically center it inside the QR code.\n'
                    '4. Tap "Generate" to preview, then Save or Share it!', style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            NeoCard(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Enter Text or URL', style: AppTextStyles.sectionTitle.copyWith(fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      hintText: 'e.g., https://example.com',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.black, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.black, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _qrData = val;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // CUSTOMIZATIONS
                  Text('QR Color', style: AppTextStyles.sectionTitle.copyWith(fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ..._qrColors.map((c) => _buildColorPicker(c, _qrColor, (col) => setState(() => _qrColor = col))),
                      IconButton(
                        icon: const Icon(Icons.color_lens),
                        onPressed: () => _pickColor(_qrColor, (col) => setState(() => _qrColor = col)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Text('Background Color', style: AppTextStyles.sectionTitle.copyWith(fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ..._bgColors.map((c) => _buildColorPicker(c, _bgColor, (col) => setState(() => _bgColor = col))),
                      IconButton(
                        icon: const Icon(Icons.color_lens),
                        onPressed: () => _pickColor(_bgColor, (col) => setState(() => _bgColor = col)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text('Border Color', style: AppTextStyles.sectionTitle.copyWith(fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ..._borderColors.map((c) => _buildColorPicker(c, _borderColor, (col) => setState(() => _borderColor = col))),
                      IconButton(
                        icon: const Icon(Icons.color_lens),
                        onPressed: () => _pickColor(_borderColor, (col) => setState(() => _borderColor = col)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Text('Custom Logo (Optional)', style: AppTextStyles.sectionTitle.copyWith(fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickLogo,
                        icon: const Icon(Icons.upload_file, color: Colors.black),
                        label: Text(_logoFile != null ? 'Change Logo' : 'Upload Logo', style: const TextStyle(color: Colors.black)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      if (_logoFile != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_logoFile!.path.split('/').last, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _logoFile = null;
                              _logoBase64 = null;
                            });
                          },
                        )
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isGenerating ? null : _generateQrCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryYellow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      child: _isGenerating 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : Text('Generate QR Code', style: AppTextStyles.buttonText.copyWith(color: Colors.black)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_qrImageBytes != null)
              NeoCard(
                backgroundColor: AppColors.primaryPurple,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Image.memory(
                        _qrImageBytes!,
                        width: 200.0,
                        height: 200.0,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Text('Invalid data format or error', style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _saveToGallery,
                              icon: _isSaving 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                                : const Icon(Icons.download_rounded, color: Colors.black, size: 20),
                              label: Text(
                                _isSaving ? 'Saving...' : 'Save',
                                style: AppTextStyles.buttonText.copyWith(color: Colors.black, fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryYellow,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: Colors.black, width: 2),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _downloadQrCode,
                              icon: _isSaving 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                                : const Icon(Icons.share_rounded, color: Colors.black, size: 20),
                              label: Text(
                                _isSaving ? 'Wait...' : 'Share',
                                style: AppTextStyles.buttonText.copyWith(color: Colors.black, fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: Colors.black, width: 2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker(Color color, Color selectedColor, Function(Color) onSelect) {
    bool isSelected = color == selectedColor;
    return GestureDetector(
      onTap: () => onSelect(color),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple : Colors.black,
            width: isSelected ? 4 : 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
          ],
        ),
      ),
    );
  }
}
