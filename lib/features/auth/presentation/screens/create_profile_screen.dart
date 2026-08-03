import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/neo_card.dart';
import '../../../../core/api/api_config.dart';
import '../providers/auth_provider.dart';
import '../../../../features/tools/business_toolkit/presentation/providers/business_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreateProfileScreen extends ConsumerStatefulWidget {
  final bool isEditing;
  const CreateProfileScreen({super.key, this.isEditing = false});

  @override
  ConsumerState<CreateProfileScreen> createState() =>
      _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _businessType = 'Retailer';
  String _pricingMode = 'EXCLUSIVE';
  String _userEmail = '';

  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstController = TextEditingController();

  String? _companyLogoUrl;
  bool _isUploadingLogo = false;

  final _bankNameController = TextEditingController();
  final _accHolderController = TextEditingController();
  final _accNumberController = TextEditingController();
  final _ifscController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = prefs.getString('user_email') ?? '';
    });

    if (widget.isEditing) {
      await _fetchProfileFromServer(prefs);
    }
  }

  Future<void> _fetchProfileFromServer(SharedPreferences prefs) async {
    // First load from prefs as a quick fallback
    setState(() {
      _companyNameController.text = prefs.getString('company_name') ?? '';
      _companyAddressController.text = prefs.getString('company_address') ?? '';
      _phoneController.text = prefs.getString('phone_number') ?? '';
      _whatsappController.text = prefs.getString('whatsapp_number') ?? '';
      _gstController.text = prefs.getString('gst_number') ?? '';
      _businessType = prefs.getString('business_type') ?? 'Retailer';
      String? logo = prefs.getString('company_logo_url');
      if (logo != null) {
        // Always extract just the path (e.g., /uploads/...) so it dynamically uses the current IP
        if (logo.contains('/uploads/')) {
          logo = logo.substring(logo.indexOf('/uploads/'));
        }
      }
      _companyLogoUrl = logo;
      _bankNameController.text = prefs.getString('bank_name') ?? '';
      _accHolderController.text = prefs.getString('account_name') ?? '';
      _accNumberController.text = prefs.getString('account_number') ?? '';
      _ifscController.text = prefs.getString('ifsc_code') ?? '';
    });

    try {
      final token = prefs.getString('auth_token');
      if (token != null) {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/auth/profile'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (mounted) {
            setState(() {
              _companyNameController.text =
                  data['company_name'] ?? _companyNameController.text;
              _companyAddressController.text =
                  data['company_address'] ?? _companyAddressController.text;
              _phoneController.text =
                  data['phone_number'] ?? _phoneController.text;
              _whatsappController.text =
                  data['whatsapp_number'] ?? _whatsappController.text;
              _gstController.text = data['gst_number'] ?? _gstController.text;
              if (data['business_type'] != null &&
                  data['business_type'].toString().isNotEmpty) {
                _businessType = data['business_type'];
                // Update prefs so next time it loads faster
                prefs.setString('business_type', _businessType);
              }
              if (data['pricing_mode'] != null && data['pricing_mode'].toString().isNotEmpty) {
                String pm = data['pricing_mode'];
                if (pm == 'INCLUSIVE') pm = 'EXCLUSIVE';
                _pricingMode = pm;
                prefs.setString('pricing_mode', _pricingMode);
              }
              _bankNameController.text = data['bank_name'] ?? '';
              _accHolderController.text = data['account_name'] ?? '';
              _accNumberController.text = data['account_number'] ?? '';
              _ifscController.text = data['ifsc_code'] ?? '';
              
              if (data['company_logo_url'] != null) {
                String fetchedLogo = data['company_logo_url'];
                if (fetchedLogo.contains('/uploads/')) {
                  fetchedLogo = fetchedLogo.substring(fetchedLogo.indexOf('/uploads/'));
                }
                _companyLogoUrl = fetchedLogo;
                prefs.setString('company_logo_url', fetchedLogo);
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch profile from server: $e");
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _whatsappController.dispose();
    _phoneController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null) {
        final response = await http.put(
          Uri.parse('${ApiConfig.baseUrl}/auth/profile'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'company_name': _companyNameController.text,
            'company_logo_url': _companyLogoUrl,
            'company_address': _companyAddressController.text,
            'whatsapp_number': _whatsappController.text,
            'phone_number': _phoneController.text,
            'gst_number': _gstController.text,
            'business_type': _businessType,
            'pricing_mode': _pricingMode,
            'bank_name': _bankNameController.text,
            'account_name': _accHolderController.text,
            'account_number': _accNumberController.text,
            'ifsc_code': _ifscController.text,
          }),
        );

        if (response.statusCode == 200) {
          await prefs.setString('company_name', _companyNameController.text);
          await prefs.setString(
              'company_address', _companyAddressController.text);
          await prefs.setString('phone_number', _phoneController.text);
          await prefs.setString('whatsapp_number', _whatsappController.text);
          await prefs.setString('gst_number', _gstController.text);
          await prefs.setString('business_type', _businessType);
          await prefs.setString('pricing_mode', _pricingMode);
          if (_companyLogoUrl != null) {
            await prefs.setString('company_logo_url', _companyLogoUrl!);
          } else {
            await prefs.remove('company_logo_url');
          }
          await prefs.setString('bank_name', _bankNameController.text);
          await prefs.setString('account_name', _accHolderController.text);
          await prefs.setString('account_number', _accNumberController.text);
          await prefs.setString('ifsc_code', _ifscController.text);

          if (mounted) {
            if (widget.isEditing) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Profile updated successfully!')));
              context.pop();
            } else {
              context.pushReplacement('/business-toolkit');
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Failed to update profile: ${response.body}')),
            );
          }
        }
      } else {
        // Fallback for mocked mode or offline
        if (mounted) context.pushReplacement('/business-toolkit');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.isEditing,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!widget.isEditing) {
          await ref.read(authProvider.notifier).signOut();
          if (context.mounted) {
            context.go('/');
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Edit Profile' : 'Business Profile',
              style: AppTextStyles.screenHeading),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: widget.isEditing,
          leading: widget.isEditing
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () async {
                    await ref.read(authProvider.notifier).signOut();
                    if (context.mounted) {
                      context.go('/');
                    }
                  },
                ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NeoCard(
                  backgroundColor: AppColors.primaryYellow,
                  child: Column(
                    children: [
                      Text(
                        'Complete Your Profile',
                        style: AppTextStyles.heroTitle
                            .copyWith(fontSize: 24, color: Colors.black),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please provide your business details.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyText
                            .copyWith(color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_userEmail.isNotEmpty) ...[
                  TextFormField(
                    key: const ValueKey('email_field'),
                    initialValue: _userEmail,
                    enabled: false,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black54),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: const TextStyle(color: Colors.black54),
                      prefixIcon:
                          const Icon(Icons.email, color: Colors.black54),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.black, width: 2),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.black26, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_companyLogoUrl != null)
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300, width: 2),
                            image: DecorationImage(
                              image: NetworkImage(
                                  _companyLogoUrl!.startsWith('http') ? _companyLogoUrl! : '${ApiConfig.baseUrl}$_companyLogoUrl'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () => setState(() => _companyLogoUrl = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final picked =
                            await picker.pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          setState(() => _isUploadingLogo = true);
                          try {
                            final url = await ref
                                .read(businessServiceProvider)
                                .uploadImage(File(picked.path));
                            setState(() => _companyLogoUrl = url);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Failed to upload logo: $e')));
                            }
                          } finally {
                            setState(() => _isUploadingLogo = false);
                          }
                        }
                      },
                      icon: _isUploadingLogo
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.upload_file),
                      label: Text(_isUploadingLogo
                          ? 'Uploading Logo...'
                          : 'Upload Company Logo'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.primaryBlue),
                      ),
                    ),
                  ),
                _buildTextField(_companyNameController, 'Name of the company*',
                    Icons.business,
                    isRequired: true),
                const SizedBox(height: 16),
                _buildTextField(_companyAddressController, 'Company Address*',
                    Icons.location_on,
                    isRequired: true),
                const SizedBox(height: 16),
                _buildTextField(_phoneController, 'Phone Number*', Icons.phone,
                    isRequired: true, keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                _buildTextField(
                    _whatsappController, 'Whatsapp Number', Icons.chat),
                const SizedBox(height: 16),
                _buildTextField(_gstController, 'GST Number (Optional)',
                    Icons.confirmation_number),
                const SizedBox(height: 24),
                NeoCard(
                  backgroundColor: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Bank Details (Optional)',
                          style: AppTextStyles.toolCardTitle),
                      const SizedBox(height: 16),
                      _buildTextField(_bankNameController, 'Bank Name',
                          Icons.account_balance),
                      const SizedBox(height: 12),
                      _buildTextField(_accHolderController,
                          'Account Holder Name', Icons.person),
                      const SizedBox(height: 12),
                      _buildTextField(
                          _accNumberController, 'Account Number', Icons.numbers,
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      _buildTextField(_ifscController, 'IFSC Code', Icons.code),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildBusinessTypeSelector(),
                const SizedBox(height: 16),
                _buildPricingModeSelector(),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: _isLoading ? null : _submitProfile,
                  child: NeoCard(
                    backgroundColor: AppColors.primaryPurple,
                    child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              widget.isEditing
                                  ? 'Save Changes'
                                  : 'Save & Continue',
                              style: AppTextStyles.bodyText.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isRequired = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: isRequired
          ? (val) =>
              val == null || val.isEmpty ? 'This field is required' : null
          : null,
      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        prefixIcon: Icon(icon, color: Colors.black54),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 3),
        ),
      ),
    );
  }

  Widget _buildBusinessTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Business Type*',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isEditing ? Colors.grey.shade200 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: widget.isEditing ? Colors.black26 : Colors.black,
                width: 2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _businessType,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down,
                  color: widget.isEditing ? Colors.black26 : Colors.black),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.isEditing ? Colors.black54 : Colors.black,
                  fontSize: 16),
              dropdownColor: Colors.white,
              onChanged: widget.isEditing
                  ? null
                  : (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _businessType = newValue;
                        });
                      }
                    },
              items: <String>['Retailer', 'Manufacturer']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ),
        if (widget.isEditing)
          const Padding(
            padding: EdgeInsets.only(left: 4, top: 4),
            child: Text('Business Type cannot be changed after registration.',
                style: TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildPricingModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Default Pricing Mode*',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _pricingMode,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 16),
              dropdownColor: Colors.white,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _pricingMode = newValue;
                  });
                }
              },
              items: <String>['EXCLUSIVE', 'WITHOUT_GST']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value == 'EXCLUSIVE' ? 'With GST (B2B/Exclusive)' : 'Without GST (0% Tax)'),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
