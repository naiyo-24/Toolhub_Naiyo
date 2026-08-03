import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/widgets/neo_text_field.dart';
import '../providers/business_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'inventory_scanner_screen.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PosBillingScreen extends ConsumerStatefulWidget {
  const PosBillingScreen({super.key});

  @override
  ConsumerState<PosBillingScreen> createState() => _PosBillingScreenState();
}

class _PosBillingScreenState extends ConsumerState<PosBillingScreen> {
  final _customerName = TextEditingController();
  final _customerPhone = TextEditingController();
  final List<Map<String, dynamic>> _cart = [];
  bool _isLoading = false;
  String _paymentMode = 'Cash';
  String _pricingMode = 'EXCLUSIVE';
  String? _invoiceDiscountType;
  double _invoiceDiscountValue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPricingMode();
  }

  Future<void> _loadPricingMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      String pm = prefs.getString('pricing_mode') ?? 'EXCLUSIVE';
      if (pm == 'INCLUSIVE') pm = 'EXCLUSIVE';
      _pricingMode = pm;
    });
  }

  void _scanItem() async {
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
      setState(() {
        final existingIndex = _cart.indexWhere((item) =>
            item['sku'] == (result['barcode'] ?? result['sku']?.toString()));
        if (existingIndex >= 0) {
          _cart[existingIndex]['qty']++;
        } else {
          _cart.add({
            'desc': result['name'],
            'sku': result['barcode'] ?? result['sku']?.toString(),
            'hsn': result['hsn_code']?.toString() ?? '',
            'qty': 1,
            'price': (result['selling_price'] ?? result['unit_price'] ?? result['mrp'] ?? 0.0).toDouble(),
            'gst': (result['gst_rate'] ?? 0.0).toDouble(),
            'discount_type': null,
            'discount_value': 0.0,
          });
        }
      });
      if (!mounted) return;
      final price = (result['selling_price'] ?? result['unit_price'] ?? result['mrp'] ?? 0.0).toStringAsFixed(2);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${result['name']} (₹$price) to cart!')),
      );
    }
  }

  void _updateQty(int index, int delta) {
    setState(() {
      _cart[index]['qty'] += delta;
      if (_cart[index]['qty'] <= 0) {
        _cart.removeAt(index);
      }
    });
  }

  double get _rawSubtotal {
    double total = 0;
    for (var item in _cart) {
      double qty = item['qty'].toDouble();
      double price = item['price'].toDouble();
      double discount = 0;
      if (item['discount_type'] == 'PERCENTAGE') {
        discount = (qty * price) * (item['discount_value'] / 100);
      } else if (item['discount_type'] == 'AMOUNT') {
        discount = item['discount_value'];
      }
      total += (qty * price) - discount;
    }
    return total;
  }

  double get _calculatedInvoiceDiscount {
    if (_invoiceDiscountType == 'PERCENTAGE') {
      return _rawSubtotal * (_invoiceDiscountValue / 100);
    } else if (_invoiceDiscountType == 'AMOUNT') {
      return _invoiceDiscountValue;
    }
    return 0.0;
  }

  double get _subtotalAmount {
    return _rawSubtotal; // Subtotal before invoice discount and tax
  }

  Map<double, double> get _gstBreakup {
    if (_pricingMode.toUpperCase() == 'WITHOUT_GST') return {};
    Map<double, double> breakup = {};
    double rawSub = _rawSubtotal;
    double invDisc = _calculatedInvoiceDiscount;
    
    for (var item in _cart) {
      double gstRate = (item['gst'] as num).toDouble();
      if (gstRate == 0) continue;
      
      double qty = item['qty'].toDouble();
      double price = item['price'].toDouble();
      double discount = 0;
      if (item['discount_type'] == 'PERCENTAGE') {
        discount = (qty * price) * (item['discount_value'] / 100);
      } else if (item['discount_type'] == 'AMOUNT') {
        discount = item['discount_value'];
      }
      double base = (qty * price) - discount;
      
      double ratio = rawSub > 0 ? (base / rawSub) : 0;
      double itemInvDisc = invDisc * ratio;
      double finalTaxable = base - itemInvDisc;
      
      double tax = finalTaxable * (gstRate / 100);
      breakup[gstRate] = (breakup[gstRate] ?? 0.0) + tax;
    }
    return breakup;
  }

  double get _totalTax {
    return _gstBreakup.values.fold(0.0, (sum, val) => sum + val);
  }

  double get _totalAmount {
    return _subtotalAmount - _calculatedInvoiceDiscount + _totalTax;
  }

  Future<void> _checkout(String format) async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cart is empty!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final items = _cart
          .map((i) => {
                'description': i['desc'],
                'sku': i['sku'],
                'quantity': i['qty'],
                'unit_price': i['price'],
                'gst_rate': i['gst'],
                'hsn_code': i['hsn'],
                'discount_type': i['discount_type'],
                'discount_value': i['discount_value'],
              })
          .toList();

      final service = ref.read(businessServiceProvider);
      final profile = await service.getProfile();

      final payload = {
        'company_name': profile['company_name'] ?? 'My Store',
        'company_address': profile['company_address'] ?? 'Store Address',
        'company_phone': profile['phone_number'],
        'company_gstin': profile['gst_number'],
        'receipt_number':
            'POS-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        'receipt_date': DateTime.now().toString().split(' ')[0],
        'customer_name': _customerName.text.isEmpty ? null : _customerName.text,
        'customer_phone':
            _customerPhone.text.isEmpty ? null : _customerPhone.text,
        'payment_mode': _paymentMode,
        'receipt_size': format,
        'pricing_mode': _pricingMode,
        'invoice_discount_type': _invoiceDiscountType,
        'invoice_discount_value': _invoiceDiscountValue,
        'items': items,
      };

      final pdfUrl = await service.generatePOSCheckout(payload);

      // Save to local SharedPreferences for end of day sync
      final prefs = await SharedPreferences.getInstance();
      List<String> pendingSales = prefs.getStringList('pending_sales') ?? [];
      
      String today = DateTime.now().toString().split(' ')[0];
      for (var item in items) {
        double unitPrice = item['unit_price'];
        double quantity = item['quantity'].toDouble();
        double gstRate = (item['gst_rate'] ?? 0).toDouble();
        
        double discount = 0;
        if (item['discount_type'] == 'PERCENTAGE') {
          discount = (quantity * unitPrice) * (item['discount_value'] / 100);
        } else if (item['discount_type'] == 'AMOUNT') {
          discount = item['discount_value'];
        }
        
        double itemTotal = (quantity * unitPrice) - discount;
        if (_pricingMode.toUpperCase() != 'WITHOUT_GST') {
          itemTotal += itemTotal * (gstRate / 100);
        }
        // Simplified invoice discount distribution for local storage
        if (_invoiceDiscountValue > 0 && _rawSubtotal > 0) {
           double ratio = ((quantity * unitPrice) - discount) / _rawSubtotal;
           itemTotal -= _calculatedInvoiceDiscount * ratio;
        }
        
        pendingSales.add(jsonEncode({
          'item_name': item['description'],
          'sku': item['sku'],
          'quantity_sold': item['quantity'],
          'unit_price': item['unit_price'],
          'total_amount': itemTotal,
          'sale_date': today,
        }));
      }
      await prefs.setStringList('pending_sales', pendingSales);


      if (mounted) {
        setState(() {
          _isLoading = false;
          _cart.clear();
          _customerName.clear();
          _customerPhone.clear();
        });

        final uri = Uri.parse(pdfUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Could not launch receipt URL');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('POS Checkout', style: AppTextStyles.screenHeading),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          if (isMobile) {
            return Column(
              children: [
                Expanded(flex: 3, child: _buildCartPanel()),
                Expanded(flex: 4, child: _buildCheckoutPanel()),
              ],
            );
          } else {
            return Row(
              children: [
                Expanded(flex: 3, child: _buildCartPanel()),
                Expanded(flex: 2, child: _buildCheckoutPanel()),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildCartPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
              color: AppColors.primaryYellow,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Shopping Cart', style: AppTextStyles.toolCardTitle),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 28),
                  onPressed: _scanItem,
                )
              ],
            ),
          ),
          Expanded(
            child: _cart.isEmpty
                ? Center(
                    child: Text(
                        'Cart is empty.\nTap the scanner to add items.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyText
                            .copyWith(color: Colors.grey.shade600)),
                  )
                : ListView.separated(
                    itemCount: _cart.length,
                    separatorBuilder: (context, index) =>
                        const Divider(color: Colors.black26, height: 1),
                    itemBuilder: (context, index) {
                      final item = _cart[index];
                      final double basePrice = item['price'];
                      final double itemAmt = basePrice * item['qty'];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(item['desc'],
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                      ),
                                      InkWell(
                                        onTap: () => _showItemDiscountDialog(index),
                                        child: const Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: Icon(Icons.discount_outlined, size: 18, color: AppColors.primaryPurple),
                                        ),
                                      )
                                    ],
                                  ),
                                  if (item['hsn'] != null && item['hsn'].toString().isNotEmpty)
                                    Text('HSN: ${item['hsn']}', style: AppTextStyles.caption.copyWith(color: AppColors.primaryPurple, fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Text(
                                      'Unit Price: ₹${basePrice.toStringAsFixed(2)}  |  GST: ${item['gst']}%',
                                      style: AppTextStyles.caption.copyWith(color: Colors.grey.shade700)),
                                  if (item['discount_type'] != null && item['discount_value'] > 0)
                                    Text(
                                      'Discount: ${item['discount_type'] == 'PERCENTAGE' ? '${item['discount_value']}%' : '₹${item['discount_value']}'}',
                                      style: AppTextStyles.caption.copyWith(color: Colors.green, fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => _updateQty(index, -1),
                                ),
                                Text('${item['qty']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => _updateQty(index, 1),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 80,
                              child: Text(
                                '₹${itemAmt.toStringAsFixed(2)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 16, right: 16, bottom: 16, left: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          const Text('Checkout Details', style: AppTextStyles.toolCardTitle),
          const SizedBox(height: 24),
          NeoTextField(
              controller: _customerName, label: 'Customer Name (Optional)'),
          const SizedBox(height: 16),
          NeoTextField(
              controller: _customerPhone, label: 'Customer Phone (Optional)'),
          const SizedBox(height: 24),
          Text('Payment Mode',
              style:
                  AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _paymentMode,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            items: ['Cash', 'Card', 'UPI', 'Due']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _paymentMode = v);
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Invoice Discount:', style: TextStyle(fontSize: 14)),
                    InkWell(
                      onTap: _showInvoiceDiscountDialog,
                      child: Row(
                        children: [
                          Text(
                            _invoiceDiscountValue > 0 
                                ? (_invoiceDiscountType == 'PERCENTAGE' ? '$_invoiceDiscountValue%' : '₹$_invoiceDiscountValue')
                                : 'Add Discount',
                            style: const TextStyle(fontSize: 14, color: AppColors.primaryPurple, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit, size: 14, color: AppColors.primaryPurple),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:', style: TextStyle(fontSize: 14)),
                    Text('₹${_subtotalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
                  ],
                ),
                ..._gstBreakup.entries.expand((e) {
                  final taxHalf = e.value / 2;
                  return [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('CGST @ ${e.key/2}%:', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                          Text('₹${taxHalf.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('SGST @ ${e.key/2}%:', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                          Text('₹${taxHalf.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ];
                }),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total GST:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    Text('₹${_totalTax.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(color: Colors.black38, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL:', style: AppTextStyles.toolCardTitle),
                    Text('₹${_totalAmount.toStringAsFixed(2)}',
                        style: AppTextStyles.screenHeading
                            .copyWith(color: AppColors.primaryPurple)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: NeoCard(
                  onTap: _isLoading ? null : () => _checkout('Thermal'),
                  backgroundColor: AppColors.primaryYellow,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: _isLoading 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text('THERMAL (80mm)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeoCard(
                  onTap: _isLoading ? null : () => _checkout('A4'),
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: _isLoading 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('GENERATE A4', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  void _showItemDiscountDialog(int index) {
    final item = _cart[index];
    final typeController = TextEditingController(text: item['discount_type'] ?? 'AMOUNT');
    final valController = TextEditingController(text: item['discount_value']?.toString() ?? '0');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text('Discount on ${item['desc']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
              initialValue: typeController.text,
              items: ['PERCENTAGE', 'AMOUNT'].map((e) => DropdownMenuItem(value: e, child: Text(e == 'PERCENTAGE' ? 'Percentage (%)' : 'Amount (₹)'))).toList(),
              onChanged: (v) {
                if (v != null) typeController.text = v;
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: valController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Discount Value', border: OutlineInputBorder()),
            )
          ],
        ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _cart[index]['discount_type'] = typeController.text;
                _cart[index]['discount_value'] = double.tryParse(valController.text) ?? 0.0;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Apply'),
          )
        ],
      ),
    );
  }

  void _showInvoiceDiscountDialog() {
    final typeController = TextEditingController(text: _invoiceDiscountType ?? 'AMOUNT');
    final valController = TextEditingController(text: _invoiceDiscountValue.toString());
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: const Text('Invoice Discount'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
              initialValue: typeController.text,
              items: ['PERCENTAGE', 'AMOUNT'].map((e) => DropdownMenuItem(value: e, child: Text(e == 'PERCENTAGE' ? 'Percentage (%)' : 'Amount (₹)'))).toList(),
              onChanged: (v) {
                if (v != null) typeController.text = v;
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: valController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Discount Value', border: OutlineInputBorder()),
            )
          ],
        ),
        ),
        actions: [
          TextButton(onPressed: () {
            setState(() {
              _invoiceDiscountType = null;
              _invoiceDiscountValue = 0.0;
            });
            Navigator.pop(ctx);
          }, child: const Text('Remove')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _invoiceDiscountType = typeController.text;
                _invoiceDiscountValue = double.tryParse(valController.text) ?? 0.0;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Apply'),
          )
        ],
      ),
    );
  }
}
