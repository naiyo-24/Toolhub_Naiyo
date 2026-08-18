import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../theme/loandesk_theme.dart';
import '../../widgets/neo_button.dart';
import '../../widgets/neo_text_field.dart';
import '../../../domain/entities/loan_case.dart';
import '../../../domain/entities/customer.dart';
import '../../providers/loan_case_provider.dart';
import '../../providers/customer_provider.dart';

class CreateLoanCaseScreen extends ConsumerStatefulWidget {
  const CreateLoanCaseScreen({super.key});

  @override
  ConsumerState<CreateLoanCaseScreen> createState() => _CreateLoanCaseScreenState();
}

class _CreateLoanCaseScreenState extends ConsumerState<CreateLoanCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  Customer? _selectedCustomer;
  String? _selectedLoanType;
  final _amountController = TextEditingController();

  final List<String> _loanTypes = [
    'Business Loan',
    'MSME Loan',
    'Personal Loan',
    'Home Loan',
    'Vehicle Loan',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _saveCase() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedCustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a customer')),
        );
        return;
      }
      if (_selectedLoanType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a loan type')),
        );
        return;
      }

      final amount = double.tryParse(_amountController.text) ?? 0.0;

      final newCase = LoanCase(
        id: 'LD-${DateTime.now().year}-${const Uuid().v4().substring(0, 6).toUpperCase()}',
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.name,
        loanType: _selectedLoanType!,
        amount: amount,
        status: 'Documents Pending',
        applicationDate: DateTime.now(),
      );

      ref.read(loanCaseProvider.notifier).addLoanCase(newCase);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Loan Case created successfully!', style: TextStyle(fontWeight: FontWeight.bold, color: LoanDeskTheme.primaryBlack)),
          backgroundColor: LoanDeskTheme.primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius),
            side: const BorderSide(color: LoanDeskTheme.primaryBlack, width: LoanDeskTheme.borderWidth),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );

      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customerProvider);

    return Scaffold(
      backgroundColor: LoanDeskTheme.background,
      appBar: AppBar(
        backgroundColor: LoanDeskTheme.primaryWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: LoanDeskTheme.primaryBlack),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Create Loan Case',
          style: TextStyle(
            color: LoanDeskTheme.primaryBlack,
            fontWeight: FontWeight.w900,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: LoanDeskTheme.primaryBlack,
            height: LoanDeskTheme.borderWidth,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Case Details',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Customer *',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    TextButton.icon(
                      onPressed: () => context.push('/loandesk/customers/add'),
                      icon: const Icon(Icons.add, size: 16, color: LoanDeskTheme.primaryBlue),
                      label: const Text(
                        'New Customer',
                        style: TextStyle(color: LoanDeskTheme.primaryBlue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildCustomerDropdown(customers),
                
                const SizedBox(height: 24),
                const Text(
                  'Loan Type *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                _buildLoanTypeDropdown(),
                
                const SizedBox(height: 24),
                NeoTextField(
                  label: 'Loan Amount (₹) *',
                  keyboardType: TextInputType.number,
                  controller: _amountController,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Amount is required';
                    if (double.tryParse(value) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                NeoButton(
                  text: 'CREATE CASE',
                  isFullWidth: true,
                  color: LoanDeskTheme.primaryYellow,
                  onPressed: _saveCase,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerDropdown(List<Customer> customers) {
    return Container(
      decoration: BoxDecoration(
        color: LoanDeskTheme.primaryWhite,
        borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius),
        border: Border.all(
          color: LoanDeskTheme.primaryBlack,
          width: LoanDeskTheme.borderWidth,
        ),
        boxShadow: const [
          BoxShadow(
            color: LoanDeskTheme.primaryBlack,
            offset: Offset(LoanDeskTheme.shadowOffset, LoanDeskTheme.shadowOffset),
          ),
        ],
      ),
      child: DropdownButtonFormField<Customer>(
        value: _selectedCustomer,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        hint: const Text('Select a customer'),
        items: customers.map((customer) {
          return DropdownMenuItem(
            value: customer,
            child: Text('${customer.name} (${customer.panNumber})'),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedCustomer = value;
          });
        },
      ),
    );
  }

  Widget _buildLoanTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: LoanDeskTheme.primaryWhite,
        borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius),
        border: Border.all(
          color: LoanDeskTheme.primaryBlack,
          width: LoanDeskTheme.borderWidth,
        ),
        boxShadow: const [
          BoxShadow(
            color: LoanDeskTheme.primaryBlack,
            offset: Offset(LoanDeskTheme.shadowOffset, LoanDeskTheme.shadowOffset),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedLoanType,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        hint: const Text('Select loan type'),
        items: _loanTypes.map((type) {
          return DropdownMenuItem(
            value: type,
            child: Text(type),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedLoanType = value;
          });
        },
      ),
    );
  }
}
