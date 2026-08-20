import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/loandesk_theme.dart';
import '../../widgets/neo_button.dart';
import '../../widgets/neo_card.dart';
import '../../widgets/neo_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';

class OnboardingWizardScreen extends ConsumerStatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  ConsumerState<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends ConsumerState<OnboardingWizardScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  final _personalFormKey = GlobalKey<FormState>();
  final _professionalFormKey = GlobalKey<FormState>();
  final _orgFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(onboardingProvider.notifier).updateField(
          fullName: user.name,
          email: user.email,
        );
      }
    });
  }

  Future<void> _nextPage() async {
    bool canProceed = true;

    if (_currentPage == 0) {
      canProceed = _personalFormKey.currentState?.validate() ?? false;
    } else if (_currentPage == 1) {
      canProceed = _professionalFormKey.currentState?.validate() ?? false;
    } else if (_currentPage == 2) {
      canProceed = _orgFormKey.currentState?.validate() ?? false;
    }

    if (!canProceed) return;

    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      final state = ref.read(onboardingProvider);
      final profileData = {
        'full_name': state.fullName,
        'mobile': state.mobileNumber,
        'date_of_birth': state.dateOfBirth?.toIso8601String(),
        'role': state.role,
        'designation': state.designation,
        'experience_years': state.experience,
        'employee_id': state.employeeId,
        'org_type': state.orgType,
        'org_name': state.orgName,
        'branch_name': state.branchName,
        'city': state.city,
        'state_region': state.state,
        'loan_types': state.loanTypes,
        'is_profile_complete': true,
      };
      
      try {
        await ref.read(authProvider.notifier).completeProfile(profileData);
        if (mounted) {
          context.pushReplacement('/loandesk/dashboard');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving profile: $e')),
          );
        }
      }
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _prevPage();
      },
      child: Scaffold(
        backgroundColor: LoanDeskTheme.background,
      appBar: AppBar(
        backgroundColor: LoanDeskTheme.primaryWhite,
        elevation: 0,
        title: const Text(
          'Complete Profile',
          style: TextStyle(
            color: LoanDeskTheme.primaryBlack,
            fontWeight: FontWeight.w900,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: (_currentPage + 1) / _totalPages,
            backgroundColor: LoanDeskTheme.background,
            color: LoanDeskTheme.primaryBlue,
            minHeight: 4,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildPersonalInfoStep(),
                  _buildProfessionalInfoStep(),
                  _buildOrganizationStep(),
                  _buildPreferencesStep(),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: LoanDeskTheme.primaryWhite,
                border: Border(
                  top: BorderSide(
                    color: LoanDeskTheme.primaryBlack,
                    width: LoanDeskTheme.borderWidth,
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (_currentPage > 0) ...[
                    Expanded(
                      flex: 1,
                      child: NeoButton(
                        text: 'BACK',
                        color: LoanDeskTheme.primaryWhite,
                        onPressed: _prevPage,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    flex: 2,
                    child: NeoButton(
                      text: _currentPage == _totalPages - 1 ? 'COMPLETE & ENTER' : 'CONTINUE',
                      color: LoanDeskTheme.primaryYellow,
                      onPressed: _nextPage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: LoanDeskTheme.primaryBlack,
          ),
        ),
        const SizedBox(height: 8),
        Container(
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
            value: value.isNotEmpty ? value : items.first,
            onChanged: onChanged,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: LoanDeskTheme.primaryBlack,
                  ),
                ),
              );
            }).toList(),
            decoration: const InputDecoration(
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoStep() {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _personalFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 24),
            NeoCard(
              child: Column(
                children: [
                  NeoTextField(
                    label: 'Full Name *',
                    controller: TextEditingController(text: state.fullName)..selection = TextSelection.collapsed(offset: state.fullName.length),
                    onChanged: (v) => notifier.updateField(fullName: v),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  NeoTextField(
                    label: 'Mobile Number *',
                    keyboardType: TextInputType.phone,
                    controller: TextEditingController(text: state.mobileNumber)..selection = TextSelection.collapsed(offset: state.mobileNumber.length),
                    onChanged: (v) => notifier.updateField(mobileNumber: v),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  NeoTextField(
                    label: 'Email *',
                    keyboardType: TextInputType.emailAddress,
                    controller: TextEditingController(text: state.email)..selection = TextSelection.collapsed(offset: state.email.length),
                    onChanged: (v) => notifier.updateField(email: v),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('Date of Birth (Optional)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) notifier.updateField(dateOfBirth: date);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: LoanDeskTheme.primaryWhite,
                        border: Border.all(color: LoanDeskTheme.primaryBlack, width: LoanDeskTheme.borderWidth),
                        borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius),
                        boxShadow: const [
                          BoxShadow(color: LoanDeskTheme.primaryBlack, offset: Offset(LoanDeskTheme.shadowOffset, LoanDeskTheme.shadowOffset)),
                        ],
                      ),
                      child: Text(
                        state.dateOfBirth == null ? 'Select Date' : '${state.dateOfBirth!.day}/${state.dateOfBirth!.month}/${state.dateOfBirth!.year}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalInfoStep() {
    final state = ref.watch(onboardingProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _professionalFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Professional Information',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 24),
            NeoCard(
              child: Column(
                children: [
                  _buildDropdown(
                    label: 'Role *',
                    value: state.role,
                    items: ['Bank Manager', 'Loan Officer', 'Credit Officer', 'Relationship Manager', 'Banking Executive', 'DSA / Loan Agent', 'Financial Advisor', 'Other'],
                    onChanged: (v) => ref.read(onboardingProvider.notifier).updateField(role: v),
                  ),
                  const SizedBox(height: 16),
                  NeoTextField(
                    label: 'Designation *',
                    hint: 'e.g. Senior Officer',
                    controller: TextEditingController(text: state.designation)..selection = TextSelection.collapsed(offset: state.designation.length),
                    onChanged: (v) => ref.read(onboardingProvider.notifier).updateField(designation: v),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  NeoTextField(
                    label: 'Years of Experience',
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: state.experience)..selection = TextSelection.collapsed(offset: state.experience.length),
                    onChanged: (v) => ref.read(onboardingProvider.notifier).updateField(experience: v),
                  ),
                  const SizedBox(height: 16),
                  NeoTextField(
                    label: 'Employee / Agent ID (Optional)',
                    hint: 'EMP-1234',
                    controller: TextEditingController(text: state.employeeId)..selection = TextSelection.collapsed(offset: state.employeeId.length),
                    onChanged: (v) => ref.read(onboardingProvider.notifier).updateField(employeeId: v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizationStep() {
    final state = ref.watch(onboardingProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _orgFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Organization Profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 24),
            NeoCard(
              child: Column(
                children: [
                  _buildDropdown(
                    label: 'Organization Type *',
                    value: state.orgType,
                    items: ['Bank', 'NBFC', 'Fintech', 'Cooperative Bank', 'Microfinance', 'DSA', 'Loan Consultancy', 'Other'],
                    onChanged: (v) => ref.read(onboardingProvider.notifier).updateField(orgType: v),
                  ),
                  const SizedBox(height: 16),
                  NeoTextField(
                    label: 'Organization Name *',
                    controller: TextEditingController(text: state.orgName)..selection = TextSelection.collapsed(offset: state.orgName.length),
                    onChanged: (v) => ref.read(onboardingProvider.notifier).updateField(orgName: v),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  NeoTextField(
                    label: 'Branch Name *',
                    controller: TextEditingController(text: state.branchName)..selection = TextSelection.collapsed(offset: state.branchName.length),
                    onChanged: (v) => ref.read(onboardingProvider.notifier).updateField(branchName: v),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: NeoTextField(
                          label: 'City',
                          controller: TextEditingController(text: state.city)..selection = TextSelection.collapsed(offset: state.city.length),
                          onChanged: (v) => ref.read(onboardingProvider.notifier).updateField(city: v),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: NeoTextField(
                          label: 'State',
                          controller: TextEditingController(text: state.state)..selection = TextSelection.collapsed(offset: state.state.length),
                          onChanged: (v) => ref.read(onboardingProvider.notifier).updateField(state: v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesStep() {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    
    final loanTypes = ['Personal', 'Business', 'MSME', 'Home', 'Vehicle', 'Education', 'Working Capital', 'Other'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Work Preferences',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 24),
          NeoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('What type of loans do you handle?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: loanTypes.map((type) {
                    final isSelected = state.loanTypes.contains(type);
                    return InkWell(
                      onTap: () => notifier.toggleLoanType(type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? LoanDeskTheme.primaryBlue : LoanDeskTheme.primaryWhite,
                          borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius),
                          border: Border.all(color: LoanDeskTheme.primaryBlack, width: 2),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? LoanDeskTheme.primaryWhite : LoanDeskTheme.primaryBlack,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Text('Default Currency', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: LoanDeskTheme.primaryWhite,
                    border: Border.all(color: LoanDeskTheme.primaryBlack, width: 2),
                    borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius),
                  ),
                  child: const Text('₹ INR', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
