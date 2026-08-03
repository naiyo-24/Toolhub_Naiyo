import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';

class AiNoteSummarizerScreen extends StatefulWidget {
  const AiNoteSummarizerScreen({super.key});

  @override
  State<AiNoteSummarizerScreen> createState() => _AiNoteSummarizerScreenState();
}

class _AiNoteSummarizerScreenState extends State<AiNoteSummarizerScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  List<Map<String, dynamic>> _history = [];
  bool _isSummarizing = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('ai_note_summarizer_history');
    if (historyJson != null) {
      final List<dynamic> decoded = json.decode(historyJson);
      setState(() {
        _history = List<Map<String, dynamic>>.from(decoded);
      });
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_note_summarizer_history', json.encode(_history));
  }

  void _deleteHistoryItem(int index) {
    setState(() {
      _history.removeAt(index);
    });
    _saveHistory();
  }

  Future<void> _summarize() async {
    final text = _textController.text.trim();
    final title = _titleController.text.trim();
    if (text.isEmpty || title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title and text to summarize')),
      );
      return;
    }

    setState(() {
      _isSummarizing = true;
    });

    // Mock summarization delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock summarize logic: Just taking the first few words and appending "..."
    final words = text.split(RegExp(r'\s+'));
    final summaryText = words.take(15).join(' ') + (words.length > 15 ? '...' : '');

    setState(() {
      _history.insert(0, {
        'title': title,
        'summary': summaryText,
        'original': text,
        'timestamp': DateTime.now().toIso8601String(),
      });
      if (_history.length > 10) {
        _history = _history.sublist(0, 10);
      }
      _isSummarizing = false;
    });

    _saveHistory();
    _titleController.clear();
    _textController.clear();
    // ignore: use_build_context_synchronously
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        centerTitle: true,
        title: Text('AI Note Summarizer', style: AppTextStyles.heroTitle.copyWith(fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Instructions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      "1. Give your note a title.\n2. Paste your long notes or text.\n3. Tap 'Summarize' to get a concise summary.",
                      style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: NeoCard(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Note Title...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _textController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: 'Paste your long text here to summarize...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.black, width: 2)),
                      ),
                      onPressed: _isSummarizing ? null : _summarize,
                      icon: _isSummarizing
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryBlue),
                      label: Text(_isSummarizing ? 'Summarizing...' : 'Summarize with AI', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
            
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: NeoCard(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Summarized Notes (Last 10)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 12),
                      ..._history.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            border: Border.all(color: Colors.black, width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(item['title'] ?? 'Summary', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_rounded, color: AppColors.primaryRed, size: 20),
                                    onPressed: () => _deleteHistoryItem(index),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.black26),
                              Text(item['summary'], style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ] else ...[
              const SizedBox(height: 40),
              const Center(child: Text('No summaries yet! Paste text above.', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ],
        ),
      ),
    );
  }
}
