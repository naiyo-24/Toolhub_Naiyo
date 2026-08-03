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

class BusinessCardScreen extends ConsumerStatefulWidget {
  const BusinessCardScreen({super.key});

  @override
  ConsumerState<BusinessCardScreen> createState() => _BusinessCardScreenState();
}

class _BusinessCardScreenState extends ConsumerState<BusinessCardScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _jobTitleController.dispose();
    _companyNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _generateBusinessCard() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final payload = {
        'name': _nameController.text,
        'job_title': _jobTitleController.text,
        'company_name': _companyNameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'website': _websiteController.text.isEmpty ? null : _websiteController.text,
      };

      final pdfPath = await ref.read(businessServiceProvider).generateBusinessCard(payload);
      
      if (mounted) {
        SnackbarUtils.showNeoSnackBar(context, message: 'Business Card generated!');
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

  Widget _buildTextField(String label, TextEditingController controller, {bool isRequired = true}) {
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
        backgroundColor: AppColors.primaryPink,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text('Business Card', style: AppTextStyles.heroTitle.copyWith(fontSize: 20)),
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
                _buildTextField('Full Name', _nameController),
                _buildTextField('Job Title', _jobTitleController),
                _buildTextField('Company Name', _companyNameController),
                _buildTextField('Phone Number', _phoneController),
                _buildTextField('Email Address', _emailController),
                _buildTextField('Website (Optional)', _websiteController, isRequired: false),
                
                const SizedBox(height: 24),
                NeoCard(
                  onTap: _isLoading ? null : _generateBusinessCard,
                  backgroundColor: AppColors.primaryPink,
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
