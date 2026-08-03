import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import '../providers/internet_tools_providers.dart';

class WifiQrScreen extends ConsumerStatefulWidget {
  const WifiQrScreen({super.key});

  @override
  ConsumerState<WifiQrScreen> createState() => _WifiQrScreenState();
}

class _WifiQrScreenState extends ConsumerState<WifiQrScreen> {
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  String _encryption = 'WPA';
  Uint8List? _qrBytes;
  bool _isLoading = false;
  String? _error;

  final List<String> _encryptionTypes = ['WPA', 'WEP', 'nopass'];

  Future<void> _generateQr() async {
    final ssid = _ssidController.text.trim();
    final password = _passwordController.text.trim();
    if (ssid.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _qrBytes = null;
    });

    try {
      final service = ref.read(internetToolsServiceProvider);
      final bytes = await service.generateWifiQr(ssid, password, _encryption);
      setState(() {
        _qrBytes = bytes;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to generate QR code.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _shareQr() async {
    if (_qrBytes == null) return;
    try {
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/wifi_qr.png').create();
      await file.writeAsBytes(_qrBytes!);
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)], text: 'Scan to connect to WiFi!');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share/download QR code.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryYellow,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'WiFi QR Generator',
          style: AppTextStyles.heroTitle.copyWith(fontSize: 20, color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
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
                    "1. Enter your WiFi Network Name (SSID) and Password.\n2. Choose the Security Type (WPA/WEP/None).\n3. Tap 'Generate' to create a QR code.",
                    style: AppTextStyles.bodyText.copyWith(fontSize: 14),
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
                  Text('WiFi Details', style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ssidController,
                    decoration: InputDecoration(
                      labelText: 'Network Name (SSID)',
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
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _encryption,
                    decoration: InputDecoration(
                      labelText: 'Encryption Type',
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
                    ),
                    items: _encryptionTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type == 'nopass' ? 'None' : type));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _encryption = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password (Optional for None)',
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
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryYellow,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      onPressed: _isLoading ? null : _generateQr,
                      child: _isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Text('Generate QR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 20),
              Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
            if (_qrBytes != null) ...[
              const SizedBox(height: 20),
              Center(
                child: NeoCard(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Image.memory(_qrBytes!, width: 200, height: 200),
                      const SizedBox(height: 12),
                      Text('Scan to connect', style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryYellow,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Colors.black, width: 2),
                          ),
                        ),
                        onPressed: _shareQr,
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Download / Share', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
