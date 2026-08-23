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
  
  bool _isNewCustomer = true;
  Customer? _selectedCustomer;

  final List<String> _customerTypes = ['Proprietorship', 'Partnership', 'Private Limited', 'Public Limited', 'HUF', 'Individual'];
  final List<String> _loanTypes = ['Business Loan', 'MSME Loan', 'Personal Loan', 'Home Loan', 'Vehicle Loan'];

  String? _selectedCustomerType;
  String? _selectedBusinessType;
  String? _selectedLoanType;

  final _customerNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _panController = TextEditingController();
  final _gstinController = TextEditingController();
  final _cinController = TextEditingController();
  final _amountController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _tenureController = TextEditingController();
  final _panSearchController = TextEditingController();
  final _dobController = TextEditingController();
  final _occupationController = TextEditingController();
  final _addressController = TextEditingController();
  final _legalNameController = TextEditingController();
  final _udyamNumberController = TextEditingController();

  @override
  void dispose() {
    _customerNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _businessNameController.dispose();
    _panController.dispose();
    _gstinController.dispose();
    _cinController.dispose();
    _amountController.dispose();
    _interestRateController.dispose();
    _tenureController.dispose();
    _panSearchController.dispose();
    _dobController.dispose();
    _occupationController.dispose();
    _addressController.dispose();
    _legalNameController.dispose();
    _udyamNumberController.dispose();
    super.dispose();
  }

  void _onCustomerSelected(Customer? customer) {
    setState(() {
      _selectedCustomer = customer;
      if (customer != null) {
        _customerNameController.text = customer.name;
        _mobileController.text = customer.phoneNumber;
        _emailController.text = customer.email;
        _panController.text = customer.panNumber;
        _dobController.text = customer.dob != null ? "${customer.dob!.day}/${customer.dob!.month}/${customer.dob!.year}" : '';
        _occupationController.text = customer.occupation ?? '';
        _addressController.text = customer.address;
        _legalNameController.text = customer.legalName ?? '';
        _udyamNumberController.text = customer.udyamNumber ?? '';
        _selectedCustomerType = 'Individual';
        _selectedBusinessType = customer.businessType ?? 'Individual';
        _businessNameController.text = customer.businessName ?? '${customer.name} Enterprise';
        _gstinController.text = customer.gstin ?? '';
        _cinController.text = '';
      } else {
        _clearForm();
      }
    });
  }

  void _clearForm() {
    _customerNameController.clear();
    _mobileController.clear();
    _emailController.clear();
    _businessNameController.clear();
    _panController.clear();
    _gstinController.clear();
    _cinController.clear();
    _dobController.clear();
    _occupationController.clear();
    _addressController.clear();
    _legalNameController.clear();
    _udyamNumberController.clear();
    _selectedCustomerType = null;
    _selectedBusinessType = null;
  }

  Future<void> _saveCase() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedLoanType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a loan type')),
        );
        return;
      }
      
      if (_selectedCustomerType == null || _selectedBusinessType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select Customer Type and Business Type')),
        );
        return;
      }

      String customerId;
      String customerName = _customerNameController.text;

      String? formattedDob;
      if (_dobController.text.isNotEmpty) {
        final parts = _dobController.text.split('/');
        if (parts.length == 3) {
          // Assuming input is DD/MM/YYYY
          formattedDob = '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
        } else {
          formattedDob = _dobController.text;
        }
      }

      try {
        // Handle New Customer Saving
        if (_isNewCustomer) {
          final newCustomerData = {
            'name': customerName,
            'pan': _panController.text,
            'phone': _mobileController.text,
            'email': _emailController.text,
            'address': _addressController.text.isNotEmpty ? _addressController.text : 'Not Provided',
            'dob': formattedDob,
            'occupation': _occupationController.text,
            'legal_name': _legalNameController.text,
            'business_name': _businessNameController.text,
            'business_type': _selectedBusinessType,
            'udyam_number': _udyamNumberController.text,
            'gstin': _gstinController.text,
          };
          final newCustomer = await ref.read(customerProvider.notifier).addCustomer(newCustomerData);
          customerId = newCustomer.id;
        } else {
          if (_selectedCustomer == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select an existing customer')),
            );
            return;
          }
          customerId = _selectedCustomer!.id;
        }

        final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
        
        final interestRate = double.tryParse(_interestRateController.text) ?? 0.0;
        final tenureMonths = int.tryParse(_tenureController.text) ?? 0;
        
        final rawDetails = {
          'customerType': _selectedCustomerType,
          'customerName': customerName,
          'mobileNo': _mobileController.text,
          'email': _emailController.text,
          'dob': formattedDob,
          'occupation': _occupationController.text,
          'address': _addressController.text,
          'legalName': _legalNameController.text,
          'businessName': _businessNameController.text,
          'businessType': _selectedBusinessType,
          'udyamNumber': _udyamNumberController.text,
          'pan': _panController.text,
          'gstin': _gstinController.text,
          'cin': _cinController.text,
          'interest_rate': interestRate,
          'tenure_months': tenureMonths,
        };

        final newCaseData = {
          'customer_id': customerId,
          'customer_name': customerName,
          'loan_type': _selectedLoanType!,
          'requested_amount': amount,
          'interest_rate': interestRate,
          'tenure_months': tenureMonths,
          'status': 'Documents Pending',
          'raw_details': rawDetails,
        };

        final newCase = await ref.read(loanCaseProvider.notifier).addLoanCase(newCaseData);
        
        if (mounted) {
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

          context.pushReplacement('/loandesk/cases/workspace/${newCase.id}');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving case: $e', style: const TextStyle(fontWeight: FontWeight.bold, color: LoanDeskTheme.primaryWhite)),
              backgroundColor: LoanDeskTheme.primaryRed,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersState = ref.watch(customerProvider);
    final customers = customersState.value ?? [];
    final bool readOnly = !_isNewCustomer;

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
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTypeToggle(),
                const SizedBox(height: 24),
                
                if (!_isNewCustomer) ...[
                  _buildPanSearchField(customers),
                  const SizedBox(height: 24),
                ],

                const Text('Basic Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                
                _buildDropdownField('Customer Type *', _customerTypes, _selectedCustomerType, (val) {
                  if(!readOnly) setState(() => _selectedCustomerType = val);
                }),
                const SizedBox(height: 16),
                
                NeoTextField(
                  label: 'Customer Name *',
                  controller: _customerNameController,
                  readOnly: readOnly,
                  validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                NeoTextField(
                  label: 'Mobile No *',
                  keyboardType: TextInputType.phone,
                  controller: _mobileController,
                  readOnly: readOnly,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    if (val.length != 10) return 'Must be exactly 10 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                NeoTextField(
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                  readOnly: readOnly,
                ),
                const SizedBox(height: 16),
                
                NeoTextField(
                  label: 'DOB (DD/MM/YYYY)',
                  controller: _dobController,
                  readOnly: readOnly,
                ),
                const SizedBox(height: 16),
                
                NeoTextField(
                  label: 'Occupation',
                  controller: _occupationController,
                  readOnly: readOnly,
                ),
                const SizedBox(height: 16),
                
                NeoTextField(
                  label: 'Address',
                  controller: _addressController,
                  readOnly: readOnly,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                
                NeoTextField(
                  label: 'Legal Name',
                  controller: _legalNameController,
                  readOnly: readOnly,
                ),
                const SizedBox(height: 16),
                
                NeoTextField(
                  label: 'Business Name *',
                  controller: _businessNameController,
                  readOnly: readOnly,
                  validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                _buildDropdownField('Business Type *', _customerTypes, _selectedBusinessType, (val) {
                  if(!readOnly) setState(() => _selectedBusinessType = val);
                }),
                const SizedBox(height: 16),

                NeoTextField(
                  label: 'PAN *',
                  controller: _panController,
                  readOnly: readOnly,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    if (val.length != 10) return 'Must be exactly 10 chars';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                NeoTextField(
                  label: 'GSTIN',
                  controller: _gstinController,
                  readOnly: readOnly,
                  validator: (val) {
                    if (val != null && val.isNotEmpty && val.length != 15) return 'Must be 15 chars';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                NeoTextField(
                  label: 'CIN/LLPIN',
                  controller: _cinController,
                  readOnly: readOnly,
                  validator: (val) {
                    if (val != null && val.isNotEmpty && val.length != 7 && val.length != 21) {
                      return 'Must be 7 (LLPIN) or 21 (CIN) chars';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                NeoTextField(
                  label: 'Udyam Number',
                  controller: _udyamNumberController,
                  readOnly: readOnly,
                  validator: (val) {
                    if (val != null && val.isNotEmpty && val.length != 16 && val.length != 19) {
                      return 'Must be 16 or 19 (with hyphens) chars';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 32),
                const Text('Loan Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                
                _buildDropdownField('Loan Type *', _loanTypes, _selectedLoanType, (val) {
                  setState(() => _selectedLoanType = val);
                }),
                const SizedBox(height: 16),
                
                NeoTextField(
                  label: 'Loan Amount (₹) *',
                  keyboardType: TextInputType.number,
                  controller: _amountController,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Amount is required';
                    if (double.tryParse(value.replaceAll(',', '')) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: NeoTextField(
                        label: 'Interest Rate (%)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        controller: _interestRateController,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: NeoTextField(
                        label: 'Tenure (Months)',
                        keyboardType: TextInputType.number,
                        controller: _tenureController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                Row(
                  children: [
                    Expanded(
                      child: NeoButton(
                        text: 'Cancel',
                        color: LoanDeskTheme.primaryWhite,
                        onPressed: () => context.pop(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: NeoButton(
                        text: 'Save & Continue',
                        color: LoanDeskTheme.primaryYellow,
                        onPressed: _saveCase,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: LoanDeskTheme.primaryWhite,
        borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius),
        border: Border.all(color: LoanDeskTheme.primaryBlack, width: LoanDeskTheme.borderWidth),
        boxShadow: const [
          BoxShadow(
            color: LoanDeskTheme.primaryBlack,
            offset: Offset(LoanDeskTheme.shadowOffset, LoanDeskTheme.shadowOffset),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isNewCustomer = true;
                  _selectedCustomer = null;
                  _clearForm();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _isNewCustomer ? LoanDeskTheme.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(LoanDeskTheme.borderRadius - 2)),
                ),
                child: Text(
                  'New Customer',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _isNewCustomer ? LoanDeskTheme.primaryWhite : LoanDeskTheme.primaryBlack,
                  ),
                ),
              ),
            ),
          ),
          Container(width: LoanDeskTheme.borderWidth, color: LoanDeskTheme.primaryBlack, height: 50),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isNewCustomer = false;
                  _clearForm();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: !_isNewCustomer ? LoanDeskTheme.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.horizontal(right: Radius.circular(LoanDeskTheme.borderRadius - 2)),
                ),
                child: Text(
                  'Existing Customer',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: !_isNewCustomer ? LoanDeskTheme.primaryWhite : LoanDeskTheme.primaryBlack,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> items, String? value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: LoanDeskTheme.primaryBlack),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: LoanDeskTheme.primaryWhite,
            borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius),
            border: Border.all(color: LoanDeskTheme.primaryBlack, width: LoanDeskTheme.borderWidth),
            boxShadow: const [
              BoxShadow(
                color: LoanDeskTheme.primaryBlack,
                offset: Offset(LoanDeskTheme.shadowOffset, LoanDeskTheme.shadowOffset),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            hint: const Text('Select'),
            items: items.map((item) {
              return DropdownMenuItem(value: item, child: Text(item));
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildPanSearchField(List<Customer> customers) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: NeoTextField(
            label: 'Enter PAN Number *',
            controller: _panSearchController,
            hint: 'e.g. ABCDE1234F',
          ),
        ),
        const SizedBox(width: 16),
        NeoButton(
          text: 'Search',
          color: LoanDeskTheme.primaryBlue,
          onPressed: () {
            final query = _panSearchController.text.trim().toUpperCase();
            if (query.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a PAN number')),
              );
              return;
            }
            
            try {
              final customer = customers.firstWhere((c) => c.panNumber.toUpperCase() == query);
              _onCustomerSelected(customer);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Found ${customer.name}'),
                  backgroundColor: LoanDeskTheme.primaryGreen,
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Customer not found with this PAN'),
                  backgroundColor: LoanDeskTheme.primaryRed,
                ),
              );
              _onCustomerSelected(null);
            }
          },
        ),
      ],
    );
  }
}
