import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tool_hub/core/utils/permission_disclosure_utils.dart';

import 'package:tool_hub/features/tools/business_toolkit/data/business_service.dart';

class InventoryScannerScreen extends StatefulWidget {
  final List<dynamic> inventory;
  final bool isPicker;
  final bool isGlobalLookup;
  const InventoryScannerScreen(
      {super.key,
      required this.inventory,
      this.isPicker = false,
      this.isGlobalLookup = false});

  @override
  State<InventoryScannerScreen> createState() => _InventoryScannerScreenState();
}

class _InventoryScannerScreenState extends State<InventoryScannerScreen> {
  MobileScannerController? _controller;
  bool _isProcessing = false;
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
      description: 'We need access to your camera so you can scan inventory barcodes.',
      icon: Icons.camera_alt,
      color: AppColors.primaryYellow,
    );

    if (mounted) {
      setState(() {
        _hasPermission = granted;
        _isCheckingPermission = false;
        if (granted) {
          _controller = MobileScannerController(
            detectionSpeed: DetectionSpeed.normal,
            formats: [BarcodeFormat.all],
          );
        }
      });
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission denied.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final code = barcodes.first.rawValue!;

      setState(() {
        _isProcessing = true;
      });

      _controller?.stop();

      Map<String, dynamic>? product;
      if (widget.isGlobalLookup) {
        try {
          product = await BusinessService().lookupProduct(code);
        } catch (e) {
          product = null;
        }
      } else {
        product = _findProduct(code);
      }

      if (widget.isPicker) {
        if (product != null) {
          if (mounted) context.pop(product);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Product not found!')),
            );
          }
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
            _controller?.start();
          }
        }
      } else {
        _showProductSheet(product, code).then((_) {
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
            _controller?.start();
          }
        });
      }
    }
  }

  Map<String, dynamic>? _findProduct(String code) {
    for (var item in widget.inventory) {
      final sku = item['sku']?.toString();
      final id = item['item_id']?.toString();
      final defaultBarcode = 'ITEM-$id';

      if (sku == code || defaultBarcode == code || id == code) {
        return item as Map<String, dynamic>;
      }
    }
    return null;
  }

  Future<void> _showProductSheet(
      Map<String, dynamic>? product, String scannedCode) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          border: Border.all(color: Colors.black, width: 3),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(0, -4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 24),
            if (product != null) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.primaryGreen, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text('Product Found!',
                          style: AppTextStyles.heroTitle.copyWith(
                              fontSize: 22, color: AppColors.primaryGreen))),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Name', product['name']),
              _buildDetailRow(
                  'SKU', product['barcode'] ?? product['sku'] ?? 'N/A'),
              _buildDetailRow('Price',
                  '₹${product['mrp'] ?? product['selling_price'] ?? product['unit_price'] ?? 0}'),
              _buildDetailRow('Stock',
                  '${product['available_stock'] ?? product['current_stock'] ?? 0} units'),
            ] else ...[
              Row(
                children: [
                  const Icon(Icons.error,
                      color: AppColors.primaryRed, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text('Product Not Found',
                          style: AppTextStyles.heroTitle.copyWith(
                              fontSize: 22, color: AppColors.primaryRed))),
                ],
              ),
              const SizedBox(height: 16),
              Text('Scanned Code: $scannedCode', style: AppTextStyles.bodyText),
              const SizedBox(height: 8),
              Text(
                  'This barcode is not associated with any product in your inventory database.',
                  style:
                      AppTextStyles.bodyText.copyWith(color: Colors.black54)),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => context.pop(),
                child: Text('CONTINUE SCANNING',
                    style:
                        AppTextStyles.buttonText.copyWith(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.bodyText.copyWith(
                  color: Colors.black54, fontWeight: FontWeight.bold)),
          Text(value,
              style:
                  AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Scan Barcode',
            style: AppTextStyles.heroTitle
                .copyWith(color: Colors.white, fontSize: 20)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (_isCheckingPermission) 
             const Center(child: CircularProgressIndicator())
          else if (!_hasPermission)
             Center(
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
          else ...[
            if (_controller != null) MobileScanner(
              controller: _controller!,
              onDetect: _onDetect,
            ),
            // Scanner Overlay
          Center(
            child: Container(
              width: 300,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryYellow, width: 4),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'Align barcode within the frame',
                  style: AppTextStyles.bodyText.copyWith(color: Colors.white),
                ),
              ),
            ),
          )
          ]
        ],
      ),
    );
  }
}
