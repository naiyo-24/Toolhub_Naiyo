import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/widgets/neo_text_field.dart';
import 'package:tool_hub/core/api/api_config.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';
import 'package:tool_hub/features/tools/business_toolkit/data/business_service.dart';
import 'package:tool_hub/features/tools/business_toolkit/presentation/screens/stock_movement_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'dart:async';

final businessServiceProvider = Provider((ref) => BusinessService());

class InventoryListScreen extends ConsumerStatefulWidget {
  const InventoryListScreen({super.key});

  @override
  ConsumerState<InventoryListScreen> createState() =>
      _InventoryListScreenState();
}

class _InventoryListScreenState extends ConsumerState<InventoryListScreen> {
  bool _isFetching = true;
  bool _isDownloading = false;
  List<dynamic> _remoteItems = [];
  Timer? _debounce;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchInventory();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {});
    });
  }

  Future<void> _fetchInventory() async {
    setState(() => _isFetching = true);
    try {
      final items = await ref.read(businessServiceProvider).getInventory();
      if (mounted) {
        setState(() {
          _remoteItems = items;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showNeoSnackBar(context,
            message: 'Failed to fetch inventory: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isFetching = false);
      }
    }
  }

  Future<void> _printBarcodes() async {
    setState(() => _isDownloading = true);
    try {
      final pdfPath =
          await ref.read(businessServiceProvider).generateInventoryBarcodes();
      if (mounted) {
        SnackbarUtils.showNeoSnackBar(context,
            message: 'Barcodes PDF generated!');
        final uri = Uri.parse(pdfPath);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Could not launch PDF URL');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showNeoSnackBar(context, message: 'Failed: $e');
      }
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _downloadReport() async {
    setState(() => _isDownloading = true);
    try {
      final pdfPath =
          await ref.read(businessServiceProvider).generateInventoryReport();
      if (mounted) {
        SnackbarUtils.showNeoSnackBar(context,
            message: 'Inventory Report generated!');
        final uri = Uri.parse(pdfPath);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Could not launch PDF URL');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showNeoSnackBar(context, message: 'Failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  void _showProductDetailsBottomsheet(Map<String, dynamic> item) {
    final sku = item['barcode'] ?? item['sku'] ?? 'ITEM-${item['product_id'] ?? item['id']}';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (builderCtx) {
        bool isDownloading = false;
        return StatefulBuilder(builder: (builderCtx, setStateSheet) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: Colors.black, width: 2),
                left: BorderSide(color: Colors.black, width: 2),
                right: BorderSide(color: Colors.black, width: 2),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(builderCtx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Title & Image
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item['image_url'] != null) ...[
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black, width: 2),
                              image: DecorationImage(
                                image: NetworkImage(
                                  item['image_url'].toString().startsWith('http') && 
                                  (item['image_url'].toString().contains('192.168') || item['image_url'].toString().contains('10.0.2.2') || item['image_url'].toString().contains('127.0.0.1'))
                                      ? '${ApiConfig.baseUrl}${Uri.parse(item['image_url']).path}'
                                      : item['image_url'].toString().startsWith('http') 
                                          ? item['image_url'] 
                                          : '${ApiConfig.baseUrl}${item['image_url']}'
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name'] ?? 'Unknown',
                                  style: AppTextStyles.heroTitle.copyWith(fontSize: 22)),
                              if (item['brand'] != null)
                                Text('Brand: ${item['brand']}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                              if (item['category'] != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(item['category'],
                                      style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              if (item['product_type'] == 'Raw Material')
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryYellow.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Raw Material',
                                      style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Details Grid
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildDetailChip('Stock', '${item['current_stock'] ?? 0}'),
                        _buildDetailChip('Price', 'Rs. ${(item['selling_price'] != null && item['selling_price'] > 0) ? item['selling_price'] : (item['mrp'] ?? 0)}'),
                        _buildDetailChip('MRP', 'Rs. ${item['mrp'] ?? 0}'),
                        if (item['gst_rate'] != null && item['gst_rate'] > 0)
                          _buildDetailChip('GST', '${item['gst_rate']}%'),
                        if (item['hsn_code'] != null)
                          _buildDetailChip('HSN', item['hsn_code']),
                      ],
                    ),
                    
                    if (item['description'] != null) ...[
                      const SizedBox(height: 24),
                      Text('Description', style: AppTextStyles.toolCardTitle.copyWith(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(item['description'], style: const TextStyle(color: Colors.black87)),
                    ],

                    const SizedBox(height: 32),
                    const Divider(color: Colors.black26, thickness: 1),
                    const SizedBox(height: 24),

                    // Barcode Section
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.black, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: BarcodeWidget(
                              barcode: Barcode.code128(),
                              data: sku,
                              width: 200,
                              height: 80,
                              errorBuilder: (ctx, error) => Center(child: Text(error)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('SKU: $sku', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    NeoCard(
                      onTap: () {
                        Navigator.pop(builderCtx);
                        _showRefillDialog(item);
                      },
                      backgroundColor: AppColors.primaryYellow,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: const Center(
                        child: Text('Refill / Add Stock',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    NeoCard(
                      onTap: isDownloading
                          ? null
                          : () async {
                              setStateSheet(() => isDownloading = true);
                              try {
                                final pdfPath = await ref
                                    .read(businessServiceProvider)
                                    .generateSingleBarcode(item['id'].toString());
                                if (builderCtx.mounted) {
                                  Navigator.pop(builderCtx);
                                  SnackbarUtils.showNeoSnackBar(builderCtx, message: 'PDF generated!');
                                  final uri = Uri.parse(pdfPath);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                }
                              } catch (e) {
                                if (builderCtx.mounted) {
                                  setStateSheet(() => isDownloading = false);
                                  SnackbarUtils.showNeoSnackBar(builderCtx, message: 'Failed: $e');
                                }
                              }
                            },
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: isDownloading
                            ? const SizedBox(
                                width: 24, height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Download Barcode PDF',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),

                    const SizedBox(height: 16),
                    NeoCard(
                      onTap: () {
                        Navigator.pop(builderCtx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StockMovementScreen(
                              productId: item['id'],
                              productName: item['name'] ?? 'Product',
                            ),
                          ),
                        );
                      },
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: const Center(
                        child: Text('View Stock History',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  void _showRefillDialog(Map<String, dynamic> item) {
    final TextEditingController qtyController = TextEditingController();
    bool isRefilling = false;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: AppColors.backgroundLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.black, width: 3)),
          title: Text('Refill Stock for ${item['name']}', style: AppTextStyles.toolCardTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Stock: ${item['current_stock'] ?? 0}'),
              const SizedBox(height: 16),
              NeoTextField(
                controller: qtyController,
                label: 'Quantity to Add',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
              onPressed: isRefilling ? null : () async {
                final qty = int.tryParse(qtyController.text);
                if (qty == null || qty <= 0) {
                  SnackbarUtils.showNeoSnackBar(ctx, message: 'Enter a valid quantity');
                  return;
                }
                
                setStateDialog(() => isRefilling = true);
                
                try {
                  final payload = {
                    'barcode': item['barcode'],
                    'available_stock': qty,
                  };
                  await ref.read(businessServiceProvider).addInventory(payload);
                  
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    // ignore: use_build_context_synchronously
                    SnackbarUtils.showNeoSnackBar(context, message: 'Stock refilled successfully!');
                    _fetchInventory();
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    setStateDialog(() => isRefilling = false);
                    SnackbarUtils.showNeoSnackBar(ctx, message: 'Failed to refill: $e');
                  }
                }
              },
              child: isRefilling 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Refill', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      )
    );
  }

  Widget _buildDetailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();
    final filteredItems = _remoteItems.where((item) {
      final name = (item['name'] ?? '').toLowerCase();
      final sku = (item['barcode'] ?? item['sku'] ?? '').toLowerCase();
      return name.contains(query) || sku.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('All Products',
            style: AppTextStyles.heroTitle
                .copyWith(fontSize: 20, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Colors.black, width: 2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
            onPressed: _isDownloading ? null : _downloadReport,
            tooltip: 'Download Report',
          ),
          IconButton(
            icon: const Icon(Icons.print_rounded, color: Colors.white),
            onPressed: _isDownloading ? null : _printBarcodes,
            tooltip: 'Print Barcodes',
          ),
          IconButton(
            icon:
                const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
            onPressed: () {
              context.push('/inventory-scanner', extra: _remoteItems);
            },
            tooltip: 'Scan Barcode',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by Product Name or SKU...',
                    prefixIcon:
                        Icon(Icons.search_rounded, color: Colors.black54),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isFetching
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryBlue))
                  : filteredItems.isEmpty
                      ? Center(
                          child: Text('No products found.',
                              style: AppTextStyles.bodyText
                                  .copyWith(fontStyle: FontStyle.italic)))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          itemCount: filteredItems.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final bool lowStock =
                                (item['current_stock'] ?? 0) <=
                                    (item['reminder_stock'] ?? 0);
                            return NeoCard(
                              onTap: () => _showProductDetailsBottomsheet(item),
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryYellow
                                          .withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.black, width: 1.5),
                                    ),
                                    child: item['image_url'] != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: Image.network(item['image_url'], fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.inventory_2_rounded, color: Colors.black87)),
                                          )
                                        : const Icon(Icons.inventory_2_rounded, color: Colors.black87),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(item['name'],
                                            style: AppTextStyles.toolCardTitle
                                                .copyWith(fontSize: 16)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                                'SKU: ${item['barcode'] ?? 'N/A'}',
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black54,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const Spacer(),
                                            Text(
                                                'Price: ₹${(item['selling_price'] != null && item['selling_price'] > 0) ? item['selling_price'] : (item['mrp'] ?? 0)}',
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors
                                                        .primaryGreen)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        if (item['product_type'] == 'Raw Material')
                                          Container(
                                            margin: const EdgeInsets.only(bottom: 4),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryYellow.withValues(alpha: 0.3),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text('Raw Material',
                                                style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 10)),
                                          ),
                                        Row(
                                          children: [
                                            Icon(Icons.inventory_rounded,
                                                size: 14,
                                                color: lowStock
                                                    ? AppColors.primaryRed
                                                    : Colors.black54),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Stock: ${item['current_stock'] ?? 0}',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: lowStock
                                                      ? AppColors.primaryRed
                                                      : Colors.black87,
                                                  fontWeight: lowStock
                                                      ? FontWeight.bold
                                                      : FontWeight.normal),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.qr_code_2_rounded,
                                      color: Colors.black87),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Go to Add Item screen, wait for return, then refresh
          await context.push('/inventory-manager');
          _fetchInventory();
        },
        backgroundColor: AppColors.primaryBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Product',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
