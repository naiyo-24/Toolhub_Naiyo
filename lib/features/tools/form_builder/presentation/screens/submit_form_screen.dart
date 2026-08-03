import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';
import 'package:tool_hub/features/tools/form_builder/data/form_api_service.dart';
import 'package:tool_hub/features/tools/form_builder/data/models/form_models.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tool_hub/core/api/api_config.dart';

class SubmitFormScreen extends StatefulWidget {
  final String formId;
  const SubmitFormScreen({super.key, required this.formId});

  @override
  State<SubmitFormScreen> createState() => _SubmitFormScreenState();
}

class _SubmitFormScreenState extends State<SubmitFormScreen> {
  final FormApiService _apiService = FormApiService();
  FormDetailModel? _form;
  bool _isLoading = true;
  String? _error;
  bool _isSubmitting = false;

  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _answers = {};
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  Future<void> _loadForm() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final form = await _apiService.getPublicForm(widget.formId);
      if (mounted) {
        setState(() {
          _form = form;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);
    
    try {
      await _apiService.submitFormResponse(
        widget.formId, 
        _answers,
        email: _emailController.text.isNotEmpty ? _emailController.text : null
      );
      
      if (mounted) {
        SnackbarUtils.showNeoSnackBar(context, message: 'Response submitted successfully!');
        context.pop(); // Go back
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showNeoSnackBar(context, message: e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryPink,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Submit Response',
          style: AppTextStyles.heroTitle.copyWith(fontSize: 20, color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3));
    }

    if (_error != null || _form == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.primaryRed, size: 64),
            const SizedBox(height: 16),
            const Text('Failed to load form', style: AppTextStyles.sectionTitle),
            Text(_error ?? 'Unknown error', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadForm,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text('Retry'),
            )
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          NeoCard(
            backgroundColor: AppColors.primaryPink,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_form!.headerImageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.network(
                        _form!.headerImageUrl!.startsWith('http') 
                          ? _form!.headerImageUrl! 
                          : '${ApiConfig.baseUrl}${_form!.headerImageUrl}',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(_form!.title, style: AppTextStyles.heroTitle.copyWith(fontSize: 28, color: Colors.black)),
                if (_form!.description != null && _form!.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(_form!.description!, style: AppTextStyles.bodyText.copyWith(color: Colors.black87, fontSize: 16)),
                ]
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Your Email *',
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          ..._form!.fields.map((field) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: NeoCard(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(field.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black))),
                        if (field.isRequired)
                          const Text('*', style: TextStyle(color: AppColors.primaryRed, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildFieldInput(field),
                  ],
                ),
              ),
            );
          }),
          
          const SizedBox(height: 20),
          _isSubmitting
            ? const Center(child: CircularProgressIndicator(color: Colors.black))
            : ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Submit Form', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFieldInput(FormFieldModel field) {
    if (field.fieldType == 'radio') {
      return FormField<String>(
        validator: (val) {
          if (field.isRequired && (val == null || val.isEmpty)) return 'Please select an option';
          return null;
        },
        onSaved: (val) {
          _answers[field.label] = val ?? '';
        },
        builder: (FormFieldState<String> state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...(field.options ?? []).map((opt) {
                return RadioListTile<String>(
                  title: Text(opt),
                  value: opt,
                  // ignore: deprecated_member_use
                  groupValue: state.value,
                  // ignore: deprecated_member_use
                  onChanged: (val) => state.didChange(val),
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primaryBlue,
                );
              }),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(state.errorText!, style: const TextStyle(color: AppColors.primaryRed, fontSize: 12)),
                )
            ],
          );
        },
      );
    }

    if (field.fieldType == 'checkbox') {
      return FormField<List<String>>(
        initialValue: const [],
        validator: (val) {
          if (field.isRequired && (val == null || val.isEmpty)) return 'Please select at least one option';
          return null;
        },
        onSaved: (val) {
          _answers[field.label] = (val ?? []).join(', ');
        },
        builder: (FormFieldState<List<String>> state) {
          final selectedList = state.value ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...(field.options ?? []).map((opt) {
                return CheckboxListTile(
                  title: Text(opt),
                  value: selectedList.contains(opt),
                  onChanged: (checked) {
                    final newList = List<String>.from(selectedList);
                    if (checked == true) {
                      newList.add(opt);
                    } else {
                      newList.remove(opt);
                    }
                    state.didChange(newList);
                  },
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primaryBlue,
                );
              }),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(state.errorText!, style: const TextStyle(color: AppColors.primaryRed, fontSize: 12)),
                )
            ],
          );
        },
      );
    }

    if (field.fieldType == 'dropdown') {
      return DropdownButtonFormField<String>(
        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
        items: (field.options ?? []).map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
        onChanged: (val) {},
        validator: (val) {
          if (field.isRequired && (val == null || val.isEmpty)) return 'Please select an option';
          return null;
        },
        onSaved: (val) {
          _answers[field.label] = val ?? '';
        },
      );
    }

    if (field.fieldType == 'file') {
      return FormField<String>(
        validator: (val) {
          if (field.isRequired && (val == null || val.isEmpty)) return 'Please upload a file';
          return null;
        },
        onSaved: (val) {
          _answers[field.label] = val ?? '';
        },
        builder: (FormFieldState<String> state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.value != null && state.value!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text('Uploaded File URL: ${state.value}', style: const TextStyle(color: AppColors.primaryBlue)),
                ),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final result = await FilePicker.platform.pickFiles();
                    if (result != null && result.files.single.path != null) {
                      // Validate size (5MB max)
                      final size = result.files.single.size;
                      if (size > 5 * 1024 * 1024) {
                        // ignore: use_build_context_synchronously
                        SnackbarUtils.showNeoSnackBar(context, message: 'File is too large (max 5MB)');
                        return;
                      }
                      
                      // ignore: use_build_context_synchronously
                      SnackbarUtils.showNeoSnackBar(context, message: 'Uploading...');
                      final url = await _apiService.uploadFile(result.files.single.path!, result.files.single.name);
                      state.didChange(url);
                      // ignore: use_build_context_synchronously
                      SnackbarUtils.showNeoSnackBar(context, message: 'Upload successful!');
                    }
                  } catch (e) {
                    // ignore: use_build_context_synchronously
                    SnackbarUtils.showNeoSnackBar(context, message: 'Upload failed: $e');
                  }
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Pick and Upload File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black, width: 2),
                ),
              ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(state.errorText!, style: const TextStyle(color: AppColors.primaryRed, fontSize: 12)),
                )
            ],
          );
        },
      );
    }

    TextInputType keyboardType = TextInputType.text;
    if (field.fieldType == 'email') keyboardType = TextInputType.emailAddress;
    if (field.fieldType == 'number') keyboardType = TextInputType.number;

    return TextFormField(
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      keyboardType: keyboardType,
      maxLines: field.fieldType == 'paragraph' ? 4 : 1,
      validator: (val) {
        if (field.isRequired && (val == null || val.trim().isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
      onSaved: (val) {
        _answers[field.label] = val?.trim() ?? '';
      },
    );
  }
}
