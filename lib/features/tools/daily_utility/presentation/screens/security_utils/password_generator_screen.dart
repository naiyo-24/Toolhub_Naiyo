import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';
import '../../providers/daily_utility_providers.dart';

class PasswordGeneratorScreen extends ConsumerStatefulWidget {
  const PasswordGeneratorScreen({super.key});

  @override
  ConsumerState<PasswordGeneratorScreen> createState() => _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends ConsumerState<PasswordGeneratorScreen> {

  List<Map<String, dynamic>> _history = [];
  static const String _historyKey = 'password_gen_history';


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

  Future<void> _saveToHistory(String input, String result) async {
    final prefs = await SharedPreferences.getInstance();
    final entry = {
      'input': input,
      'result': result,
      'calculatedOn': DateFormat('dd MMM yyyy HH:mm').format(DateTime.now()),
    };
    _history.insert(0, entry);
    if (_history.length > 10) _history = _history.sublist(0, 10);
    await prefs.setString(_historyKey, jsonEncode(_history));
    setState(() {});
  }

  String _generatedPassword = 'Password will appear here';
  double _passwordLength = 16;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _generatePassword();
  }

  bool _isLoading = false;

  void _generatePassword() async {
    if (!_includeUppercase && !_includeLowercase && !_includeNumbers && !_includeSymbols) {
      setState(() => _generatedPassword = 'Select at least one option');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ref.read(dailyUtilityServiceProvider).generatePassword(
        length: _passwordLength.toInt(),
        includeUppercase: _includeUppercase,
        includeLowercase: _includeLowercase,
        includeNumbers: _includeNumbers,
        includeSymbols: _includeSymbols,
      );

      setState(() {
        _generatedPassword = result['password'] as String;
        _isLoading = false;
      });
      _saveToHistory(
        'Length: ${_passwordLength.toInt()}',
        _generatedPassword
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _generatedPassword = 'Error generating password';
      });
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _generatedPassword));
    SnackbarUtils.showNeoSnackBar(context, message: 'Password copied to clipboard!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Password Generator',
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
                    "1. Choose your desired password length.\n2. Toggle uppercase, lowercase, numbers, and symbols.\n3. Tap 'Regenerate' to create a new password.", style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            NeoCard(
              backgroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator())
                      : SelectableText(
                          _generatedPassword,
                          style: AppTextStyles.heroTitle.copyWith(
                            fontSize: 24,
                            color: Colors.black,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _copyToClipboard,
                    icon: const Icon(Icons.copy_rounded, color: Colors.black),
                    label: const Text('Copy Password', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryYellow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            NeoCard(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Password Length: ${_passwordLength.toInt()}', style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
                  Slider(
                    value: _passwordLength,
                    min: 8,
                    max: 32,
                    divisions: 24,
                    activeColor: AppColors.primaryBlue,
                    inactiveColor: Colors.grey[300],
                    thumbColor: AppColors.primaryBlue,
                    onChanged: (val) {
                      setState(() => _passwordLength = val);
                      _generatePassword();
                    },
                  ),
                  const Divider(color: Colors.black26, thickness: 1),
                  _buildOptionSwitch('Uppercase Letters (A-Z)', _includeUppercase, (val) {
                    setState(() => _includeUppercase = val);
                    _generatePassword();
                  }),
                  _buildOptionSwitch('Lowercase Letters (a-z)', _includeLowercase, (val) {
                    setState(() => _includeLowercase = val);
                    _generatePassword();
                  }),
                  _buildOptionSwitch('Numbers (0-9)', _includeNumbers, (val) {
                    setState(() => _includeNumbers = val);
                    _generatePassword();
                  }),
                  _buildOptionSwitch('Symbols (!@#\$...)', _includeSymbols, (val) {
                    setState(() => _includeSymbols = val);
                    _generatePassword();
                  }),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _generatePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Regenerate',
                        style: AppTextStyles.buttonText.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildHistoryCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionSwitch(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primaryBlue,
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
                  await prefs.remove('password_gen_history');
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
                            Text(entry['input'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(entry['result'] ?? '', style: const TextStyle(color: Colors.black87, fontSize: 13)),
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