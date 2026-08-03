import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';
import 'package:tool_hub/features/tools/business_toolkit/data/business_service.dart';

final businessServiceProvider = Provider((ref) => BusinessService());

class ExpenseManagerScreen extends ConsumerStatefulWidget {
  const ExpenseManagerScreen({super.key});

  @override
  ConsumerState<ExpenseManagerScreen> createState() => _ExpenseManagerScreenState();
}

class _ExpenseManagerScreenState extends ConsumerState<ExpenseManagerScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _catController = TextEditingController();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();

  final List<Map<String, dynamic>> _expenses = [];

  @override
  void dispose() {
    _catController.dispose();
    _descController.dispose();
    _amountController.dispose();
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

  void _addExpense() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _expenses.add({
        'category': _catController.text,
        'description': _descController.text,
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'date': _dateController.text,
      });
      _catController.clear();
      _descController.clear();
      _amountController.clear();
      _dateController.clear();
    });
  }

  Future<void> _syncExpenses() async {
    if (_expenses.isEmpty) {
      SnackbarUtils.showNeoSnackBar(context, message: 'Add at least one expense.');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final res = await ref.read(businessServiceProvider).manageExpenses(_expenses);
      
      if (mounted) {
        SnackbarUtils.showNeoSnackBar(
          context, 
          message: 'Synced! Total Added: ₹${res['total_business_expenses_added']}', 
        );
        setState(() {
          _expenses.clear();
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Expense Manager', style: AppTextStyles.heroTitle.copyWith(fontSize: 20, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Colors.black, width: 2)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Expense List (${_expenses.length})', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 12),
                    if (_expenses.isEmpty)
                      Text('No expenses added yet.', style: AppTextStyles.bodyText.copyWith(fontStyle: FontStyle.italic)),
                    ..._expenses.map((e) => Container(
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
                                  Text(e['description'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('${e['category']} | ₹${e['amount']} | ${e['date']}', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() => _expenses.remove(e));
                                },
                              )
                            ],
                          ),
                        )),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.black, thickness: 2),
                    const SizedBox(height: 16),
                    const Text('Log an Expense', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField('Category (e.g. Travel, Office)', _catController),
                          _buildTextField('Description', _descController),
                          Row(
                            children: [
                              Expanded(child: _buildTextField('Amount', _amountController, isNumber: true)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildTextField('Date', _dateController, onTap: () => _selectDate(context))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          NeoCard(
                            onTap: _addExpense,
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            borderRadius: 8,
                            child: const Center(
                              child: Text(
                                '+ ADD EXPENSE',
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
                onTap: _isLoading ? null : _syncExpenses,
                backgroundColor: AppColors.primaryRed,
                padding: const EdgeInsets.symmetric(vertical: 16),
                borderRadius: 12,
                child: Center(
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          'SYNC EXPENSES',
                          style: AppTextStyles.heroTitle.copyWith(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
