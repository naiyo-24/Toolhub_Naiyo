import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';
import 'package:tool_hub/core/api/api_config.dart';
import 'package:tool_hub/features/tools/form_builder/data/form_api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class FormDetailsScreen extends StatefulWidget {
  final String formId;
  const FormDetailsScreen({super.key, required this.formId});

  @override
  State<FormDetailsScreen> createState() => _FormDetailsScreenState();
}

class _FormDetailsScreenState extends State<FormDetailsScreen> {
  final FormApiService _apiService = FormApiService();
  Map<String, dynamic>? _responsesData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadResponses();
  }

  Future<void> _loadResponses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final data = await _apiService.getFormResponses(widget.formId);
      if (mounted) {
        setState(() {
          _responsesData = data;
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

  void _copyShareLink() {
    // URL to the new Web Viewer!
    final link = '${ApiConfig.baseUrl}/form-builder/forms/view/${widget.formId}';
    Clipboard.setData(ClipboardData(text: link));
    SnackbarUtils.showNeoSnackBar(context, message: 'Web form link copied to clipboard!');
  }

  void _exportCSV() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/form-builder/forms/${widget.formId}/export/csv');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showNeoSnackBar(context, message: 'Could not export CSV');
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
          'Form Details',
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
            const Text('Failed to load details', style: AppTextStyles.sectionTitle),
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadResponses,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text('Retry'),
            )
          ],
        ),
      );
    }

    if (_responsesData == null) return const SizedBox.shrink();

    final title = _responsesData!['title'] ?? 'Unknown Form';
    final totalResponses = _responsesData!['total_responses'] ?? 0;
    final List responses = _responsesData!['responses'] ?? [];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.primaryYellow,
            border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
          ),
                    child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: AppTextStyles.heroTitle.copyWith(fontSize: 24, color: Colors.black)),
              const SizedBox(height: 8),
              Text('$totalResponses Responses', style: AppTextStyles.sectionTitle.copyWith(color: Colors.black87)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _copyShareLink,
                      icon: const Icon(Icons.share_rounded, color: Colors.white),
                      label: const Text('Share Link', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/submit-form/${widget.formId}'),
                      icon: const Icon(Icons.visibility_rounded, color: Colors.black),
                      label: const Text('Preview', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                                    Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _exportCSV,
                      icon: const Icon(Icons.download_rounded, color: Colors.white),
                      label: const Text('Export CSV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.black, width: 2)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: Colors.black,
            backgroundColor: AppColors.primaryYellow,
            onRefresh: _loadResponses,
            child: responses.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: constraints.maxHeight,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inbox_rounded, size: 64, color: Colors.black26),
                            const SizedBox(height: 16),
                            Text('No responses yet', style: AppTextStyles.sectionTitle.copyWith(color: Colors.black54)),
                            const SizedBox(height: 8),
                            const Text('Pull to refresh', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: responses.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildResponseCard(responses[index]),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponseCard(dynamic response) {
    final dateStr = response['submitted_at'] != null 
        ? DateTime.parse(response['submitted_at']).toLocal().toString().substring(0, 16)
        : '';
    final email = response['respondent_email'] ?? 'Anonymous';
    final Map<String, dynamic> answers = response['answers'] ?? {};
    
    return NeoCard(
      backgroundColor: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black))),
              Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const Divider(color: Colors.black26, thickness: 1),
          ...answers.entries.map((e) {
            final valueStr = e.value.toString();
            final isLink = valueStr.startsWith('/uploads/') || valueStr.startsWith('http');
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.key, style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w600)),
                  if (isLink)
                    InkWell(
                      onTap: () async {
                        final urlString = valueStr.startsWith('http') ? valueStr : '${ApiConfig.baseUrl}$valueStr';
                        final url = Uri.parse(urlString);
                        try {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } catch (e) {
                          // ignore: use_build_context_synchronously
                          SnackbarUtils.showNeoSnackBar(context, message: 'Could not open link');
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.attach_file, color: AppColors.primaryBlue, size: 16),
                            SizedBox(width: 4),
                            Flexible(child: Text('View File', style: TextStyle(color: AppColors.primaryBlue, fontSize: 16, decoration: TextDecoration.underline))),
                          ],
                        ),
                      ),
                    )
                  else
                    Text(valueStr, style: const TextStyle(color: Colors.black, fontSize: 16)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
