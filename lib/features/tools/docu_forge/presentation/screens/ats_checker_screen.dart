import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import '../../data/docuforge_service.dart';

class ATSCheckerScreen extends StatefulWidget {
  const ATSCheckerScreen({super.key});

  @override
  State<ATSCheckerScreen> createState() => _ATSCheckerScreenState();
}

class _ATSCheckerScreenState extends State<ATSCheckerScreen> {
  final _service = DocuForgeService();
  final _jdController = TextEditingController();
  
  File? _selectedFile;
  bool _isLoading = false;
  Map<String, dynamic>? _results;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() => _selectedFile = File(result.files.single.path!));
    }
  }

  Future<void> _checkATS() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select your Resume PDF')));
      return;
    }
    if (_jdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please paste a Job Description')));
      return;
    }

    setState(() {
      _isLoading = true;
      _results = null;
    });

    try {
      final res = await _service.checkAtsScore(_selectedFile!, _jdController.text);
      setState(() {
        _results = res;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _jdController.dispose();
    super.dispose();
  }

  Widget _buildResults() {
    if (_results == null) return const SizedBox();
    
    final int score = _results!['ats_score'] ?? 0;
    final List<dynamic> missing = _results!['missing_keywords'] ?? [];
    final List<dynamic> issues = _results!['formatting_issues'] ?? [];
    final List<dynamic> tips = _results!['improvement_tips'] ?? [];

    Color scoreColor = score >= 80 ? AppColors.primaryGreen : (score >= 50 ? AppColors.primaryYellow : AppColors.primaryOrange);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NeoCard(
          backgroundColor: scoreColor,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('ATS Match Score', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('$score%', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (missing.isNotEmpty) ...[
          const Text('Missing Keywords', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: missing.map((e) => Chip(
              label: Text(e.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.primaryPink,
              side: const BorderSide(color: Colors.black, width: 2),
            )).toList(),
          ),
          const SizedBox(height: 24),
        ],
        if (issues.isNotEmpty) ...[
          const Text('Formatting Issues', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          ...issues.map((i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning, color: AppColors.primaryOrange, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(i.toString())),
              ],
            ),
          )),
          const SizedBox(height: 24),
        ],
        if (tips.isNotEmpty) ...[
          const Text('Improvement Tips', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          ...tips.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb, color: AppColors.primaryYellow, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(t.toString())),
              ],
            ),
          )),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        centerTitle: true,
        title: Text('ATS Checker', style: AppTextStyles.heroTitle.copyWith(fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NeoCard(
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
                    "1. Upload your resume (PDF).\n2. Paste the target job description.\n3. Tap 'Check ATS Score' to get a compatibility report.",
                    style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            NeoCard(
              backgroundColor: AppColors.primaryPink,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('1. Upload Resume (PDF)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: Text(_selectedFile != null ? _selectedFile!.path.split('/').last : 'Select PDF File', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('2. Paste Job Description', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _jdController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Paste the full job description here...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _checkATS,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.black, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.black)
                : const Text('Analyze Resume', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
            _buildResults(),
          ],
        ),
      ),
    );
  }
}
