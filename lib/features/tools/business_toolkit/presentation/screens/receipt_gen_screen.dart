import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';
import 'package:tool_hub/features/tools/business_toolkit/data/business_service.dart';
import 'package:open_filex/open_filex.dart';

final businessServiceProvider = Provider((ref) => BusinessService());

class ReceiptGenScreen extends ConsumerStatefulWidget {
  const ReceiptGenScreen({super.key});

  @override
  ConsumerState<ReceiptGenScreen> createState() => _ReceiptGenScreenState();
}

class _ReceiptGenScreenState extends ConsumerState<ReceiptGenScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _receiptNumberController = TextEditingController();
  final _receiptDateController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _receivedFromController = TextEditingController();
  final _amountController = TextEditingController();
  final _paymentModeController = TextEditingController(text: 'Cash');
  final _purposeController = TextEditingController();
  final _transactionIdController = TextEditingController();

  @override
  void dispose() {
    _receiptNumberController.dispose();
    _receiptDateController.dispose();
    _companyNameController.dispose();
    _receivedFromController.dispose();
    _amountController.dispose();
    _paymentModeController.dispose();
    _purposeController.dispose();
    _transactionIdController.dispose();
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
        _receiptDateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _generateReceipt() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final payload = {
        'receipt_number': _receiptNumberController.text,
        'receipt_date': _receiptDateController.text,
        'company_name': _companyNameController.text,
        'received_from': _receivedFromController.text,
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'payment_mode': _paymentModeController.text,
        'purpose': _purposeController.text,
        'transaction_id': _transactionIdController.text.isEmpty ? null : _transactionIdController.text,
      };

      final pdfPath = await ref.read(businessServiceProvider).generateReceipt(payload);
      
      if (mounted) {
        SnackbarUtils.showNeoSnackBar(context, message: 'Receipt generated successfully!');
        await OpenFilex.open(pdfPath);
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text('Receipt Gen', style: AppTextStyles.heroTitle.copyWith(fontSize: 20)),
        centerTitle: true,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Colors.black, width: 2)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField('Receipt Number', _receiptNumberController),
                _buildTextField('Receipt Date', _receiptDateController, onTap: () => _selectDate(context)),
                _buildTextField('Company Name', _companyNameController),
                _buildTextField('Received From', _receivedFromController),
                _buildTextField('Amount', _amountController, isNumber: true),
                _buildTextField('Payment Mode (Cash/Card/Online)', _paymentModeController),
                _buildTextField('Purpose', _purposeController),
                _buildTextField('Transaction ID (Optional)', _transactionIdController, isRequired: false),
                
                const SizedBox(height: 24),
                NeoCard(
                  onTap: _isLoading ? null : _generateReceipt,
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  borderRadius: 12,
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : Text(
                            'GENERATE PDF',
                            style: AppTextStyles.heroTitle.copyWith(fontSize: 18),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
