import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tool_hub/core/utils/permission_disclosure_utils.dart';
import '../../providers/daily_utility_providers.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  final String scannerType; // 'QR' or 'Barcode'
  const ScannerScreen({super.key, required this.scannerType});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  String? _scannedData;
  MobileScannerController? cameraController;
  bool _isUploading = false;
  bool _hasPermission = false;
  bool _isCheckingPermission = true;
  
  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await PermissionDisclosureUtils.requestWithDisclosure(
      context,
      permission: Permission.camera,
      title: 'Camera Permission',
      description: 'We need access to your camera so you can scan ${widget.scannerType} codes.',
      icon: Icons.camera_alt,
      color: widget.scannerType == 'QR' ? AppColors.primaryPink : AppColors.primaryGreen,
    );
    
    if (mounted) {
      setState(() {
        _hasPermission = granted;
        _isCheckingPermission = false;
        if (granted) {
          cameraController = MobileScannerController();
        }
      });
      if (!granted) {
        SnackbarUtils.showNeoSnackBar(context, message: 'Camera permission denied.', isError: true);
      }
    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  Future<void> _uploadAndScan() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _isUploading = true;
      });

      try {
        cameraController?.stop();
        final path = result.files.single.path!;
        Map<String, dynamic> response;
        if (widget.scannerType == 'QR') {
          response = await ref.read(dailyUtilityServiceProvider).scanQr(path);
        } else {
          response = await ref.read(dailyUtilityServiceProvider).scanBarcode(path);
        }

        if (response.containsKey('data')) {
          setState(() {
            _scannedData = response['data'] as String;
          });
        } else {
          // ignore: use_build_context_synchronously
          SnackbarUtils.showNeoSnackBar(context, message: 'Could not find ${widget.scannerType} in image.');
        }
      } catch (e) {
        // ignore: use_build_context_synchronously
        SnackbarUtils.showNeoSnackBar(context, message: 'Error analyzing image with server.');
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _handleScanAction(String data) async {
    String launchString = data.trim();

    if (_isEmail(data) && !data.startsWith('mailto:')) {
      launchString = 'mailto:$data';
    } else if (_isPhone(data) && !data.startsWith('tel:')) {
      launchString = 'tel:$data';
    } else if (_isUrl(data) && !data.startsWith('http')) {
      launchString = 'https://$data';
    }

    final uri = Uri.tryParse(launchString);
    if (uri != null && (_isUrl(data) || _isEmail(data) || _isPhone(data))) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    }
    // Fallback: copy to clipboard
    await Clipboard.setData(ClipboardData(text: data));
    // ignore: use_build_context_synchronously
    SnackbarUtils.showNeoSnackBar(context, message: 'Copied to clipboard');
  }

  bool _isEmail(String data) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(data.trim()) || data.startsWith('mailto:');
  }

  bool _isPhone(String data) {
    // 7 to 15 digits, optionally starting with +
    final phoneRegex = RegExp(r'^\+?[\d\s-]{7,15}$');
    return phoneRegex.hasMatch(data.trim()) || data.startsWith('tel:');
  }

  bool _isUrl(String data) {
    final str = data.trim().toLowerCase();
    if (str.startsWith('http://') || str.startsWith('https://')) return true;
    // Basic check for things like www.google.com or example.com
    final urlRegex = RegExp(r'^([\w\d-]+\.)+[\w\d-]+(\/.*)?$');
    return urlRegex.hasMatch(str) && !str.contains(' ');
  }

  String _getActionText(String data) {
    if (_isUrl(data)) return 'Open Link';
    if (_isEmail(data)) return 'Send Email';
    if (_isPhone(data)) return 'Call Number';
    return 'Copy text';
  }
  
  IconData _getActionIcon(String data) {
    if (_isUrl(data)) return Icons.open_in_browser_rounded;
    if (_isEmail(data)) return Icons.email_rounded;
    if (_isPhone(data)) return Icons.phone_rounded;
    return Icons.copy_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: widget.scannerType == 'QR' ? AppColors.primaryPink : AppColors.primaryGreen,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '${widget.scannerType} Scanner',
          style: AppTextStyles.heroTitle.copyWith(fontSize: 20, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white),
            onPressed: () => cameraController?.switchCamera(),
          ),
        ],
      ),
      body: _isCheckingPermission 
        ? const Center(child: CircularProgressIndicator())
        : !_hasPermission 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Camera permission is required to scan.', style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _checkPermission,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                if (cameraController != null) MobileScanner(
                  controller: cameraController!,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && _scannedData == null) {
                      final barcode = barcodes.first;
                      setState(() {
                        _scannedData = barcode.rawValue;
                      });
                      cameraController?.stop(); // Stop scanning once found
                    }
                  },
                ),
                // Scanner overlay box
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: widget.scannerType == 'QR' ? AppColors.primaryPink : AppColors.primaryGreen, width: 4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                // Instructions overlay
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: widget.scannerType == 'QR' ? AppColors.primaryPink : AppColors.primaryGreen, width: 2),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.black),
                            const SizedBox(width: 8),
                            Text('How to scan', style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '1. Point your camera at any ${widget.scannerType} code.\n'
                          '2. Ensure it is well-lit and centered in the frame.\n'
                          '3. Or, tap "Upload Image" below to scan from your gallery.', style: AppTextStyles.bodyText.copyWith(fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_scannedData == null) ...[
                    Text(
                      'Align ${widget.scannerType} within the frame to scan',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isUploading ? null : _uploadAndScan,
                      icon: _isUploading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const Icon(Icons.upload_file_rounded, color: Colors.black),
                      label: Text('Upload Image to Scan', style: AppTextStyles.buttonText.copyWith(color: Colors.black)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                    ),
                  ] else ...[
                    const Text('Scan Result:', style: TextStyle(fontSize: 14, color: Colors.black54)),
                    const SizedBox(height: 8),
                    SelectableText(
                      _scannedData!,
                      style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _handleScanAction(_scannedData!),
                          icon: Icon(_getActionIcon(_scannedData!), color: Colors.black),
                          label: Text(_getActionText(_scannedData!), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryYellow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.black, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _scannedData = null;
                            });
                            cameraController?.start();
                          },
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                          label: const Text('Scan Again', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.scannerType == 'QR' ? AppColors.primaryPink : AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.black, width: 2),
                            ),
                          ),
                        )
                      ],
                    )
                  ]
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
