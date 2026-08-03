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
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';

class InvoiceGeneratorScreen extends ConsumerStatefulWidget {
  final bool isGst;
  const InvoiceGeneratorScreen({super.key, this.isGst = false});

  @override
  ConsumerState<InvoiceGeneratorScreen> createState() => _InvoiceGeneratorScreenState();
}

class _InvoiceGeneratorScreenState extends ConsumerState<InvoiceGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _companyName = TextEditingController();
  final _companyAddress = TextEditingController();
  final _companyGstin = TextEditingController();
  final _companyPhone = TextEditingController();
  final _companyWhatsapp = TextEditingController();
  
  final _clientName = TextEditingController();
  final _clientCompanyName = TextEditingController();
  final _clientAddress = TextEditingController();
  final _clientGstin = TextEditingController();
  final _clientPhone = TextEditingController();
  final _clientWhatsapp = TextEditingController();
  
  final _invoiceNumber = TextEditingController();
  final _invoiceDate = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
  String? _companyLogoUrl;
  
  final _bankName = TextEditingController();
  final _accName = TextEditingController();
  final _accNumber = TextEditingController();
  final _ifscCode = TextEditingController();

  final List<Map<String, TextEditingController>> _items = [];
  bool _isLoading = false;
  List<dynamic> _inventory = [];
  String _pricingMode = 'EXCLUSIVE';
  String? _invoiceDiscountType;
  double _invoiceDiscountValue = 0.0;

  @override
  void initState() {
    super.initState();
    _invoiceNumber.text = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    _fetchInventory();
    _fetchProfile();
    _addItem(); // Start with one item
  }
  
  Future<void> _fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _companyLogoUrl = prefs.getString('company_logo_url');
          _bankName.text = prefs.getString('bank_name') ?? '';
          _accName.text = prefs.getString('account_name') ?? '';
          _accNumber.text = prefs.getString('account_number') ?? '';
          _ifscCode.text = prefs.getString('ifsc_code') ?? '';
          String pm = prefs.getString('pricing_mode') ?? 'EXCLUSIVE';
          if (pm == 'INCLUSIVE') pm = 'EXCLUSIVE';
          _pricingMode = pm;
        });
      }
      final profile = await ref.read(businessServiceProvider).getProfile();
      if (mounted) {
        setState(() {
          _companyName.text = profile['company_name'] ?? '';
          _companyAddress.text = profile['company_address'] ?? '';
          _companyGstin.text = profile['gst_number'] ?? '';
          _companyPhone.text = profile['phone_number'] ?? '';
          _companyWhatsapp.text = profile['whatsapp_number'] ?? '';
          _bankName.text = profile['bank_name'] ?? _bankName.text;
          _accName.text = profile['account_name'] ?? _accName.text;
          _accNumber.text = profile['account_number'] ?? _accNumber.text;
          _ifscCode.text = profile['ifsc_code'] ?? _ifscCode.text;
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }
  
  Future<void> _fetchInventory() async {
    try {
      final items = await ref.read(businessServiceProvider).getInventory();
      if (mounted) {
        setState(() {
          _inventory = items;
        });
      }
    } catch (e) {
      debugPrint('Error fetching inventory for billing: $e');
    }
  }

  void _addItem({Map<String, dynamic>? product}) {
    final qtyCtrl = TextEditingController(text: product != null ? '1' : '');
    final priceCtrl = TextEditingController(text: product != null ? (product['selling_price'] ?? product['unit_price'] ?? product['mrp']).toString() : '');
    final gstCtrl = TextEditingController(text: product != null ? (product['gst_rate'] ?? 0.0).toString() : '0');
    final discountTypeCtrl = TextEditingController(text: 'AMOUNT');
    final discountValCtrl = TextEditingController(text: '0');

    void listener() => setState(() {});
    qtyCtrl.addListener(listener);
    priceCtrl.addListener(listener);
    gstCtrl.addListener(listener);
    discountValCtrl.addListener(listener);
    discountTypeCtrl.addListener(listener);

    setState(() {
      _items.add({
        'desc': TextEditingController(text: product != null ? product['name'] : ''),
        'sku': TextEditingController(text: product != null ? (product['barcode'] ?? product['sku']?.toString()) : ''),
        'hsn': TextEditingController(text: product != null ? (product['hsn_code']?.toString() ?? '') : ''),
        'qty': qtyCtrl,
        'unit': TextEditingController(text: 'Piece'),
        'price': priceCtrl,
        'gst': gstCtrl,
        'discount_type': discountTypeCtrl,
        'discount_value': discountValCtrl,
      });
    });
  }

  double get _rawSubtotal {
    double total = 0;
    for (var item in _items) {
      double qty = double.tryParse(item['qty']!.text) ?? 0.0;
      double price = double.tryParse(item['price']!.text) ?? 0.0;
      double discount = 0.0;
      if (item.containsKey('discount_type') && item.containsKey('discount_value')) {
        double dVal = double.tryParse(item['discount_value']!.text) ?? 0.0;
        if (item['discount_type']!.text == 'PERCENTAGE') {
          discount = (qty * price) * (dVal / 100);
        } else {
          discount = dVal;
        }
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
    return _rawSubtotal;
  }

  Map<double, double> get _gstBreakup {
    Map<double, double> breakup = {};
    double rawSub = _rawSubtotal;
    double invDisc = _calculatedInvoiceDiscount;

    for (var item in _items) {
      double gstRate = double.tryParse(item['gst']!.text) ?? 0.0;
      if (gstRate == 0) continue;

      double qty = double.tryParse(item['qty']!.text) ?? 0.0;
      double price = double.tryParse(item['price']!.text) ?? 0.0;
      
      double discount = 0.0;
      if (item.containsKey('discount_type') && item.containsKey('discount_value')) {
        double dVal = double.tryParse(item['discount_value']!.text) ?? 0.0;
        if (item['discount_type']!.text == 'PERCENTAGE') {
          discount = (qty * price) * (dVal / 100);
        } else {
          discount = dVal;
        }
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
    if (_pricingMode.toUpperCase() == 'WITHOUT_GST') return 0.0;
    return _gstBreakup.values.fold(0.0, (sum, val) => sum + val);
  }

  double get _totalAmount {
    return _subtotalAmount - _calculatedInvoiceDiscount + _totalTax;
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
      if (_items.length == 1 && _items[0]['desc']!.text.isEmpty && _items[0]['qty']!.text.isEmpty) {
        setState(() {
          _items[0]['desc']!.text = result['name'];
          _items[0]['sku']!.text = result['barcode'] ?? result['sku']?.toString() ?? '';
          _items[0]['hsn']!.text = result['hsn_code']?.toString() ?? '';
          _items[0]['qty']!.text = '1';
          _items[0]['price']!.text = (result['selling_price'] ?? result['unit_price'] ?? result['mrp']).toString();
          _items[0]['gst']!.text = (result['gst_rate'] ?? 0.0).toString();
        });
      } else {
        _addItem(product: result);
      }
      if (!mounted) return;
      final price = (result['selling_price'] ?? result['unit_price'] ?? result['mrp'])?.toStringAsFixed(2) ?? '0.00';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${result['name']} (₹$price) to bill!')),
      );
    }
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final items = _items.map((i) => {
        'description': i['desc']!.text,
        'sku': i['sku']!.text.isEmpty ? null : i['sku']!.text,
        'hsn_code': i['hsn']!.text.isEmpty ? null : i['hsn']!.text,
        'quantity': int.tryParse(i['qty']!.text) ?? 1,
        'unit': i['unit']!.text.isEmpty ? 'Piece' : i['unit']!.text,
        'unit_price': double.tryParse(i['price']!.text) ?? 0.0,
        'gst_rate': double.tryParse(i['gst']!.text) ?? 0.0,
        'discount_type': i.containsKey('discount_type') && i['discount_type']!.text.isNotEmpty ? i['discount_type']!.text : null,
        'discount_value': i.containsKey('discount_value') ? (double.tryParse(i['discount_value']!.text) ?? 0.0) : 0.0,
      }).toList();

      final payload = {
        'company_name': _companyName.text,
        'company_address': _companyAddress.text,
        'company_gstin': _companyGstin.text.isEmpty ? null : _companyGstin.text,
        'company_phone': _companyPhone.text.isEmpty ? null : _companyPhone.text,
        'company_whatsapp': _companyWhatsapp.text.isEmpty ? null : _companyWhatsapp.text,
        'company_logo_url': _companyLogoUrl,
        
        'client_name': _clientName.text,
        'client_company_name': _clientCompanyName.text.isEmpty ? null : _clientCompanyName.text,
        'client_address': _clientAddress.text,
        'client_gstin': _clientGstin.text.isEmpty ? null : _clientGstin.text,
        'client_phone': _clientPhone.text.isEmpty ? null : _clientPhone.text,
        'client_whatsapp': _clientWhatsapp.text.isEmpty ? null : _clientWhatsapp.text,
        
        'bank_name': _bankName.text.isEmpty ? null : _bankName.text,
        'account_name': _accName.text.isEmpty ? null : _accName.text,
        'account_number': _accNumber.text.isEmpty ? null : _accNumber.text,
        'ifsc_code': _ifscCode.text.isEmpty ? null : _ifscCode.text,
        'pricing_mode': _pricingMode,
        
        'invoice_number': _invoiceNumber.text,
        'invoice_date': _invoiceDate.text,
        'invoice_discount_type': _invoiceDiscountType,
        'invoice_discount_value': _invoiceDiscountValue,
        'items': items,
        'is_gst_invoice': widget.isGst,
      };

      final service = ref.read(businessServiceProvider);
      final pdfUrl = widget.isGst 
          ? await service.generateGstBill(payload)
          : await service.generateInvoice(payload);

      // Save to local SharedPreferences for end of day sync
      final prefs = await SharedPreferences.getInstance();
      List<String> pendingSales = prefs.getStringList('pending_sales') ?? [];
      
      for (var item in items) {
        double unitPrice = item['unit_price'] as double;
        int quantity = item['quantity'] as int;
        double gstRate = (item['gst_rate'] ?? 0.0) as double;
        
        double itemTotal = 0.0;
        
        double discount = 0;
        if (item['discount_type'] == 'PERCENTAGE') {
          discount = (quantity * unitPrice) * ((item['discount_value'] as double) / 100);
        } else if (item['discount_type'] == 'AMOUNT') {
          discount = item['discount_value'] as double;
        }
        
        itemTotal = (quantity * unitPrice) - discount;

        if (_pricingMode.toUpperCase() != 'WITHOUT_GST') {
          itemTotal += itemTotal * (gstRate / 100);
        }
        
        if (_invoiceDiscountValue > 0 && _rawSubtotal > 0) {
           double ratio = ((quantity * unitPrice) - discount) / _rawSubtotal;
           itemTotal -= _calculatedInvoiceDiscount * ratio;
        }

        pendingSales.add(jsonEncode({
          'item_name': item['description'],
          'sku': item['sku'],
          'quantity_sold': quantity,
          'unit_price': unitPrice,
          'total_amount': itemTotal,
          'sale_date': _invoiceDate.text,
        }));
      }
      await prefs.setStringList('pending_sales', pendingSales);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice generated! Opening...')),
        );
        final uri = Uri.parse(pdfUrl);
        if (await canLaunchUrl(uri)) {
          if (mounted) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open the invoice URL.')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(widget.isGst ? 'GST Billing' : 'Invoice Generator', style: AppTextStyles.screenHeading),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('Your Details'),
              NeoCard(
                backgroundColor: Colors.white,
                child: Column(
                  children: [
                    const Text('Your Details', style: AppTextStyles.toolCardTitle),
                    const SizedBox(height: 16),
                    NeoTextField(controller: _companyName, label: 'Company / Your Name'),
                    const SizedBox(height: 12),
                    NeoTextField(controller: _companyAddress, label: 'Address', maxLines: 2),
                    const SizedBox(height: 12),
                    NeoTextField(controller: _companyPhone, label: 'Phone Number (Optional)'),
                    const SizedBox(height: 12),
                    NeoTextField(controller: _companyWhatsapp, label: 'WhatsApp Number (Optional)'),
                    if (widget.isGst) ...[
                      const SizedBox(height: 12),
                      NeoTextField(controller: _companyGstin, label: 'Your GSTIN'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Bank Details (Optional)'),
              NeoCard(
                backgroundColor: Colors.white,
                child: Column(
                  children: [
                    const Text('Bank Details (Optional)', style: AppTextStyles.toolCardTitle),
                    const SizedBox(height: 16),
                    NeoTextField(controller: _bankName, label: 'Bank Name'),
                    const SizedBox(height: 12),
                    NeoTextField(controller: _accName, label: 'Account Name'),
                    const SizedBox(height: 12),
                    NeoTextField(controller: _accNumber, label: 'Account Number', keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    NeoTextField(controller: _ifscCode, label: 'IFSC Code'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              _buildSectionTitle('Client Details'),
              NeoCard(
                backgroundColor: Colors.white,
                child: Column(
                  children: [
                    const Text('Client Details', style: AppTextStyles.toolCardTitle),
                    const SizedBox(height: 16),
                    NeoTextField(controller: _clientName, label: 'Client Name'),
                    const SizedBox(height: 12),
                    NeoTextField(controller: _clientCompanyName, label: 'Client Company Name (Optional)'),
                    const SizedBox(height: 12),
                    NeoTextField(controller: _clientPhone, label: 'Client Phone (Optional)'),
                    const SizedBox(height: 12),
                    NeoTextField(controller: _clientWhatsapp, label: 'Client WhatsApp (Optional)'),
                    const SizedBox(height: 12),
                    NeoTextField(controller: _clientAddress, label: 'Client Address', maxLines: 2),
                    if (widget.isGst) ...[
                      const SizedBox(height: 12),
                      NeoTextField(controller: _clientGstin, label: 'Client GSTIN'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              _buildSectionTitle('Invoice Info'),
              NeoCard(
                backgroundColor: Colors.white,
                child: Column(
                  children: [
                    NeoTextField(controller: _invoiceNumber, label: 'Invoice Number (e.g. INV-001)'),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppColors.primaryBlue,
                                  onPrimary: Colors.white,
                                  onSurface: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (pickedDate != null) {
                          setState(() {
                            _invoiceDate.text = pickedDate.toString().split(' ')[0];
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: NeoTextField(
                          controller: _invoiceDate,
                          label: 'Invoice Date',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Items'),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _scanBarcodeToAdd,
                        icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.black),
                        tooltip: 'Scan Barcode',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primaryYellow,
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _addItem(),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Add Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          side: const BorderSide(color: Colors.black, width: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 8),
              ..._items.asMap().entries.map((e) => _buildItemCard(e.key, e.value)),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Invoice Summary'),
              NeoCard(
                backgroundColor: Colors.white,
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
                    if (_pricingMode.toUpperCase() != 'WITHOUT_GST') ...[
                      const SizedBox(height: 8),
                      ..._gstBreakup.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('GST @ ${e.key}%:', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                            Text('₹${e.value.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                      )),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Tax:', style: TextStyle(fontSize: 14)),
                          Text('₹${_totalTax.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ],
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('₹${_totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryPurple)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _generate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Generate PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: AppTextStyles.sectionTitle),
    );
  }

  Widget _buildItemCard(int index, Map<String, TextEditingController> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeoCard(
        backgroundColor: Colors.grey.shade100,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Description / Search', style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
                          InkWell(
                            onTap: () => _showItemDiscountDialog(index),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.discount_outlined, size: 18, color: AppColors.primaryPurple),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 6),
                      Autocomplete<Map<String, dynamic>>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<Map<String, dynamic>>.empty();
                          }
                          return _inventory.where((dynamic invItem) {
                            final name = invItem['name'].toString().toLowerCase();
                            final query = textEditingValue.text.toLowerCase();
                            return name.contains(query);
                          }).cast<Map<String, dynamic>>();
                        },
                        displayStringForOption: (Map<String, dynamic> option) => option['name'],
                        onSelected: (Map<String, dynamic> selection) {
                          item['desc']!.text = selection['name'];
                          item['sku']!.text = selection['barcode'] ?? selection['sku']?.toString() ?? '';
                          item['hsn']!.text = selection['hsn_code']?.toString() ?? '';
                          item['price']!.text = ((selection['selling_price'] != null && selection['selling_price'] > 0) ? selection['selling_price'] : (selection['mrp'] ?? 0)).toString();
                          item['gst']!.text = (selection['gst_rate'] ?? 0.0).toString();
                          if (item['qty']!.text.isEmpty) item['qty']!.text = '1';
                          setState(() {});
                        },
                        fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                          // Sync the external controller with the autocomplete internal controller
                          if (item['desc']!.text != textEditingController.text && !focusNode.hasFocus) {
                            textEditingController.text = item['desc']!.text;
                          }
                          textEditingController.addListener(() {
                            item['desc']!.text = textEditingController.text;
                          });
                          
                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Type item name...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.black, width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.black, width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: Colors.black, width: 2),
                              ),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width - 96,
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final option = options.elementAt(index);
                                    return ListTile(
                                      title: Text(option['name'], style: AppTextStyles.bodyText),
                                      subtitle: Text('Stock: ${option['current_stock']} | Price: ₹${((option['selling_price'] != null && option['selling_price'] > 0) ? option['selling_price'] : (option['mrp'] ?? 0))}', style: AppTextStyles.caption),
                                      onTap: () {
                                        onSelected(option);
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.primaryRed),
                  onPressed: () => _removeItem(index),
                )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: NeoTextField(controller: item['qty']!, label: 'Qty', keyboardType: TextInputType.number, validator: _req),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue: item['unit']!.text,
                    decoration: InputDecoration(
                      labelText: 'Unit',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: ['Piece', 'Kg', 'Gram', 'Box', 'Litre', 'Pack', 'Dozen'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) { if (v != null) item['unit']!.text = v; },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: NeoTextField(controller: item['price']!, label: 'Unit Price', keyboardType: TextInputType.number, validator: _req),
                ),
              ],
            ),
            if (widget.isGst) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: NeoTextField(controller: item['hsn']!, label: 'HSN Code', keyboardType: TextInputType.text),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeoTextField(controller: item['gst']!, label: 'GST %', keyboardType: TextInputType.number, validator: _req),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  String? _req(String? val) => val == null || val.isEmpty ? 'Required' : null;

  void _showItemDiscountDialog(int index) {
    final item = _items[index];
    final typeController = TextEditingController(text: item['discount_type']?.text.isNotEmpty == true ? item['discount_type']!.text : 'AMOUNT');
    final valController = TextEditingController(text: item['discount_value']?.text.isNotEmpty == true ? item['discount_value']!.text : '0');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text('Discount on ${item['desc']!.text.isEmpty ? 'Item' : item['desc']!.text}'),
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
                item['discount_type']!.text = typeController.text;
                item['discount_value']!.text = double.tryParse(valController.text)?.toString() ?? '0';
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
