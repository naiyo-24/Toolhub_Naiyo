import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';
import 'package:tool_hub/features/tools/business_toolkit/data/business_service.dart';
import 'package:tool_hub/features/tools/business_toolkit/presentation/screens/inventory_scanner_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';

final businessServiceProvider = Provider((ref) => BusinessService());

class InventoryManagerScreen extends ConsumerStatefulWidget {
  const InventoryManagerScreen({super.key});

  @override
  ConsumerState<InventoryManagerScreen> createState() =>
      _InventoryManagerScreenState();
}

class _InventoryManagerScreenState
    extends ConsumerState<InventoryManagerScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _businessType = 'Retailer';
  File? _selectedImage;
  
  List<dynamic> _gstMasterList = [];
  int? _selectedGstId;
  String _selectedProductType = 'Finished Good';

  // Manufacturer Form Controllers
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descController = TextEditingController();
  final _hsnController = TextEditingController();
  final _gstController = TextEditingController(text: '0.0');
  final _mrpController = TextEditingController();
  final _skuController = TextEditingController();
  final _initialStockController = TextEditingController(text: '0');
  final _reminderStockController = TextEditingController(text: '10');

  // Retailer Inventory Form Controllers (in dialog)
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _stockController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBusinessType();
    _fetchGstMaster();
  }

  Future<void> _fetchGstMaster() async {
    try {
      final list = await ref.read(businessServiceProvider).getGstMaster();
      if (mounted) {
        setState(() {
          _gstMasterList = list;
          if (_gstMasterList.isNotEmpty) {
            _selectedGstId = _gstMasterList.first['id'];
          }
        });
      }
    } catch (e) {
      debugPrint("Failed to fetch GST master: $e");
    }
  }

  Future<void> _loadBusinessType() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _businessType = prefs.getString('business_type') ?? 'Retailer';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _categoryController.dispose();
    _descController.dispose();
    _hsnController.dispose();
    _gstController.dispose();
    _mrpController.dispose();
    _skuController.dispose();
    _initialStockController.dispose();
    _reminderStockController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  String _generateSKU() {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return 'SKU-${List.generate(8, (index) => chars[random.nextInt(chars.length)]).join()}';
  }

  Future<void> _createProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await ref.read(businessServiceProvider).uploadImage(_selectedImage!);
      }

      final payload = {
        'name': _nameController.text,
        'brand': _brandController.text.isEmpty ? null : _brandController.text,
        'category':
            _categoryController.text.isEmpty ? null : _categoryController.text,
        'product_type': _selectedProductType,
        'hsn_code': _hsnController.text.isEmpty ? null : _hsnController.text,
        'gst_id': _selectedGstId,
        'gst_rate': 0.0, // Backend will handle it
        'mrp': double.tryParse(_mrpController.text),
        'description':
            _descController.text.isEmpty ? null : _descController.text,
        'initial_stock': int.tryParse(_initialStockController.text) ?? 0,
        'reminder_stock': int.tryParse(_reminderStockController.text) ?? 0,
        'barcode':
            _skuController.text.isEmpty ? _generateSKU() : _skuController.text,
        if (imageUrl != null) 'image_url': imageUrl,
      };

      final res = await ref.read(businessServiceProvider).addProduct(payload);

      if (mounted) {
        SnackbarUtils.showNeoSnackBar(context,
            message: 'Product created: ${res['name']}');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showNeoSnackBar(context, message: 'Failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _scanBarcodeToAddInventory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InventoryScannerScreen(
            inventory: [], isPicker: true, isGlobalLookup: true),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      _showAddToInventoryDialog(result);
    }
  }

  void _showAddToInventoryDialog(Map<String, dynamic> product) {
    _purchasePriceController.text = '';
    _sellingPriceController.text = product['mrp']?.toString() ?? '';
    _stockController.text = '1';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 3),
        ),
        title: Text('Add to Inventory: ${product['name']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField('Purchase Price', _purchasePriceController),
              _buildDialogField('Selling Price', _sellingPriceController),
              _buildDialogField('Stock to Add', _stockController),
              _buildDialogField('Reminder Stock', _reminderStockController),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYellow,
                foregroundColor: Colors.black),
            onPressed: () async {
              Navigator.pop(ctx);
              _addInventoryRecord(product['barcode']);
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  Future<void> _addInventoryRecord(String barcode) async {
    setState(() => _isLoading = true);
    try {
      final payload = {
        'barcode': barcode,
        'purchase_price': double.tryParse(_purchasePriceController.text) ?? 0.0,
        'selling_price': double.tryParse(_sellingPriceController.text) ?? 0.0,
        'available_stock': int.tryParse(_stockController.text) ?? 0,
        'reminder_stock': int.tryParse(_reminderStockController.text) ?? 0,
      };
      await ref.read(businessServiceProvider).addInventory(payload);
      if (mounted) {
        SnackbarUtils.showNeoSnackBar(context,
            message: 'Inventory updated successfully!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showNeoSnackBar(context, message: 'Failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildDialogField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumber = false, bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.bodyText
                  .copyWith(fontWeight: FontWeight.bold, fontSize: 12)),
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
              keyboardType:
                  isNumber ? TextInputType.number : TextInputType.text,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              validator: isRequired
                  ? (v) => v == null || v.isEmpty ? 'Required' : null
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isManufacturer = _businessType == 'Manufacturer';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(isManufacturer ? 'Create Product' : 'Manage Inventory',
            style: AppTextStyles.heroTitle
                .copyWith(fontSize: 20, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Colors.black, width: 2)),
      ),
      body: SafeArea(
        child: isManufacturer ? _buildManufacturerView() : _buildRetailerView(),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Product Image', style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.image, size: 40, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  NeoCard(
                    onTap: () => _pickImage(ImageSource.gallery),
                    backgroundColor: AppColors.primaryOrange,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Center(child: Text('Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ),
                  const SizedBox(height: 8),
                  NeoCard(
                    onTap: () => _pickImage(ImageSource.camera),
                    backgroundColor: AppColors.primaryYellow,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Center(child: Text('Camera', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildManufacturerView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                      'Add a new product to the catalog. It will automatically be assigned a barcode.',
                      style: AppTextStyles.bodyText),
                  const SizedBox(height: 24),
                  _buildImagePicker(),
                  _buildTextField('Product Name', _nameController),
                  Row(
                    children: [
                      Expanded(
                          child: _buildTextField('Brand', _brandController,
                              isRequired: false)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildTextField(
                              'Category', _categoryController,
                              isRequired: false)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Product Type*',
                          style: AppTextStyles.bodyText.copyWith(
                              fontWeight: FontWeight.bold, fontSize: 12)),
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
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedProductType,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontSize: 14),
                            dropdownColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedProductType = newValue;
                                });
                              }
                            },
                            items: ['Finished Good', 'Raw Material']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _buildTextField('MRP', _mrpController,
                              isNumber: true, isRequired: false)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('GST Slab*',
                                  style: AppTextStyles.bodyText.copyWith(
                                      fontWeight: FontWeight.bold, fontSize: 12)),
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
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: _selectedGstId,
                                    isExpanded: true,
                                    icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontSize: 14),
                                    dropdownColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    onChanged: (int? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _selectedGstId = newValue;
                                        });
                                      }
                                    },
                                    items: _gstMasterList.map<DropdownMenuItem<int>>((dynamic gst) {
                                      return DropdownMenuItem<int>(
                                        value: gst['id'],
                                        child: Text('${gst['gst_rate']}%'),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          )),
                    ],
                  ),
                  _buildTextField('Description', _descController,
                      isRequired: false),
                  if (_businessType == 'Manufacturer') ...[
                    _buildTextField('HSN Code', _hsnController,
                        isRequired: false),
                    _buildTextField('Initial Stock', _initialStockController,
                        isNumber: true, isRequired: true),
                    _buildTextField('Reminder Stock', _reminderStockController,
                        isNumber: true, isRequired: true),
                  ],
                  if (_businessType != 'Manufacturer')
                    _buildTextField('SKU/Barcode (Leave empty to auto-generate)',
                        _skuController,
                        isRequired: false),
                ],
              ),
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
            onTap: _isLoading ? null : _createProduct,
            backgroundColor: AppColors.primaryBlue,
            padding: const EdgeInsets.symmetric(vertical: 16),
            borderRadius: 12,
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      'CREATE PRODUCT',
                      style: AppTextStyles.heroTitle
                          .copyWith(fontSize: 18, color: Colors.white),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRetailerView() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NeoCard(
              onTap: _scanBarcodeToAddInventory,
              backgroundColor: AppColors.primaryYellow,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_scanner, size: 64),
                  const SizedBox(height: 16),
                  Text('SCAN PRODUCT BARCODE',
                      style: AppTextStyles.heroTitle.copyWith(fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text(
                      'Scan a manufacturer product to add it to your inventory.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyText),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Or',
                textAlign: TextAlign.center, style: AppTextStyles.sectionTitle),
            const SizedBox(height: 24),
            NeoCard(
              onTap: () {
                setState(() {
                  _businessType = 'Manufacturer';
                });
                SnackbarUtils.showNeoSnackBar(context,
                    message: 'Creating a Private Product...');
              },
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.add_box, size: 64, color: Colors.white),
                  const SizedBox(height: 16),
                  Text('CREATE CUSTOM PRODUCT',
                      style: AppTextStyles.heroTitle
                          .copyWith(fontSize: 18, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('For loose items like fruits, bakery, etc.',
                      textAlign: TextAlign.center,
                      style:
                          AppTextStyles.bodyText.copyWith(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
