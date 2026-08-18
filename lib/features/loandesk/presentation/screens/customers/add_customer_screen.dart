import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../theme/loandesk_theme.dart';
import '../../widgets/neo_button.dart';
import '../../widgets/neo_text_field.dart';
import '../../../domain/entities/customer.dart';
import '../../providers/customer_provider.dart';

class AddCustomerScreen extends ConsumerStatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _panController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _panController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveCustomer() {
    if (_formKey.currentState?.validate() ?? false) {
      final newCustomer = Customer(
        id: 'CUST-${const Uuid().v4().substring(0, 6).toUpperCase()}',
        name: _nameController.text,
        panNumber: _panController.text,
        phoneNumber: _phoneController.text,
        email: _emailController.text,
        address: _addressController.text,
        createdDate: DateTime.now(),
      );

      ref.read(customerProvider.notifier).addCustomer(newCustomer);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Customer added successfully!', style: TextStyle(fontWeight: FontWeight.bold, color: LoanDeskTheme.primaryBlack)),
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
          'Add New Customer',
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
                  'Customer Details',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 24),
                NeoTextField(
                  label: 'Full Name *',
                  controller: _nameController,
                  validator: (value) => value == null || value.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                NeoTextField(
                  label: 'PAN Number *',
                  controller: _panController,
                  validator: (value) => value == null || value.isEmpty ? 'PAN is required' : null,
                ),
                const SizedBox(height: 16),
                NeoTextField(
                  label: 'Mobile Number *',
                  keyboardType: TextInputType.phone,
                  controller: _phoneController,
                  validator: (value) => value == null || value.isEmpty ? 'Phone is required' : null,
                ),
                const SizedBox(height: 16),
                NeoTextField(
                  label: 'Email Address',
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                ),
                const SizedBox(height: 16),
                NeoTextField(
                  label: 'Residential Address',
                  controller: _addressController,
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                NeoButton(
                  text: 'SAVE CUSTOMER',
                  isFullWidth: true,
                  color: LoanDeskTheme.primaryYellow,
                  onPressed: _saveCustomer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
