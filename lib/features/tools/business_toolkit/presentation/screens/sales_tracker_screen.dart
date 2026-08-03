import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';
import 'package:tool_hub/features/tools/business_toolkit/data/business_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'inventory_scanner_screen.dart';

final businessServiceProvider = Provider((ref) => BusinessService());

class SalesTrackerScreen extends ConsumerStatefulWidget {
  const SalesTrackerScreen({super.key});

  @override
  ConsumerState<SalesTrackerScreen> createState() => _SalesTrackerScreenState();
}

class _SalesTrackerScreenState extends ConsumerState<SalesTrackerScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  final _dateController = TextEditingController();
  String? _selectedSku;

  final List<Map<String, dynamic>> _sales = [];
  List<dynamic> _inventory = [];
  List<dynamic> _historicalSales = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _fetchInventory();
    _loadPendingSales();
    _fetchHistory();
  }

  Future<void> _loadPendingSales() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList('pending_sales') ?? [];
    setState(() {
      for (var p in pending) {
        _sales.add(jsonDecode(p));
      }
    });
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final history = await ref.read(businessServiceProvider).getSalesHistory();
      if (mounted) {
        setState(() {
          _historicalSales = history;
        });
      }
    } catch (e) {
      debugPrint('Failed to load history: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
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
      debugPrint('Error fetching inventory: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
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
      setState(() {
        _nameController.text = result['name'];
        _selectedSku = result['barcode'] ?? result['sku']?.toString();
        _priceController.text = (result['selling_price'] ?? result['unit_price'] ?? result['mrp'] ?? 0.0).toString();
        if (_qtyController.text.isEmpty) _qtyController.text = '1';
        if (_dateController.text.isEmpty) {
          final now = DateTime.now();
          _dateController.text = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        }
      });
      if (!mounted) return;
      SnackbarUtils.showNeoSnackBar(context, message: 'Added ${result['name']} from scanner');
    }
  }

  void _addSale() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _sales.add({
        'item_name': _nameController.text,
        'sku': _selectedSku,
        'quantity_sold': int.tryParse(_qtyController.text) ?? 1,
        'unit_price': double.tryParse(_priceController.text) ?? 0.0,
        'sale_date': _dateController.text,
      });
      _nameController.clear();
      _qtyController.clear();
      _priceController.clear();
      _dateController.clear();
      _selectedSku = null;
    });
  }

  Future<void> _syncSales() async {
    if (_sales.isEmpty) {
      SnackbarUtils.showNeoSnackBar(context, message: 'Add at least one sale.');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final res = await ref.read(businessServiceProvider).trackSales(_sales);
      
      if (mounted) {
        SnackbarUtils.showNeoSnackBar(
          context, 
          message: 'Synced! Rev: ₹${res['total_revenue']} | Items: ${res['total_items_sold']}', 
        );
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('pending_sales');
        
        setState(() {
          _sales.clear();
        });
        _fetchHistory();
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showNeoSnackBar(context, message: 'Failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, bool isRequired = true, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 6),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(2, 2)),
              ],
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: isNumber ? TextInputType.number : TextInputType.text,
              readOnly: onTap != null,
              onTap: onTap,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              validator: isRequired ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutocompleteField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Item Name (Search Inventory)', style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, fontSize: 12)),
              GestureDetector(
                onTap: _scanBarcodeToAdd,
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_scanner, size: 16, color: AppColors.primaryPurple),
                    const SizedBox(width: 4),
                    Text('Scan', style: AppTextStyles.caption.copyWith(color: AppColors.primaryPurple, fontWeight: FontWeight.bold)),
                  ],
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
                final name = invItem['name']?.toString().toLowerCase() ?? '';
                final sku = invItem['sku']?.toString().toLowerCase() ?? '';
                final query = textEditingValue.text.toLowerCase();
                return name.contains(query) || sku.contains(query);
              }).cast<Map<String, dynamic>>();
            },
            displayStringForOption: (Map<String, dynamic> option) => "${option['name']} (SKU: ${option['sku'] ?? 'N/A'})",
            onSelected: (Map<String, dynamic> selection) {
              _nameController.text = selection['name'];
              _selectedSku = selection['sku']?.toString();
              _priceController.text = selection['unit_price'].toString();
              if (_qtyController.text.isEmpty) _qtyController.text = '1';
              if (_dateController.text.isEmpty) {
                final now = DateTime.now();
                _dateController.text = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
              }
              setState(() {});
            },
            fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
              if (_nameController.text != textEditingController.text && !focusNode.hasFocus) {
                textEditingController.text = _nameController.text;
              }
              textEditingController.addListener(() {
                _nameController.text = textEditingController.text;
              });
              
              return Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                  ],
                ),
                child: TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Type to search...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
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
                    width: MediaQuery.of(context).size.width - 40,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          title: Text(option['name'], style: AppTextStyles.bodyText),
                          subtitle: Text('Stock: ${option['current_stock']} | Price: ₹${option['unit_price']}', style: AppTextStyles.caption),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.primaryGreen,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
            onPressed: () => context.pop(),
          ),
          title: Text('Sales Tracker', style: AppTextStyles.heroTitle.copyWith(fontSize: 20)),
          centerTitle: true,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.black,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Pending Sync'),
              Tab(text: 'Historical'),
            ],
          ),
          shape: const Border(bottom: BorderSide(color: Colors.black, width: 2)),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Pending Sync
            SafeArea(
              child: Column(
                children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sales List (${_sales.length})', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 12),
                    if (_sales.isEmpty)
                      Text('No sales added yet.', style: AppTextStyles.bodyText.copyWith(fontStyle: FontStyle.italic)),
                    ..._sales.map((e) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e['item_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('Qty: ${e['quantity_sold']} | Unit: ₹${e['unit_price']} | Date: ${e['sale_date']}', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() => _sales.remove(e));
                                },
                              )
                            ],
                          ),
                        )),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.black, thickness: 2),
                    const SizedBox(height: 16),
                    const Text('Log a Sale', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildAutocompleteField(),
                          Row(
                            children: [
                              Expanded(child: _buildTextField('Quantity Sold', _qtyController, isNumber: true)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildTextField('Unit Price', _priceController, isNumber: true)),
                            ],
                          ),
                          _buildTextField('Sale Date', _dateController, onTap: () => _selectDate(context)),
                          const SizedBox(height: 16),
                          NeoCard(
                            onTap: _addSale,
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            borderRadius: 8,
                            child: const Center(
                              child: Text(
                                '+ ADD SALE',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.black, width: 2)),
              ),
              child: NeoCard(
                onTap: _isLoading ? null : _syncSales,
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                borderRadius: 12,
                child: Center(
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : Text(
                          'SYNC SALES',
                          style: AppTextStyles.heroTitle.copyWith(fontSize: 18),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Tab 2: Historical Sales
      _isLoadingHistory
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _historicalSales.isEmpty
              ? const Center(child: Text('No historical sales found.', style: AppTextStyles.bodyText))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _historicalSales.length,
                  itemBuilder: (context, index) {
                    final item = _historicalSales[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item['item_name'] ?? 'Unknown Item', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('₹${item['total_amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryPurple)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Qty: ${item['quantity_sold']} | Unit: ₹${item['unit_price']}', style: const TextStyle(fontSize: 14)),
                              Text('${item['sale_date']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}
