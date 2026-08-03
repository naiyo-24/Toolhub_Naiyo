import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/widgets/neo_text_field.dart';
import '../providers/business_provider.dart';
import 'inventory_scanner_screen.dart';

class PurchaseInvoiceScreen extends ConsumerStatefulWidget {
  const PurchaseInvoiceScreen({super.key});

  @override
  ConsumerState<PurchaseInvoiceScreen> createState() => _PurchaseInvoiceScreenState();
}

class _PurchaseInvoiceScreenState extends ConsumerState<PurchaseInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supplierName = TextEditingController();
  final _invoiceNumber = TextEditingController();
  final _invoiceDate = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
  
  final List<Map<String, TextEditingController>> _items = [];
  File? _billImage;
  bool _isLoading = false;

  Future<void> _pickBillImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _billImage = File(pickedFile.path);
      });
    }
  }

  void _addItem({Map<String, dynamic>? product}) {
    setState(() {
      _items.add({
        'desc': TextEditingController(text: product != null ? product['name'] : ''),
        'sku': TextEditingController(text: product != null ? (product['barcode'] ?? product['sku']?.toString()) : ''),
        'qty': TextEditingController(text: '1'),
        'unit_price': TextEditingController(text: product != null ? (product['purchase_price'] ?? product['mrp'] ?? 0.0).toString() : ''),
      });
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _scanBarcodeToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InventoryScannerScreen(
          inventory: [],
          isPicker: true,
          isGlobalLookup: true,
        ),
      ),
    );
    
    if (result != null && result is Map<String, dynamic>) {
      _addItem(product: result);
    }
  }

  double get _totalAmount {
    double total = 0;
    for (var item in _items) {
      final qty = int.tryParse(item['qty']!.text) ?? 0;
      final price = double.tryParse(item['unit_price']!.text) ?? 0.0;
      total += qty * price;
    }
    return total;
  }

  Future<void> _submitPurchase() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one item to purchase')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final service = ref.read(businessServiceProvider);
      
      final itemsList = _items.map((i) => {
        'description': i['desc']!.text,
        'sku': i['sku']!.text,
        'quantity': int.tryParse(i['qty']!.text) ?? 1,
        'unit_price': double.tryParse(i['unit_price']!.text) ?? 0.0,
        'unit': 'Piece', // default for now
        'gst_rate': 0.0, // not used here but required by schema
      }).toList();

      final String finalInvoiceNumber = _invoiceNumber.text.trim().isEmpty 
          ? 'RAW-INV-${DateTime.now().millisecondsSinceEpoch}' 
          : _invoiceNumber.text;

      String? billImageUrl;
      if (_billImage != null) {
        billImageUrl = await service.uploadImage(_billImage!);
      }

      final payload = {
        'supplier_name': _supplierName.text,
        'invoice_number': finalInvoiceNumber,
        'invoice_date': _invoiceDate.text,
        'total_amount': _totalAmount,
        'items': itemsList,
        if (billImageUrl != null) 'pdf_url': billImageUrl,
      };

      await service.recordPurchaseInvoice(payload);
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase recorded! Inventory updated.')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Purchase Invoice', style: AppTextStyles.screenHeading),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NeoCard(
                backgroundColor: AppColors.primaryYellow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Supplier Details', style: AppTextStyles.toolCardTitle),
                    const SizedBox(height: 16),
                    NeoTextField(
                      controller: _supplierName,
                      label: 'Supplier / Vendor Name',
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: NeoTextField(controller: _invoiceNumber, label: 'Invoice No. (Optional)')),
                          const SizedBox(width: 16),
                          Expanded(child: NeoTextField(controller: _invoiceDate, label: 'Date (YYYY-MM-DD)')),
                        ],
                      ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _pickBillImage,
                      icon: Icon(_billImage == null ? Icons.upload_file : Icons.check_circle, color: _billImage == null ? Colors.black : Colors.green),
                      label: Text(_billImage == null ? 'Upload Bill Image (Optional)' : 'Bill Image Selected', style: const TextStyle(color: Colors.black)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Items Purchased', style: AppTextStyles.sectionTitle),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _scanBarcodeToAdd,
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Add Item', style: TextStyle(color: Colors.white)),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      )
                    ],
                  )
                ],
              ),
              const SizedBox(height: 16),
              ..._items.asMap().entries.map((e) => _buildItemCard(e.key, e.value)),
              
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Value:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('₹${_totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryPurple)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitPurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.black, width: 2)),
                  ),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Record Purchase & Update Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(int index, Map<String, TextEditingController> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeoCard(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: NeoTextField(
                    controller: item['desc']!,
                    label: 'Product Name',
                    validator: (v) => v!.isEmpty ? 'Req' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NeoTextField(
                    controller: item['sku']!,
                    label: 'Barcode',
                  ),
                ),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _removeItem(index))
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: NeoTextField(
                    controller: item['qty']!,
                    label: 'Qty',
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Req' : null,
                    onChanged: (_) => setState((){}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NeoTextField(
                    controller: item['unit_price']!,
                    label: 'Purchase Price / Unit',
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Req' : null,
                    onChanged: (_) => setState((){}),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
