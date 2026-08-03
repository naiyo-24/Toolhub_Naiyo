import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:open_filex/open_filex.dart';
import 'package:gal/gal.dart';
import 'package:tool_hub/features/tools/docu_forge/data/docuforge_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tool_hub/core/utils/permission_disclosure_utils.dart';

class DocuForgeToolScreen extends StatefulWidget {
  final Map<String, dynamic> toolConfig;

  const DocuForgeToolScreen({super.key, required this.toolConfig});

  @override
  State<DocuForgeToolScreen> createState() => _DocuForgeToolScreenState();
}

class _DocuForgeToolScreenState extends State<DocuForgeToolScreen> {
  final DocuForgeService _service = DocuForgeService();
  bool _isProcessing = false;
  final List<File> _selectedFiles = [];
  final TextEditingController _pagesController = TextEditingController(text: "1,2");
  double _quality = 50.0;
  String _scanType = 'magic_color';
  String _signaturePosition = 'bottom_right';
  final _watermarkTextController = TextEditingController();
  final _targetSizeController = TextEditingController();
  String? _resultPath;

  Future<void> _pickFilesFor(int inputIndex) async {
    final isInput1 = inputIndex == 0;
    final extKey = isInput1 ? 'input1Ext' : 'input2Ext';
    final extensions = widget.toolConfig[extKey] != null 
        ? List<String>.from(widget.toolConfig[extKey]) 
        : List<String>.from(widget.toolConfig['ext'] ?? []);
        
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        while (_selectedFiles.length <= inputIndex) {
          _selectedFiles.add(File('')); // Dummy file to avoid null errors
        }
        _selectedFiles[inputIndex] = File(result.paths.first!);
      });
    }
  }

  Future<void> _openSignatureDialog() async {
    final result = await showDialog<File>(
      context: context,
      builder: (context) => const _SignatureDialog(),
    );

    if (result != null) {
      setState(() {
        while (_selectedFiles.length <= 1) {
          _selectedFiles.add(File(''));
        }
        _selectedFiles[1] = result;
      });
    }
  }

  Future<void> _pickFiles() async {
    if (widget.toolConfig['action'] == 'documentScan') {
      final hasPermission = await PermissionDisclosureUtils.requestWithDisclosure(
        context,
        permission: Permission.camera,
        title: 'Camera Permission',
        description: 'We need access to your camera so you can scan documents.',
        icon: Icons.camera_alt,
        color: AppColors.primaryBlue,
      );

      if (!hasPermission) {
        if (mounted) {
          SnackbarUtils.showNeoSnackBar(context, message: 'Camera permission denied.', isError: true);
        }
        return;
      }

      // For document scan, we want to open the camera using image_picker
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Document',
              toolbarColor: AppColors.primaryPink,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
            IOSUiSettings(
              title: 'Crop Document',
            ),
          ],
        );
        
        if (croppedFile != null) {
          setState(() {
            _selectedFiles.add(File(croppedFile.path));
          });
        }
      }
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: List<String>.from(widget.toolConfig['ext'] ?? []),
      allowMultiple: widget.toolConfig['multi'] ?? false,
    );

    if (result != null) {
      setState(() {
        _selectedFiles.addAll(result.paths.map((p) => File(p!)));
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _processFiles() async {
    if (widget.toolConfig['action'] == 'watermarkPdf') {
      if (_selectedFiles.isEmpty || _selectedFiles[0].path.isEmpty) {
        SnackbarUtils.showNeoSnackBar(context, message: 'Please select a PDF document first.');
        return;
      }
      if ((_selectedFiles.length < 2 || _selectedFiles[1].path.isEmpty) && _watermarkTextController.text.trim().isEmpty) {
        SnackbarUtils.showNeoSnackBar(context, message: 'Please provide either a watermark image or text.');
        return;
      }
    } else if (widget.toolConfig['twoInputs'] == true) {
      if (_selectedFiles.length < 2 || _selectedFiles[0].path.isEmpty || _selectedFiles[1].path.isEmpty) {
        SnackbarUtils.showNeoSnackBar(context, message: 'Please select both required files.');
        return;
      }
    } else {
      if (_selectedFiles.isEmpty || _selectedFiles[0].path.isEmpty) {
        SnackbarUtils.showNeoSnackBar(context, message: 'Please select a file first.');
        return;
      }

      if (widget.toolConfig['multi'] == true && _selectedFiles.length < 2) {
        SnackbarUtils.showNeoSnackBar(context, message: 'Please select at least 2 files.');
        return;
      }
    }

    setState(() {
      _isProcessing = true;
      _resultPath = null;
    });

    try {
      List<int> bytes;
      
      if (widget.toolConfig['action'] == 'mergePdf') {
        bytes = await _service.mergePdf(_selectedFiles);
      } else if (widget.toolConfig['action'] == 'compressPdf') {
        int? targetSize;
        if (_targetSizeController.text.isNotEmpty) {
          targetSize = int.tryParse(_targetSizeController.text);
        }
        bytes = await _service.compressPdf(_selectedFiles.first, _quality.toInt(), targetSizeKb: targetSize);
      } else if (widget.toolConfig['action'] == 'splitPdf') {
        bytes = await _service.splitPdf(_selectedFiles.first, _pagesController.text);
      } else if (widget.toolConfig['action'] == 'digitalSign') {
        bytes = await _service.digitalSign(_selectedFiles[0], _selectedFiles[1], position: _signaturePosition);
      } else if (widget.toolConfig['action'] == 'watermarkPdf') {
        bytes = await _service.watermarkPdf(
          _selectedFiles[0], 
          watermarkImage: (_selectedFiles.length > 1 && _selectedFiles[1].path.isNotEmpty) ? _selectedFiles[1] : null,
          watermarkText: _watermarkTextController.text.trim(),
        );
      } else if (widget.toolConfig['action'] == 'imagesToPdf') {
        bytes = await _service.imagesToPdf(_selectedFiles);
      } else if (widget.toolConfig['action'] == 'documentScan') {
        bytes = await _service.documentScan(_selectedFiles, _scanType);
      } else {
        bytes = await _service.convertFile(_selectedFiles.first, widget.toolConfig['endpoint']);
      }

      final ext = widget.toolConfig['outExt'] ?? 'pdf';
      final tempDir = await getTemporaryDirectory();
      final outPath = '${tempDir.path}/${widget.toolConfig['title'].toString().replaceAll(" ", "_").toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final file = File(outPath);
      await file.writeAsBytes(bytes);

      if (mounted) {
        SnackbarUtils.showNeoSnackBar(context, message: 'Success!');
        setState(() {
          _resultPath = outPath;
        });
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
    final title = widget.toolConfig['title'] ?? 'Tool';
    final icon = widget.toolConfig['icon'] ?? Icons.build_rounded;
    final color = widget.toolConfig['color'] ?? AppColors.primaryBlue;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: color,
        elevation: 0,
        centerTitle: true,
        title: Text(title, style: AppTextStyles.heroTitle.copyWith(fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NeoCard(
              backgroundColor: const Color(0xFFE0FBFC), // Light Blue tint
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
                    "1. Select the required file(s) or input.\n2. Configure any options if provided.\n3. Tap the action button to process and get your result.",
                    style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            NeoCard(
              backgroundColor: color,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(icon, size: 48, color: Colors.black),
                  const SizedBox(height: 16),
                  Text('Use the $title tool easily.', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (widget.toolConfig['twoInputs'] == true) ...[
                    ElevatedButton(
                      onPressed: () => _pickFilesFor(0),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      child: Text(widget.toolConfig['input1Label'] ?? 'Select File 1'),
                    ),
                    const SizedBox(height: 8),
                    if (widget.toolConfig['action'] == 'digitalSign') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _openSignatureDialog(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                              ),
                              icon: const Icon(Icons.draw),
                              label: const Text('Draw Signature'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _pickFilesFor(1),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                              ),
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Upload'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _signaturePosition,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'top_left', child: Text('Position: Top Left')),
                              DropdownMenuItem(value: 'top_right', child: Text('Position: Top Right')),
                              DropdownMenuItem(value: 'center', child: Text('Position: Center')),
                              DropdownMenuItem(value: 'bottom_left', child: Text('Position: Bottom Left')),
                              DropdownMenuItem(value: 'bottom_right', child: Text('Position: Bottom Right')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _signaturePosition = val);
                            },
                          ),
                        ),
                      ),
                    ] else if (widget.toolConfig['action'] == 'watermarkPdf') ...[
                      const SizedBox(height: 16),
                      const Text('OR Use Text Watermark', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _watermarkTextController,
                        decoration: const InputDecoration(
                          hintText: 'Enter watermark text (e.g. CONFIDENTIAL)',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('OR Use Image Watermark', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _pickFilesFor(1),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        child: Text(widget.toolConfig['input2Label'] ?? 'Select File 2'),
                      ),
                    ] else ...[
                      ElevatedButton(
                        onPressed: () => _pickFilesFor(1),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        child: Text(widget.toolConfig['input2Label'] ?? 'Select File 2'),
                      ),
                    ],
                  ] else ...[
                    ElevatedButton(
                      onPressed: _pickFiles,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      child: Text(widget.toolConfig['action'] == 'documentScan' 
                          ? 'Add from Camera' 
                          : 'Select Files (${(widget.toolConfig['ext'] as List?)?.join(", ") ?? ""})'),
                    ),
                  ],
                ],
              ),
            ),
            
            if (_selectedFiles.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Text('Selected Files', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              ...List.generate(_selectedFiles.length, (index) {
                if (_selectedFiles[index].path.isEmpty) return const SizedBox.shrink();
                
                final isImage = ['jpg', 'jpeg', 'png'].any((ext) => _selectedFiles[index].path.toLowerCase().endsWith(ext));
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: NeoCard(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(isImage ? Icons.image : Icons.description, color: AppColors.primaryBlue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(_selectedFiles[index].path.split('/').last, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: AppColors.primaryRed),
                              onPressed: () => _removeFile(index),
                            )
                          ],
                        ),
                        if (isImage && widget.toolConfig['action'] == 'documentScan') ...[
                          const SizedBox(height: 12),
                          Center(
                            child: _buildImagePreview(_selectedFiles[index]),
                          ),
                        ] else if (isImage) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(_selectedFiles[index], height: 150, fit: BoxFit.cover),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              
              const SizedBox(height: 24),
              if (widget.toolConfig['action'] == 'splitPdf') ...[
                TextField(
                  controller: _pagesController,
                  decoration: const InputDecoration(
                    labelText: 'Pages to Extract (e.g. 1, 2, 4)',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              if (widget.toolConfig['action'] == 'compressPdf' || widget.toolConfig['action'] == 'documentScan') ...[
                if (widget.toolConfig['action'] == 'compressPdf') ...[
                  const Text('Compression Quality', style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      const Text('10%'),
                      Expanded(
                        child: Slider(
                          value: _quality,
                          min: 10,
                          max: 100,
                          divisions: 90,
                          label: '${_quality.round()}%',
                          activeColor: AppColors.primaryPink,
                          onChanged: (double value) {
                            setState(() {
                              _quality = value;
                            });
                          },
                        ),
                      ),
                      const Text('100%'),
                    ],
                  ),
                  Text('Selected: ${_quality.round()}% (Lower is smaller size)', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 16),
                  const Text('Target Size (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _targetSizeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Target Size in KB (e.g. 500)',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (widget.toolConfig['action'] == 'documentScan') ...[
                  const SizedBox(height: 16),
                  const Text('Scan Filter:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _scanType,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'original', child: Text('Original')),
                          DropdownMenuItem(value: 'magic_color', child: Text('Magic Color')),
                          DropdownMenuItem(value: 'black_white', child: Text('Black & White')),
                          DropdownMenuItem(value: 'grayscale', child: Text('Grayscale')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _scanType = val);
                        },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],

              ElevatedButton(
                onPressed: _isProcessing ? null : _processFiles,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.all(16),
                ),
                child: Text(_isProcessing ? 'Processing...' : 'Start $title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              
              if (_resultPath != null) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => OpenFilex.open(_resultPath!),
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
                        // ignore: deprecated_member_use
                        onPressed: () => Share.shareXFiles([XFile(_resultPath!)], text: widget.toolConfig['title']),
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
                    onPressed: () async {
                      final ext = _resultPath!.split('.').last.toLowerCase();
                      if (['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(ext)) {
                        final hasAccess = await Gal.hasAccess();
                        if (!hasAccess) await Gal.requestAccess();
                        await Gal.putImage(_resultPath!);
                        if (context.mounted) SnackbarUtils.showNeoSnackBar(context, message: 'Image saved to Gallery!');
                      } else {
                        try {
                          if (Platform.isAndroid) {
                            final dir = Directory('/storage/emulated/0/Download');
                            if (await dir.exists()) {
                              final fileName = _resultPath!.split('/').last;
                              final savePath = '${dir.path}/$fileName';
                              await File(_resultPath!).copy(savePath);
                              if (context.mounted) SnackbarUtils.showNeoSnackBar(context, message: 'Saved to Downloads folder!');
                              return;
                            }
                          }
                          
                          // Fallback to FilePicker
                          final String? outputFile = await FilePicker.platform.saveFile(
                            dialogTitle: 'Save to Local',
                            fileName: _resultPath!.split('/').last,
                          );

                          if (outputFile != null) {
                            await File(_resultPath!).copy(outputFile);
                            if (context.mounted) SnackbarUtils.showNeoSnackBar(context, message: 'Saved successfully!');
                          }
                        } catch (e) {
                          if (context.mounted) SnackbarUtils.showNeoSnackBar(context, message: 'Failed to save: $e');
                        }
                      }
                    },
                    icon: const Icon(Icons.download_rounded, color: Colors.white),
                    label: const Text('SAVE TO LOCAL', style: AppTextStyles.buttonText),
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
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(File file) {
    Widget img = Image.file(file, height: 250, fit: BoxFit.contain);
    
    if (_scanType == 'grayscale' || _scanType == 'black_white') {
      img = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]),
        child: img,
      );
    }
    
    if (_scanType == 'black_white') {
      // High contrast for B&W
      img = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          3.0, 0,   0,   0, -255.0,
          0,   3.0, 0,   0, -255.0,
          0,   0,   3.0, 0, -255.0,
          0,   0,   0,   1, 0,
        ]),
        child: img,
      );
    }

    if (_scanType == 'magic_color') {
      // Boost contrast and color
      img = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          1.5, 0,   0,   0, -20.0,
          0,   1.5, 0,   0, -20.0,
          0,   0,   1.5, 0, -20.0,
          0,   0,   0,   1, 0,
        ]),
        child: img,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: img,
    );
  }
}

class _SignatureDialog extends StatefulWidget {
  const _SignatureDialog();

  @override
  State<_SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<_SignatureDialog> {
  late SignatureController _signatureController;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 5,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Draw Signature'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: Signature(
          controller: _signatureController,
          backgroundColor: Colors.grey.shade200,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _signatureController.clear();
          },
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_signatureController.isNotEmpty) {
              final bytes = await _signatureController.toPngBytes();
              if (bytes != null) {
                final tempDir = await getTemporaryDirectory();
                final file = File('${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png');
                await file.writeAsBytes(bytes);
                if (context.mounted) Navigator.pop(context, file);
                return;
              }
            }
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Use in PDF'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_signatureController.isNotEmpty) {
              final bytes = await _signatureController.toPngBytes();
              if (bytes != null) {
                final tempDir = await getTemporaryDirectory();
                final file = File('${tempDir.path}/my_signature_${DateTime.now().millisecondsSinceEpoch}.png');
                await file.writeAsBytes(bytes);
                
                // Pop the dialog FIRST so the signature controller is safely disposed
                if (context.mounted) {
                  Navigator.pop(context);
                }
                
                // Then open the share sheet over the main screen
                // ignore: deprecated_member_use
                await Share.shareXFiles([XFile(file.path)], text: 'My Digital Signature');
              }
            }
          },
          child: const Text('Export/Share'),
        ),
      ],
    );
  }
}
