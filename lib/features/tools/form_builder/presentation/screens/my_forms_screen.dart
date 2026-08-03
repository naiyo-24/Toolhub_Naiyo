import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/features/tools/form_builder/data/form_api_service.dart';
import 'package:tool_hub/features/tools/form_builder/data/models/form_models.dart';

class MyFormsScreen extends StatefulWidget {
  const MyFormsScreen({super.key});

  @override
  State<MyFormsScreen> createState() => _MyFormsScreenState();
}

class _MyFormsScreenState extends State<MyFormsScreen> {
  final FormApiService _apiService = FormApiService();
  List<FormResponseModel> _forms = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadForms();
  }

  Future<void> _loadForms() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final forms = await _apiService.getMyForms();
      if (mounted) {
        setState(() {
          _forms = forms;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryYellow,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'My Forms',
          style: AppTextStyles.heroTitle.copyWith(fontSize: 20, color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
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

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.primaryRed, size: 64),
            const SizedBox(height: 16),
            const Text('Failed to load forms', style: AppTextStyles.sectionTitle),
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadForms,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text('Retry'),
            )
          ],
        ),
      );
    }

    if (_forms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description_outlined, size: 64, color: Colors.black26),
            const SizedBox(height: 16),
            Text('No forms found', style: AppTextStyles.sectionTitle.copyWith(color: Colors.black54)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadForms,
      color: Colors.black,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _forms.length,
        itemBuilder: (context, index) {
          final form = _forms[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: NeoCard(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: const Icon(Icons.article_rounded, color: Colors.black),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(form.title, style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
                        Text('${form.formType} • ${form.fieldsCount} Fields', style: AppTextStyles.bodyText.copyWith(color: Colors.black54)),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, color: AppColors.primaryBlue),
                        onPressed: () {
                          context.push('/edit-form/${form.id}', extra: form.formType).then((_) => _loadForms());
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_rounded, color: AppColors.primaryRed),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Delete Form?'),
                              content: const Text('This will delete the form and all its responses. This cannot be undone.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel', style: TextStyle(color: Colors.black))),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(c, true), 
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
                                  child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await _apiService.deleteForm(form.id);
                              _loadForms();
                            } catch (e) {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, color: Colors.black),
                        onPressed: () {
                          context.push('/form-details/${form.id}');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
