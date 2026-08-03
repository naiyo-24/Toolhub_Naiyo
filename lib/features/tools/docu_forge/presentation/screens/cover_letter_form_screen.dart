import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import '../../data/cover_letter_model.dart';
class CoverLetterFormScreen extends StatefulWidget {
  const CoverLetterFormScreen({super.key});

  @override
  State<CoverLetterFormScreen> createState() => _CoverLetterFormScreenState();
}

class _CoverLetterFormScreenState extends State<CoverLetterFormScreen> {
  int _currentStep = 0;
  String _selectedTemplate = 'Professional';

  // Personal Info
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _linkedInController = TextEditingController();
  final _addressController = TextEditingController();

  // Job Details
  final _roleController = TextEditingController();
  final _companyController = TextEditingController();
  final _hiringManagerController = TextEditingController();

  // Qualifications
  final _experienceController = TextEditingController();
  final _skillsController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _linkedInController.dispose();
    _addressController.dispose();
    _roleController.dispose();
    _companyController.dispose();
    _hiringManagerController.dispose();
    _experienceController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  void _generateCoverLetter() {
    final data = CoverLetterData(
      fullName: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      linkedIn: _linkedInController.text,
      address: _addressController.text,
      targetRole: _roleController.text,
      companyName: _companyController.text,
      hiringManager: _hiringManagerController.text,
      yearsExperience: _experienceController.text,
      keySkills: _skillsController.text,
      templateType: _selectedTemplate,
    );
    context.push('/cover-letter-preview', extra: data);
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
            ),
          ),
        ],
      ),
    );
  }

  List<Step> _getSteps() {
    return [
      Step(
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        title: const Text('Personal Info', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          children: [
            _buildTextField('Full Name', _nameController),
            _buildTextField('Email', _emailController),
            _buildTextField('Phone', _phoneController),
            _buildTextField('LinkedIn (Optional)', _linkedInController),
            _buildTextField('Address / City (Optional)', _addressController, hint: 'e.g. New York, NY'),
          ],
        ),
      ),
      Step(
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        title: const Text('Job Details', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          children: [
            _buildTextField('Role Applying For', _roleController, hint: 'e.g. Senior Flutter Developer'),
            _buildTextField('Company Name', _companyController),
            _buildTextField('Hiring Manager Name (Optional)', _hiringManagerController, hint: 'Leave blank for "Hiring Manager"'),
          ],
        ),
      ),
      Step(
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
        title: const Text('Qualifications', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          children: [
            _buildTextField('Years of Experience', _experienceController, hint: 'e.g. 5+ years'),
            _buildTextField('Key Skills (Comma separated)', _skillsController, maxLines: 2, hint: 'e.g. Flutter, Dart, Firebase, REST APIs'),
          ],
        ),
      ),
      Step(
        isActive: _currentStep >= 3,
        state: _currentStep == 3 ? StepState.editing : StepState.indexed,
        title: const Text('Template', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select a template style:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTemplateRadio('Professional', 'Formal and structured. Best for corporate roles.'),
            _buildTemplateRadio('Creative', 'Enthusiastic and modern. Best for design/tech.'),
            _buildTemplateRadio('Direct', 'Short and punchy. Best for fast-paced startups.'),
          ],
        ),
      ),
    ];
  }

  Widget _buildTemplateRadio(String value, String description) {
    return RadioListTile<String>(
      title: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(description),
      value: value,
      // ignore: deprecated_member_use
      groupValue: _selectedTemplate,
      activeColor: AppColors.primaryBlue,
      // ignore: deprecated_member_use
      onChanged: (val) {
        setState(() {
          _selectedTemplate = val!;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: true,
        title: Text('Cover Letter', style: AppTextStyles.heroTitle.copyWith(fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: NeoCard(
              backgroundColor: const Color(0xFFE0FBFC), // Light Blue tint
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.black),
                      const SizedBox(width: 8),
                      Text('How to use', style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "1. Fill in your details and the job details step-by-step.\n2. Tap 'Next' to proceed through the sections.\n3. Finally, tap 'Generate Cover Letter' to create it.",
                    style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
        onStepTapped: (step) => setState(() => _currentStep = step),
        onStepContinue: () {
          if (_currentStep < _getSteps().length - 1) {
            setState(() => _currentStep += 1);
          } else {
            _generateCoverLetter();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          } else {
            context.pop();
          }
        },
        controlsBuilder: (context, details) {
          final isLast = _currentStep == _getSteps().length - 1;
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLast ? AppColors.primaryGreen : AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.black, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isLast ? 'Generate PDF' : 'Next', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                  ),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: details.onStepCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.black, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    ),
                  ),
                ]
              ],
            ),
          );
        },
        steps: _getSteps(),
      ),
      ),
      ],
      ),
    );
  }
}
