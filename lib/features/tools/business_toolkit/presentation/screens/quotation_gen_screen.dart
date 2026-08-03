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

class QuotationGenScreen extends ConsumerStatefulWidget {
  const QuotationGenScreen({super.key});

  @override
  ConsumerState<QuotationGenScreen> createState() => _QuotationGenScreenState();
}

class _QuotationGenScreenState extends ConsumerState<QuotationGenScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _companyName = TextEditingController();
  final _companyAddress = TextEditingController();
  final _clientName = TextEditingController();
  final _clientAddress = TextEditingController();
  final _quotationNumber = TextEditingController();
  final _validUntil = TextEditingController(text: DateTime.now().add(const Duration(days: 30)).toString().split(' ')[0]);

  final List<Map<String, TextEditingController>> _items = [];
  bool _isLoading = false;
  List<dynamic> _inventory = [];

  @override
  void initState() {
    super.initState();
    _fetchInventory();
    _fetchProfile();
    _addItem();
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await ref.read(businessServiceProvider).getProfile();
      if (mounted) {
        setState(() {
          _companyName.text = profile['company_name'] ?? '';
          _companyAddress.text = profile['company_address'] ?? '';
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
      debugPrint('Error fetching inventory for quotation: $e');
    }
  }

  void _addItem({Map<String, dynamic>? product}) {
    setState(() {
      _items.add({
        'desc': TextEditingController(text: product != null ? product['name'] : ''),
        'qty': TextEditingController(text: product != null ? '1' : ''),
        'price': TextEditingController(text: product != null ? ((product['selling_price'] != null && product['selling_price'] > 0) ? product['selling_price'] : (product['mrp'] ?? 0)).toString() : ''),
      });
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _scanBarcodeToAdd() async {
    if (_inventory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading inventory, please wait...')),
      );
      return;
    }
    
    // Navigate to scanner as picker
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InventoryScannerScreen(
          inventory: _inventory,
          isPicker: true,
        ),
      ),
    );
    
    if (result != null && result is Map<String, dynamic>) {
      // If the first item is empty, replace it, otherwise add new
      if (_items.length == 1 && _items[0]['desc']!.text.isEmpty && _items[0]['qty']!.text.isEmpty) {
        setState(() {
          _items[0]['desc']!.text = result['name'];
          _items[0]['qty']!.text = '1';
          _items[0]['price']!.text = ((result['selling_price'] != null && result['selling_price'] > 0) ? result['selling_price'] : (result['mrp'] ?? 0)).toString();
        });
      } else {
        _addItem(product: result);
      }
      if (!mounted) return;
      final price = (result['selling_price'] ?? result['unit_price'] ?? result['mrp'] ?? 0.0).toStringAsFixed(2);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${result['name']} (₹$price) to quotation!')),
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
        'quantity': int.tryParse(i['qty']!.text) ?? 1,
        'unit_price': double.tryParse(i['price']!.text) ?? 0.0,
        'gst_rate': 0.0, // Schema requires this, even though quotation might not use it
      }).toList();

      final payload = {
        'company_name': _companyName.text,
        'company_address': _companyAddress.text.isEmpty ? 'Address not provided' : _companyAddress.text,
        'client_name': _clientName.text,
        'client_address': _clientAddress.text.isEmpty ? 'Address not provided' : _clientAddress.text,
        'quotation_number': _quotationNumber.text,
        'valid_until': _validUntil.text,
        'items': items,
      };

      final service = ref.read(businessServiceProvider);
      final pdfPath = await service.generateQuotation(payload);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quotation generated! Opening...')),
        );
        final uri = Uri.parse(pdfPath);
        if (await canLaunchUrl(uri)) {
          if (mounted) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open quotation.')),
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
        title: const Text('Quotation Generator', style: AppTextStyles.screenHeading),
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
              NeoCard(
                backgroundColor: Colors.white,
                child: Column(
                  children: [
                    NeoTextField(controller: _companyName, label: 'Your Company Name', validator: _req),
                    const SizedBox(height: 12),
                    NeoTextField(controller: _companyAddress, label: 'Company Address', validator: _req),
                    const SizedBox(height: 12),
                    NeoTextField(controller: _clientName, label: 'Client Name', validator: _req),
                    const SizedBox(height: 12),
                    NeoTextField(controller: _clientAddress, label: 'Client Address', validator: _req),
                    const SizedBox(height: 12),
                    NeoTextField(controller: _quotationNumber, label: 'Quotation Number', hint: 'QT-001', validator: _req),
                    const SizedBox(height: 12),
                    NeoTextField(controller: _validUntil, label: 'Valid Until', hint: 'YYYY-MM-DD', validator: _req),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Items', style: AppTextStyles.sectionTitle),
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
                      )
                    ],
                  )
                ],
              ),
              const SizedBox(height: 8),
              ..._items.asMap().entries.map((e) => _buildItemCard(e.key, e.value)),
              
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
                      : const Text('Generate Quotation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                      Text('Description / Search Inventory', style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
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
                          item['price']!.text = ((selection['selling_price'] != null && selection['selling_price'] > 0) ? selection['selling_price'] : (selection['mrp'] ?? 0)).toString();
                          if (item['qty']!.text.isEmpty) item['qty']!.text = '1';
                          setState(() {});
                        },
                        fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
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
                  child: NeoTextField(controller: item['qty']!, label: 'Qty', keyboardType: TextInputType.number, validator: _req),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NeoTextField(controller: item['price']!, label: 'Unit Price', keyboardType: TextInputType.number, validator: _req),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  String? _req(String? val) => val == null || val.isEmpty ? 'Required' : null;
}
