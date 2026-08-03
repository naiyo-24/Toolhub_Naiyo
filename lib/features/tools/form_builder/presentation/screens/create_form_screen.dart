import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';
import 'package:tool_hub/features/tools/form_builder/data/form_api_service.dart';
import 'package:tool_hub/features/tools/form_builder/data/models/form_models.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tool_hub/core/api/api_config.dart';

class CreateFormScreen extends StatefulWidget {
  final String initialFormType;
  final String? formId;
  const CreateFormScreen({super.key, required this.initialFormType, this.formId});

  @override
  State<CreateFormScreen> createState() => _CreateFormScreenState();
}

class _CreateFormScreenState extends State<CreateFormScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  List<FormFieldModel> _fields = [];
  bool _isLoading = false;
  final FormApiService _apiService = FormApiService();
  String? _headerImageUrl;
  bool _isUploadingImage = false;
  bool _allowMultipleResponses = true;

  @override
  void initState() {
    super.initState();
    if (widget.formId != null) {
      _fetchFormDetails();
    } else {
      _titleController.text = 'My ${widget.initialFormType}';
      _populateDefaultFields();
    }
  }

  Future<void> _fetchFormDetails() async {
    try {
      final form = await _apiService.getPublicForm(widget.formId!);
      if (mounted) {
        setState(() {
          _titleController.text = form.title;
          _descController.text = form.description ?? '';
          _headerImageUrl = form.headerImageUrl;
          _allowMultipleResponses = form.allowMultipleResponses;
          _fields = form.fields;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showNeoSnackBar(context, message: 'Failed to load form: $e');
      }
    }
  }

  void _populateDefaultFields() {
    switch (widget.initialFormType) {
      case 'Contact Form':
        _fields.add(FormFieldModel(label: 'Full Name', fieldType: 'text', isRequired: true, orderIndex: 0));
        _fields.add(FormFieldModel(label: 'Email', fieldType: 'email', isRequired: true, orderIndex: 1));
        _fields.add(FormFieldModel(label: 'Subject', fieldType: 'text', isRequired: false, orderIndex: 2));
        _fields.add(FormFieldModel(label: 'Message', fieldType: 'text', isRequired: true, orderIndex: 3));
        break;
      case 'Survey Form':
        _fields.add(FormFieldModel(label: 'How did you hear about us?', fieldType: 'text', isRequired: false, orderIndex: 0));
        _fields.add(FormFieldModel(label: 'How satisfied are you? (1-5)', fieldType: 'number', isRequired: true, orderIndex: 1));
        _fields.add(FormFieldModel(label: 'Additional Comments', fieldType: 'text', isRequired: false, orderIndex: 2));
        break;
      case 'Feedback Form':
        _fields.add(FormFieldModel(label: 'Name (Optional)', fieldType: 'text', isRequired: false, orderIndex: 0));
        _fields.add(FormFieldModel(label: 'Rating (1-5)', fieldType: 'number', isRequired: true, orderIndex: 1));
        _fields.add(FormFieldModel(label: 'What could we improve?', fieldType: 'text', isRequired: false, orderIndex: 2));
        break;
      case 'Registration':
        _fields.add(FormFieldModel(label: 'First Name', fieldType: 'text', isRequired: true, orderIndex: 0));
        _fields.add(FormFieldModel(label: 'Last Name', fieldType: 'text', isRequired: true, orderIndex: 1));
        _fields.add(FormFieldModel(label: 'Email Address', fieldType: 'email', isRequired: true, orderIndex: 2));
        _fields.add(FormFieldModel(label: 'Date of Birth', fieldType: 'date', isRequired: false, orderIndex: 3));
        break;
      case 'Job App':
        _fields.add(FormFieldModel(label: 'Full Name', fieldType: 'text', isRequired: true, orderIndex: 0));
        _fields.add(FormFieldModel(label: 'Email', fieldType: 'email', isRequired: true, orderIndex: 1));
        _fields.add(FormFieldModel(label: 'Phone Number', fieldType: 'number', isRequired: true, orderIndex: 2));
        _fields.add(FormFieldModel(label: 'Portfolio Link', fieldType: 'text', isRequired: false, orderIndex: 3));
        break;
      case 'Order Form':
        _fields.add(FormFieldModel(label: 'Product Name', fieldType: 'text', isRequired: true, orderIndex: 0));
        _fields.add(FormFieldModel(label: 'Quantity', fieldType: 'number', isRequired: true, orderIndex: 1));
        _fields.add(FormFieldModel(label: 'Shipping Address', fieldType: 'text', isRequired: true, orderIndex: 2));
        break;
      case 'Quiz Builder':
        _fields.add(FormFieldModel(label: 'Participant Name', fieldType: 'text', isRequired: true, orderIndex: 0));
        _fields.add(FormFieldModel(label: 'Question 1: What is the capital of France?', fieldType: 'text', isRequired: true, orderIndex: 1));
        _fields.add(FormFieldModel(label: 'Question 2: 5 + 7 = ?', fieldType: 'number', isRequired: true, orderIndex: 2));
        break;
      case 'Poll Creator':
        _fields.add(FormFieldModel(label: 'What is your favorite color?', fieldType: 'text', isRequired: true, orderIndex: 0));
        _fields.add(FormFieldModel(label: 'Do you prefer cats or dogs?', fieldType: 'text', isRequired: true, orderIndex: 1));
        break;
      default:
        _fields.add(FormFieldModel(label: 'Question 1', fieldType: 'text', isRequired: true, orderIndex: 0));
    }
  }

  void _addField(String type) {
    setState(() {
      _fields.add(FormFieldModel(
        label: 'New $type field',
        fieldType: type,
        isRequired: false,
        orderIndex: _fields.length,
      ));
    });
  }

  void _removeField(int index) {
    setState(() {
      _fields.removeAt(index);
    });
  }

  void _updateFieldLabel(int index, String newLabel) {
    final oldField = _fields[index];
    _fields[index] = FormFieldModel(
      label: newLabel,
      fieldType: oldField.fieldType,
      isRequired: oldField.isRequired,
      options: oldField.options,
      orderIndex: oldField.orderIndex,
    );
  }

  void _updateFieldRequired(int index, bool isRequired) {
    setState(() {
      final oldField = _fields[index];
      _fields[index] = FormFieldModel(
        label: oldField.label,
        fieldType: oldField.fieldType,
        isRequired: isRequired,
        options: oldField.options,
        orderIndex: oldField.orderIndex,
      );
    });
  }

  void _updateFieldType(int index, String newType) {
    setState(() {
      final oldField = _fields[index];
      // Reset options if switching away from multi-option types, otherwise preserve or initialize
      List<String>? newOptions = oldField.options;
      if (['radio', 'checkbox', 'dropdown'].contains(newType)) {
        newOptions ??= ['Option 1'];
      } else {
        newOptions = null;
      }
      _fields[index] = FormFieldModel(
        label: oldField.label,
        fieldType: newType,
        isRequired: oldField.isRequired,
        options: newOptions,
        orderIndex: oldField.orderIndex,
      );
    });
  }

  void _addOptionToField(int index) {
    setState(() {
      final oldField = _fields[index];
      final opts = List<String>.from(oldField.options ?? []);
      opts.add('Option ${opts.length + 1}');
      _fields[index] = FormFieldModel(
        label: oldField.label,
        fieldType: oldField.fieldType,
        isRequired: oldField.isRequired,
        options: opts,
        orderIndex: oldField.orderIndex,
      );
    });
  }

  void _updateOption(int fieldIndex, int optionIndex, String newValue) {
    final oldField = _fields[fieldIndex];
    final opts = List<String>.from(oldField.options ?? []);
    if (optionIndex >= 0 && optionIndex < opts.length) {
      opts[optionIndex] = newValue;
      _fields[fieldIndex] = FormFieldModel(
        label: oldField.label,
        fieldType: oldField.fieldType,
        isRequired: oldField.isRequired,
        options: opts,
        orderIndex: oldField.orderIndex,
      );
    }
  }

  void _removeOption(int fieldIndex, int optionIndex) {
    setState(() {
      final oldField = _fields[fieldIndex];
      final opts = List<String>.from(oldField.options ?? []);
      if (optionIndex >= 0 && optionIndex < opts.length) {
        opts.removeAt(optionIndex);
        _fields[fieldIndex] = FormFieldModel(
          label: oldField.label,
          fieldType: oldField.fieldType,
          isRequired: oldField.isRequired,
          options: opts,
          orderIndex: oldField.orderIndex,
        );
      }
    });
  }

  Future<void> _pickAndUploadHeaderImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() => _isUploadingImage = true);
      try {
        final url = await _apiService.uploadFile(pickedFile.path, pickedFile.name);
        setState(() => _headerImageUrl = url);
        if (mounted) {
          SnackbarUtils.showNeoSnackBar(context, message: 'Header image uploaded successfully!');
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtils.showNeoSnackBar(context, message: 'Failed to upload image: $e', isError: true);
        }
      } finally {
        if (mounted) {
          setState(() => _isUploadingImage = false);
        }
      }
    }
  }

  Future<void> _saveForm() async {
    if (_titleController.text.trim().isEmpty) {
      SnackbarUtils.showNeoSnackBar(context, message: 'Please enter a title');
      return;
    }
    if (_fields.isEmpty) {
      SnackbarUtils.showNeoSnackBar(context, message: 'Please add at least one field');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final form = FormCreateModel(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        headerImageUrl: _headerImageUrl,
        formType: widget.initialFormType,
        isPublished: true,
        allowMultipleResponses: _allowMultipleResponses,
        fields: _fields,
      );

      if (widget.formId != null) {
        await _apiService.updateForm(widget.formId!, form);
        if (mounted) {
          SnackbarUtils.showNeoSnackBar(context, message: 'Form updated successfully!');
          context.pop();
        }
      } else {
        await _apiService.createForm(form);
        if (mounted) {
          SnackbarUtils.showNeoSnackBar(context, message: 'Form created successfully!');
          context.go('/my-forms');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showNeoSnackBar(context, message: e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryYellow,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Create Form',
          style: AppTextStyles.heroTitle.copyWith(fontSize: 20, color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          _isLoading 
            ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)),
              )
            : IconButton(
                icon: const Icon(Icons.save_rounded, color: Colors.black),
                onPressed: _saveForm,
              )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primaryYellow,
              border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  style: AppTextStyles.heroTitle.copyWith(fontSize: 24, color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Form Title',
                    border: InputBorder.none,
                    hintStyle: AppTextStyles.heroTitle.copyWith(fontSize: 24, color: Colors.black54),
                  ),
                ),
                TextField(
                  controller: _descController,
                  style: AppTextStyles.bodyText.copyWith(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Form Description (optional)',
                    border: InputBorder.none,
                    hintStyle: AppTextStyles.bodyText.copyWith(color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 16),
                if (_headerImageUrl != null)
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(
                              _headerImageUrl!.startsWith('http') 
                                ? _headerImageUrl! 
                                : '${ApiConfig.baseUrl}$_headerImageUrl'
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.black),
                            onPressed: () => setState(() => _headerImageUrl = null),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isUploadingImage ? null : _pickAndUploadHeaderImage,
                      icon: _isUploadingImage 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.image_rounded, color: Colors.white),
                      label: Text(
                        _isUploadingImage ? 'Uploading...' : 'Add Header Photo',
                        style: AppTextStyles.buttonText.copyWith(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Allow multiple responses per email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Switch(
                      value: _allowMultipleResponses,
                      onChanged: (val) => setState(() => _allowMultipleResponses = val),
                      activeThumbColor: Colors.black,
                      inactiveTrackColor: Colors.black12,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _fields.length,
              itemBuilder: (context, index) {
                final field = _fields[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: NeoCard(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              decoration: BoxDecoration(
                                color: _getColorForType(field.fieldType),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.black, width: 2),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: field.fieldType,
                                  dropdownColor: _getColorForType(field.fieldType),
                                  style: AppTextStyles.caption.copyWith(color: Colors.black, fontWeight: FontWeight.bold),
                                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                                  onChanged: (val) {
                                    if (val != null) _updateFieldType(index, val);
                                  },
                                  items: const [
                                    DropdownMenuItem(value: 'text', child: Text('SHORT ANSWER')),
                                    DropdownMenuItem(value: 'paragraph', child: Text('PARAGRAPH')),
                                    DropdownMenuItem(value: 'email', child: Text('EMAIL')),
                                    DropdownMenuItem(value: 'radio', child: Text('MULTIPLE CHOICE')),
                                    DropdownMenuItem(value: 'checkbox', child: Text('CHECKBOXES')),
                                    DropdownMenuItem(value: 'dropdown', child: Text('DROPDOWN')),
                                    DropdownMenuItem(value: 'file', child: Text('FILE UPLOAD')),
                                    DropdownMenuItem(value: 'date', child: Text('DATE')),
                                    DropdownMenuItem(value: 'time', child: Text('TIME')),
                                    DropdownMenuItem(value: 'number', child: Text('NUMBER')),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                const Text('Required:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                                Switch(
                                  value: field.isRequired,
                                  onChanged: (val) => _updateFieldRequired(index, val),
                                  activeThumbColor: AppColors.primaryGreen,
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.primaryRed),
                              onPressed: () => _removeField(index),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: field.label,
                          onChanged: (val) => _updateFieldLabel(index, val),
                          decoration: InputDecoration(
                            labelText: 'Question',
                            border: const OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2)),
                          ),
                        ),
                        if (['radio', 'checkbox', 'dropdown'].contains(field.fieldType))
                          _buildOptionsEditor(index, field),
                        if (field.fieldType == 'file')
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text('Respondents will be able to upload any file up to 5MB.', style: AppTextStyles.caption.copyWith(color: Colors.black54)),
                          )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildAddFieldButton('text', Icons.add_circle_outline, 'Add Question'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsEditor(int fieldIndex, FormFieldModel field) {
    final options = field.options ?? [];
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Options', style: AppTextStyles.sectionTitle.copyWith(fontSize: 14)),
          const SizedBox(height: 8),
          ...options.asMap().entries.map((entry) {
            final idx = entry.key;
            final opt = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(
                    field.fieldType == 'radio' ? Icons.radio_button_unchecked : 
                    (field.fieldType == 'checkbox' ? Icons.check_box_outline_blank : Icons.arrow_right),
                    color: Colors.black54,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: opt,
                      onChanged: (val) => _updateOption(fieldIndex, idx, val),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54, size: 20),
                    onPressed: () => _removeOption(fieldIndex, idx),
                  )
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: () => _addOptionToField(fieldIndex),
            icon: const Icon(Icons.add, color: AppColors.primaryBlue),
            label: const Text('Add Option', style: TextStyle(color: AppColors.primaryBlue)),
          )
        ],
      ),
    );
  }

  Widget _buildAddFieldButton(String type, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ActionChip(
        backgroundColor: Colors.white,
        side: const BorderSide(color: Colors.black, width: 2),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        avatar: Icon(icon, color: Colors.black, size: 16),
        onPressed: () => _addField(type),
      ),
    );
  }

  Color _getColorForType(String type) {
    switch(type) {
      case 'text': return AppColors.primaryBlue;
      case 'paragraph': return Colors.lightBlueAccent;
      case 'radio': return Colors.purpleAccent;
      case 'checkbox': return Colors.deepOrangeAccent;
      case 'dropdown': return Colors.tealAccent;
      case 'file': return Colors.brown;
      case 'email': return AppColors.primaryPink;
      case 'number': return AppColors.primaryGreen;
      case 'date': return AppColors.primaryYellow;
      case 'time': return Colors.amber;
      default: return AppColors.primaryPurple;
    }
  }
}
