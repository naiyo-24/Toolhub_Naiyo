import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'dart:io';
import '../../providers/daily_utility_providers.dart';

class BarcodeGeneratorScreen extends ConsumerStatefulWidget {
  const BarcodeGeneratorScreen({super.key});

  @override
  ConsumerState<BarcodeGeneratorScreen> createState() => _BarcodeGeneratorScreenState();
}

class _BarcodeGeneratorScreenState extends ConsumerState<BarcodeGeneratorScreen> {
  final _inputController = TextEditingController();
  String _barcodeData = '';
  Uint8List? _barcodeImage;
  bool _isLoading = false;
  bool _isSaving = false;

  Future<void> _generateBarcode() async {
    if (_barcodeData.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final bytes = await ref.read(dailyUtilityServiceProvider).generateBarcode(
        data: _barcodeData,
        barcodeType: 'code128',
      );

      setState(() {
        _barcodeImage = bytes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error appropriately
    }
  }

  Future<void> _downloadBarcode() async {
    if (_barcodeImage == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/barcode.png');
      await file.writeAsBytes(_barcodeImage!);

      final xFile = XFile(file.path);
      await SharePlus.instance.share(ShareParams(files: [xFile], text: 'My Barcode'));
    } catch (e) {
      // Handle error
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
        backgroundColor: AppColors.primaryYellow,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Barcode Generator',
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
          children: [
            NeoCard(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Enter Product ID / Code', style: AppTextStyles.sectionTitle.copyWith(fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      hintText: 'e.g., 123456789012',
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
                        borderSide: const BorderSide(color: AppColors.primaryYellow, width: 2),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _barcodeData = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _generateBarcode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryYellow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : Text('Generate Barcode', style: AppTextStyles.buttonText.copyWith(color: Colors.black)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_barcodeImage != null)
              NeoCard(
                backgroundColor: AppColors.primaryYellow,
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
                        _barcodeImage!,
                        width: double.infinity,
                        height: 100,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Text('Invalid data format or error', style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _downloadBarcode,
                        icon: _isSaving 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Icon(Icons.share_rounded, color: Colors.black),
                        label: Text(
                          _isSaving ? 'Processing...' : 'Share Barcode',
                          style: AppTextStyles.buttonText.copyWith(color: Colors.black),
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
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
