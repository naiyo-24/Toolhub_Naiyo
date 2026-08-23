import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/features/loandesk/presentation/theme/loandesk_theme.dart';
import 'package:tool_hub/features/loandesk/presentation/widgets/neo_button.dart';
import 'package:tool_hub/features/loandesk/presentation/widgets/neo_text_field.dart';
import 'package:tool_hub/features/loandesk/presentation/providers/banker_profile_provider.dart';

class BankerProfileTab extends ConsumerStatefulWidget {
  const BankerProfileTab({super.key});

  @override
  ConsumerState<BankerProfileTab> createState() => _BankerProfileTabState();
}

class _BankerProfileTabState extends ConsumerState<BankerProfileTab> {
  final _formKey = GlobalKey<FormState>();

  final _designationController = TextEditingController();
  final _orgNameController = TextEditingController();
  final _branchController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _mobileController = TextEditingController();
  final _experienceController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _loanTypesController = TextEditingController();

  bool _isEditing = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _designationController.dispose();
    _orgNameController.dispose();
    _branchController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _mobileController.dispose();
    _experienceController.dispose();
    _employeeIdController.dispose();
    _loanTypesController.dispose();
    super.dispose();
  }

  void _populateFields(BankerProfile? profile) {
    if (profile == null) return;
    _designationController.text = profile.designation ?? '';
    _orgNameController.text = profile.orgName ?? '';
    _branchController.text = profile.branchName ?? '';
    _cityController.text = profile.city ?? '';
    _stateController.text = profile.stateRegion ?? '';
    _mobileController.text = profile.mobile ?? '';
    _experienceController.text = profile.experienceYears?.toString() ?? '';
    _employeeIdController.text = profile.employeeId ?? '';
    _loanTypesController.text = profile.loanTypes ?? '';
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedProfile = BankerProfile(
        designation: _designationController.text,
        orgName: _orgNameController.text,
        branchName: _branchController.text,
        city: _cityController.text,
        stateRegion: _stateController.text,
        mobile: _mobileController.text,
        experienceYears: int.tryParse(_experienceController.text),
        employeeId: _employeeIdController.text,
        loanTypes: _loanTypesController.text,
        role: 'Banker', // Default role
        orgType: 'Bank', // Default org type
      );

      try {
        await ref.read(bankerProfileProvider.notifier).updateProfile(updatedProfile);
        setState(() {
          _isEditing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile saved successfully!', style: TextStyle(color: LoanDeskTheme.primaryBlack, fontWeight: FontWeight.bold)),
              backgroundColor: LoanDeskTheme.primaryGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius),
                side: const BorderSide(color: LoanDeskTheme.primaryBlack, width: LoanDeskTheme.borderWidth),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save profile: $e'),
              backgroundColor: LoanDeskTheme.primaryRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(bankerProfileProvider);

    return Scaffold(
      backgroundColor: LoanDeskTheme.background,
      appBar: AppBar(
        backgroundColor: LoanDeskTheme.primaryWhite,
        elevation: 0,
        title: const Text(
          'Banker Profile',
          style: TextStyle(
            color: LoanDeskTheme.primaryBlack,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          if (profileState.valueOrNull != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: LoanDeskTheme.primaryBlack),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: LoanDeskTheme.primaryBlack,
            height: LoanDeskTheme.borderWidth,
          ),
        ),
      ),
      body: profileState.when(
        data: (profile) {
          if (!_isInitialized) {
            _populateFields(profile);
            // If profile is null, force edit mode to create one
            if (profile == null) _isEditing = true;
            _isInitialized = true;
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Professional Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 16),
                    NeoTextField(
                      label: 'Designation',
                      controller: _designationController,
                      readOnly: !_isEditing,
                      validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    NeoTextField(
                      label: 'Organization Name',
                      controller: _orgNameController,
                      readOnly: !_isEditing,
                      validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    NeoTextField(
                      label: 'Employee ID',
                      controller: _employeeIdController,
                      readOnly: !_isEditing,
                    ),
                    const SizedBox(height: 16),
                    NeoTextField(
                      label: 'Experience (Years)',
                      controller: _experienceController,
                      keyboardType: TextInputType.number,
                      readOnly: !_isEditing,
                    ),
                    const SizedBox(height: 32),
                    
                    const Text('Location Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 16),
                    NeoTextField(
                      label: 'Branch Name',
                      controller: _branchController,
                      readOnly: !_isEditing,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: NeoTextField(
                            label: 'City',
                            controller: _cityController,
                            readOnly: !_isEditing,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: NeoTextField(
                            label: 'State',
                            controller: _stateController,
                            readOnly: !_isEditing,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    const Text('Contact & Portfolio', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 16),
                    NeoTextField(
                      label: 'Mobile No.',
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      readOnly: !_isEditing,
                    ),
                    const SizedBox(height: 16),
                    NeoTextField(
                      label: 'Specialized Loan Types (e.g. Home, Business)',
                      controller: _loanTypesController,
                      readOnly: !_isEditing,
                    ),
                    const SizedBox(height: 32),

                    if (_isEditing)
                      Row(
                        children: [
                          if (profile != null)
                            Expanded(
                              child: NeoButton(
                                text: 'Cancel',
                                color: LoanDeskTheme.primaryWhite,
                                onPressed: () {
                                  setState(() {
                                    _isEditing = false;
                                    _populateFields(profile);
                                  });
                                },
                              ),
                            ),
                          if (profile != null) const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: NeoButton(
                              text: 'Save Profile',
                              color: LoanDeskTheme.primaryYellow,
                              onPressed: _saveProfile,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: LoanDeskTheme.primaryBlue)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
