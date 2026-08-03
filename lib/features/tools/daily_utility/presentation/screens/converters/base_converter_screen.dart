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

class BaseConverterScreen extends ConsumerStatefulWidget {
  const BaseConverterScreen({super.key});

  @override
  ConsumerState<BaseConverterScreen> createState() => _BaseConverterScreenState();
}

class _BaseConverterScreenState extends ConsumerState<BaseConverterScreen> {

  List<Map<String, dynamic>> _history = [];
  static const String _historyKey = 'base_history';

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

  final _decController = TextEditingController();
  final _binController = TextEditingController();
  final _hexController = TextEditingController();
  final _octController = TextEditingController();

  bool _isUpdating = false;

  Future<void> _updateFromDecimal(String value) async {
    if (_isUpdating) return;
    _isUpdating = true;
    
    if (value.isEmpty) {
      _binController.clear();
      _hexController.clear();
      _octController.clear();
    } else {
      try {
        final responses = await Future.wait([
          ref.read(dailyUtilityServiceProvider).convertBinDec(value, 10, 2),
          ref.read(dailyUtilityServiceProvider).convertBinDec(value, 10, 16),
          ref.read(dailyUtilityServiceProvider).convertBinDec(value, 10, 8),
        ]);
        _binController.text = responses[0]['converted_value'];
        _hexController.text = responses[1]['converted_value'].toUpperCase();
        _octController.text = responses[2]['converted_value'];
      } catch (e) {
        int? dec = int.tryParse(value);
        if (dec != null) {
          _binController.text = dec.toRadixString(2);
          _hexController.text = dec.toRadixString(16).toUpperCase();
          _octController.text = dec.toRadixString(8);
        }
      }
    }
    
    _isUpdating = false;
  }

  Future<void> _updateFromBinary(String value) async {
    if (_isUpdating) return;
    _isUpdating = true;
    
    if (value.isEmpty) {
      _decController.clear();
      _hexController.clear();
      _octController.clear();
    } else {
      try {
        final responses = await Future.wait([
          ref.read(dailyUtilityServiceProvider).convertBinDec(value, 2, 10),
          ref.read(dailyUtilityServiceProvider).convertBinDec(value, 2, 16),
          ref.read(dailyUtilityServiceProvider).convertBinDec(value, 2, 8),
        ]);
        _decController.text = responses[0]['converted_value'];
        _hexController.text = responses[1]['converted_value'].toUpperCase();
        _octController.text = responses[2]['converted_value'];
      } catch (e) {
        int? dec = int.tryParse(value, radix: 2);
        if (dec != null) {
          _decController.text = dec.toString();
          _hexController.text = dec.toRadixString(16).toUpperCase();
          _octController.text = dec.toRadixString(8);
        }
      }
    }
    
    _isUpdating = false;
  }

  Future<void> _updateFromHex(String value) async {
    if (_isUpdating) return;
    _isUpdating = true;
    
    if (value.isEmpty) {
      _decController.clear();
      _binController.clear();
      _octController.clear();
    } else {
      try {
        final responses = await Future.wait([
          ref.read(dailyUtilityServiceProvider).convertBinDec(value, 16, 10),
          ref.read(dailyUtilityServiceProvider).convertBinDec(value, 16, 2),
          ref.read(dailyUtilityServiceProvider).convertBinDec(value, 16, 8),
        ]);
        _decController.text = responses[0]['converted_value'];
        _binController.text = responses[1]['converted_value'];
        _octController.text = responses[2]['converted_value'];
      } catch (e) {
        int? dec = int.tryParse(value, radix: 16);
        if (dec != null) {
          _decController.text = dec.toString();
          _binController.text = dec.toRadixString(2);
          _octController.text = dec.toRadixString(8);
        }
      }
    }
    
    _isUpdating = false;
  }

  Future<void> _updateFromOctal(String value) async {
    if (_isUpdating) return;
    _isUpdating = true;
    
    if (value.isEmpty) {
      _decController.clear();
      _binController.clear();
      _hexController.clear();
    } else {
      try {
        final responses = await Future.wait([
          ref.read(dailyUtilityServiceProvider).convertBinDec(value, 8, 10),
          ref.read(dailyUtilityServiceProvider).convertBinDec(value, 8, 2),
          ref.read(dailyUtilityServiceProvider).convertBinDec(value, 8, 16),
        ]);
        _decController.text = responses[0]['converted_value'];
        _binController.text = responses[1]['converted_value'];
        _hexController.text = responses[2]['converted_value'].toUpperCase();
      } catch (e) {
        int? dec = int.tryParse(value, radix: 8);
        if (dec != null) {
          _decController.text = dec.toString();
          _binController.text = dec.toRadixString(2);
          _hexController.text = dec.toRadixString(16).toUpperCase();
        }
      }
    }
    
    _isUpdating = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Base Converter',
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
                    "1. Enter a value in any of the fields (Decimal, Binary, Hex, or Octal).\n2. The other bases will automatically convert in real-time.", style: AppTextStyles.bodyText.copyWith(fontSize: 14),
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
                  const Text('Enter a value in any field below to convert:', style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 24),
                  _buildConverterField('Decimal (Base 10)', _decController, _updateFromDecimal, '0123456789'),
                  const SizedBox(height: 16),
                  _buildConverterField('Binary (Base 2)', _binController, _updateFromBinary, '01'),
                  const SizedBox(height: 16),
                  _buildConverterField('Hexadecimal (Base 16)', _hexController, _updateFromHex, '0123456789ABCDEFabcdef'),
                  const SizedBox(height: 16),
                  _buildConverterField('Octal (Base 8)', _octController, _updateFromOctal, '01234567'),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_decController.text.isNotEmpty) {
                          _saveToHistory(
                            'Dec: ${_decController.text}',
                            'Bin: ${_binController.text}\nHex: ${_hexController.text}\nOct: ${_octController.text}'
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      child: const Text('Save to History', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildConverterField(String label, TextEditingController controller, Function(String) onChanged, String allowedChars) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.sectionTitle.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
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
              borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
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
                  await prefs.remove('base_history');
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