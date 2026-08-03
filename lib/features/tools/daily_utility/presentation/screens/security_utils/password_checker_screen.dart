import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import '../../providers/daily_utility_providers.dart';

class PasswordCheckerScreen extends ConsumerStatefulWidget {
  const PasswordCheckerScreen({super.key});

  @override
  ConsumerState<PasswordCheckerScreen> createState() => _PasswordCheckerScreenState();
}

class _PasswordCheckerScreenState extends ConsumerState<PasswordCheckerScreen> {

  List<Map<String, dynamic>> _history = [];
  static const String _historyKey = 'password_check_history';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyString = prefs.getString(_historyKey);
    if (historyString != null) {
      final List<dynamic> decoded = jsonDecode(historyString);
      setState(() {
        _history = decoded.cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> _saveToHistory(String title, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final entry = {
      'title': title,
      'value': value,
      'calculatedOn': DateFormat('dd MMM yyyy HH:mm').format(DateTime.now()),
    };
    _history.insert(0, entry);
    if (_history.length > 10) _history = _history.sublist(0, 10);
    await prefs.setString(_historyKey, jsonEncode(_history));
    setState(() {});
  }


  final _inputController = TextEditingController();
  
  String _strength = 'Empty';
  Color _strengthColor = Colors.grey;
  double _score = 0.0;
  List<String> _feedback = [];

  bool _isLoading = false;

  Future<void> _checkPassword() async {
    String p = _inputController.text;
    
    if (p.isEmpty) {
      setState(() {
        _strength = 'Empty';
        _strengthColor = Colors.grey;
        _score = 0.0;
        _feedback = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ref.read(dailyUtilityServiceProvider).checkPasswordStrength(p);

      double currentScore = (result['score'] as num).toDouble();
      String rawFeedback = result['feedback'] as String? ?? '';
      List<String> currentFeedback = rawFeedback.isNotEmpty ? [rawFeedback] : [];
      
      String sText = 'Weak';
      if (currentScore == 2) {
        sText = 'Moderate';
      } else if (currentScore == 3) {
        sText = 'Strong';
      } else if (currentScore == 4) {
        sText = 'Very Strong';
      }

      Color sColor = Colors.grey;
      if (sText.toLowerCase() == 'weak') {
        sColor = Colors.redAccent;
      } else if (sText.toLowerCase() == 'moderate') {
        sColor = Colors.orangeAccent;
      } else if (sText.toLowerCase() == 'strong') {
        sColor = Colors.greenAccent;
      } else if (sText.toLowerCase() == 'very strong') {
        sColor = Colors.green;
      }

      setState(() {
        _score = currentScore / 4.0; // The backend score is out of 4 (0 to 4)
        _strength = sText;
        _strengthColor = sColor;
        _feedback = currentFeedback;
        _isLoading = false;
      });
      _saveToHistory(
        'Password Checked',
        'Strength: $_strength'
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Fallback or handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryPurple,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Password Checker',
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
                    "1. Type or paste your password into the text field.\n2. Tap 'Check' to analyze its strength and get tips for improvement.", style: AppTextStyles.bodyText.copyWith(fontSize: 14),
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
                  Text('Enter Password', style: AppTextStyles.sectionTitle.copyWith(fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _inputController,
                    obscureText: false,
                    decoration: InputDecoration(
                      hintText: 'Type your password here...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.black54),
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
                        borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
                      ),
                    ),
                    onChanged: (_) => _checkPassword(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            NeoCard(
              backgroundColor: AppColors.primaryPurple,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Strength',
                    style: AppTextStyles.sectionTitle.copyWith(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _isLoading
                        ? const SizedBox(height: 32, width: 32, child: CircularProgressIndicator(color: Colors.white))
                        : Text(
                            _strength,
                            style: AppTextStyles.heroTitle.copyWith(color: Colors.white, fontSize: 32),
                          ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _strengthColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black45,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _strength == 'Strong' ? Icons.check_rounded :
                          _strength == 'Moderate' ? Icons.remove_rounded : Icons.close_rounded,
                          color: Colors.white,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _score,
                      minHeight: 12,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
                    ),
                  ),
                ],
              ),
            ),
            if (_feedback.isNotEmpty) ...[
              const SizedBox(height: 24),
              NeoCard(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How to improve:', style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
                    const SizedBox(height: 12),
                    ..._feedback.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.primaryPurple, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(f, style: const TextStyle(fontWeight: FontWeight.w600))),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildHistoryCard(),
            ],
          ],
        ),
      ),
    );
  }
  Widget _buildHistoryCard() {
    return NeoCard(
      backgroundColor: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent History', style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('password_check_history');
                  setState(() {
                    _history.clear();
                  });
                },
                child: const Text('Clear', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._history.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(entry['value'] ?? '', style: const TextStyle(color: Colors.black87, fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(entry['calculatedOn'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

}