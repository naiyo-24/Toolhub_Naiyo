import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import '../../data/resume_model.dart';

class ResumeBuilderFormScreen extends StatefulWidget {
  const ResumeBuilderFormScreen({super.key});

  @override
  State<ResumeBuilderFormScreen> createState() => _ResumeBuilderFormScreenState();
}

class _ResumeBuilderFormScreenState extends State<ResumeBuilderFormScreen> {
  int _currentStep = 0;
  
  // Form Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _githubController = TextEditingController();
  final _summaryController = TextEditingController();
  
  final List<Map<String, TextEditingController>> _experienceControllers = [];
  final List<Map<String, TextEditingController>> _projectsControllers = [];
  final List<Map<String, TextEditingController>> _educationControllers = [];
  
  final _skillsController = TextEditingController();

  void _addExperience() {
    setState(() {
      _experienceControllers.add({
        'title': TextEditingController(),
        'company': TextEditingController(),
        'dates': TextEditingController(),
        'description': TextEditingController(),
      });
    });
  }

  void _addProject() {
    setState(() {
      _projectsControllers.add({
        'title': TextEditingController(),
        'link': TextEditingController(),
        'description': TextEditingController(),
      });
    });
  }

  void _addEducation() {
    setState(() {
      _educationControllers.add({
        'degree': TextEditingController(),
        'school': TextEditingController(),
        'year': TextEditingController(),
      });
    });
  }

  void _submitForm() {
    // Collect data
    List<Map<String, String>> experience = _experienceControllers.map((c) => {
      'title': c['title']!.text,
      'company': c['company']!.text,
      'dates': c['dates']!.text,
      'description': c['description']!.text,
    }).where((m) => m['title']!.isNotEmpty).toList();

    List<Map<String, String>> projects = _projectsControllers.map((c) => {
      'title': c['title']!.text,
      'link': c['link']!.text,
      'description': c['description']!.text,
    }).where((m) => m['title']!.isNotEmpty).toList();

    List<Map<String, String>> education = _educationControllers.map((c) => {
      'degree': c['degree']!.text,
      'school': c['school']!.text,
      'year': c['year']!.text,
    }).where((m) => m['degree']!.isNotEmpty).toList();

    List<String> skills = _skillsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    final resumeData = ResumeData(
      fullName: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      linkedIn: _linkedinController.text,
      github: _githubController.text,
      summary: _summaryController.text,
      experience: experience,
      projects: projects,
      education: education,
      skills: skills,
    );

    context.push('/resume-templates', extra: resumeData);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    _summaryController.dispose();
    _skillsController.dispose();
    for (var c in _experienceControllers) {
      for (var ctrl in c.values) {
        ctrl.dispose();
      }
    }
    for (var c in _projectsControllers) {
      for (var ctrl in c.values) {
        ctrl.dispose();
      }
    }
    for (var c in _educationControllers) {
      for (var ctrl in c.values) {
        ctrl.dispose();
      }
    }
    super.dispose();
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

  Future<void> _pickExperienceDates(BuildContext context, TextEditingController controller) async {
    DateTime? start = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1960),
      lastDate: DateTime.now(),
      helpText: 'Select Start Date',
    );
    if (start == null) return;

    if (!context.mounted) return;
    
    bool isCurrent = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Is this your current role?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
        ],
      ),
    ) ?? false;

    if (isCurrent) {
      controller.text = '${start.year} - Present';
      return;
    }

    if (!context.mounted) return;

    DateTime? end = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: start,
      lastDate: DateTime.now(),
      helpText: 'Select End Date',
    );
    if (end == null) return;

    final today = DateTime.now();
    if (end.year == today.year && end.month == today.month && end.day == today.day) {
      controller.text = '${start.year} - Present';
    } else {
      controller.text = '${start.year} - ${end.year}';
    }
  }

  List<Step> _getSteps() {
    return [
      Step(
        title: const Text('Personal Info', style: TextStyle(fontWeight: FontWeight.bold)),
        isActive: _currentStep >= 0,
        content: Column(
          children: [
            _buildTextField('Full Name', _nameController),
            _buildTextField('Email', _emailController),
            _buildTextField('Phone', _phoneController),
            _buildTextField('LinkedIn (Optional)', _linkedinController),
            _buildTextField('GitHub (Optional)', _githubController),
          ],
        ),
      ),
      Step(
        title: const Text('Summary', style: TextStyle(fontWeight: FontWeight.bold)),
        isActive: _currentStep >= 1,
        content: _buildTextField('Professional Summary', _summaryController, maxLines: 4, hint: 'Write a brief professional summary...'),
      ),
      Step(
        title: const Text('Experience', style: TextStyle(fontWeight: FontWeight.bold)),
        isActive: _currentStep >= 2,
        content: Column(
          children: [
            ..._experienceControllers.asMap().entries.map((entry) {
              int i = entry.key;
              var c = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: NeoCard(
                  backgroundColor: AppColors.primaryYellow,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Role ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => setState(() => _experienceControllers.removeAt(i)),
                          )
                        ],
                      ),
                      _buildTextField('Job Title', c['title']!),
                      _buildTextField('Company', c['company']!),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Dates', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: c['dates'],
                              readOnly: true,
                              onTap: () => _pickExperienceDates(context, c['dates']!),
                              decoration: InputDecoration(
                                hintText: 'Select Dates',
                                filled: true,
                                fillColor: Colors.white,
                                suffixIcon: const Icon(Icons.calendar_today),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildTextField('Description', c['description']!, maxLines: 3),
                    ],
                  ),
                ),
              );
            }),
            ElevatedButton.icon(
              onPressed: _addExperience,
              icon: const Icon(Icons.add),
              label: const Text('Add Experience', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
      Step(
        title: const Text('Projects (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
        isActive: _currentStep >= 3,
        content: Column(
          children: [
            ..._projectsControllers.asMap().entries.map((entry) {
              int i = entry.key;
              var c = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: NeoCard(
                  backgroundColor: AppColors.primaryPink,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Project ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => setState(() => _projectsControllers.removeAt(i)),
                          )
                        ],
                      ),
                      _buildTextField('Project Title', c['title']!),
                      _buildTextField('Link (Optional)', c['link']!),
                      _buildTextField('Description', c['description']!, maxLines: 3),
                    ],
                  ),
                ),
              );
            }),
            ElevatedButton.icon(
              onPressed: _addProject,
              icon: const Icon(Icons.add),
              label: const Text('Add Project', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
      Step(
        title: const Text('Education', style: TextStyle(fontWeight: FontWeight.bold)),
        isActive: _currentStep >= 4,
        content: Column(
          children: [
            ..._educationControllers.asMap().entries.map((entry) {
              int i = entry.key;
              var c = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: NeoCard(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Degree ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => setState(() => _educationControllers.removeAt(i)),
                          )
                        ],
                      ),
                      _buildTextField('Degree / Major', c['degree']!),
                      _buildTextField('University / School', c['school']!),
                      _buildTextField('Graduation Year', c['year']!),
                    ],
                  ),
                ),
              );
            }),
            ElevatedButton.icon(
              onPressed: _addEducation,
              icon: const Icon(Icons.add),
              label: const Text('Add Education', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
      Step(
        title: const Text('Skills', style: TextStyle(fontWeight: FontWeight.bold)),
        isActive: _currentStep >= 5,
        content: _buildTextField('Skills (Comma separated)', _skillsController, hint: 'Flutter, Python, UI/UX Design, Leadership'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        elevation: 0,
        centerTitle: true,
        title: Text('Build Resume', style: AppTextStyles.heroTitle.copyWith(fontSize: 20)),
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
                    "1. Fill in your details step-by-step.\n2. Tap 'Next' to proceed through the sections.\n3. Finally, tap 'Choose Template' to pick a resume design.",
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
            _submitForm();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: details.onStepContinue,
                    child: Text(_currentStep == _getSteps().length - 1 ? 'Choose Template' : 'Next', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      onPressed: details.onStepCancel,
                      child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
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
