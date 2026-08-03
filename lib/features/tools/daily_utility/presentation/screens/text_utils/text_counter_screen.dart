import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import '../../providers/daily_utility_providers.dart';

class TextCounterScreen extends ConsumerStatefulWidget {
  const TextCounterScreen({super.key});

  @override
  ConsumerState<TextCounterScreen> createState() => _TextCounterScreenState();
}

class _TextCounterScreenState extends ConsumerState<TextCounterScreen> {
  final _inputController = TextEditingController();
  
  int _charCount = 0;
  int _charNoSpaceCount = 0;
  int _wordCount = 0;
  int _sentenceCount = 0;

  bool _isLoading = false;

  Future<void> _analyzeText() async {
    String text = _inputController.text;
    
    if (text.isEmpty) {
      setState(() {
        _charCount = 0;
        _charNoSpaceCount = 0;
        _wordCount = 0;
        _sentenceCount = 0;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ref.read(dailyUtilityServiceProvider).countText(text);

      setState(() {
        _charCount = result['characters'] as int? ?? 0;
        int spaces = result['spaces'] as int? ?? 0;
        _charNoSpaceCount = _charCount - spaces;
        _wordCount = result['words'] as int? ?? 0;
        _sentenceCount = result['lines'] as int? ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Fallback or error handling
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
          'Text Counter',
          style: AppTextStyles.heroTitle.copyWith(fontSize: 20, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
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
                    "1. Type or paste your text into the box.\n2. The app will automatically count your characters, words, and sentences in real-time.", style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            NeoCard(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Input Text', style: AppTextStyles.sectionTitle.copyWith(fontSize: 14)),
                      if (_isLoading) const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _inputController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: 'Type or paste text here...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.black, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.black, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primaryPink, width: 2),
                      ),
                    ),
                    onChanged: (_) => _analyzeText(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildStatCard('Characters', _charCount, Colors.white)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Words', _wordCount, AppColors.primaryPink, textColor: Colors.white)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard('Characters\n(No Spaces)', _charNoSpaceCount, Colors.white)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Lines', _sentenceCount, AppColors.primaryYellow)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color bgColor, {Color textColor = Colors.black}) {
    return NeoCard(
      backgroundColor: bgColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: AppTextStyles.heroTitle.copyWith(fontSize: 36, color: textColor),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor.withValues(alpha: 0.7), fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
