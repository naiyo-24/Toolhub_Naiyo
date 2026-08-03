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

class UnitConverterScreen extends ConsumerStatefulWidget {
  const UnitConverterScreen({super.key});

  @override
  ConsumerState<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends ConsumerState<UnitConverterScreen> {

  List<Map<String, dynamic>> _history = [];
  static const String _historyKey = 'unit_history';

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

  final _inputController = TextEditingController();
  
  String _category = 'Length';
  String _fromUnit = 'Meters';
  String _toUnit = 'Feet';
  
  String _result = '0.0';

  final Map<String, List<String>> _units = {
    'Length': ['Meters', 'Kilometers', 'Centimeters', 'Millimeters', 'Miles', 'Yards', 'Feet', 'Inches'],
    'Weight': ['Kilograms', 'Grams', 'Milligrams', 'Pounds', 'Ounces'],
    'Temperature': ['Celsius', 'Fahrenheit', 'Kelvin'],
  };

  String _mapUnit(String unit) {
    final map = {
      'Meters': 'meter', 'Kilometers': 'kilometer', 'Centimeters': 'centimeter', 'Millimeters': 'millimeter',
      'Miles': 'mile', 'Yards': 'yard', 'Feet': 'foot', 'Inches': 'inch',
      'Kilograms': 'kilogram', 'Grams': 'gram', 'Milligrams': 'milligram', 'Pounds': 'pound', 'Ounces': 'ounce',
      'Celsius': 'celsius', 'Fahrenheit': 'fahrenheit', 'Kelvin': 'kelvin',
    };
    return map[unit] ?? unit.toLowerCase();
  }

  void _convert() async {
    double input = double.tryParse(_inputController.text) ?? 0.0;
    if (_inputController.text.isEmpty) {
      setState(() => _result = '0.0');
      return;
    }

    try {
      final result = await ref.read(dailyUtilityServiceProvider).convertUnit(
        input,
        _mapUnit(_fromUnit),
        _mapUnit(_toUnit),
      );

      setState(() {
        _result = (result['converted_value'] as num).toStringAsFixed(4).replaceAll(RegExp(r'([.]*0+)(?!.*\d)'), '');
        if (_result.endsWith('.')) _result = _result.substring(0, _result.length - 1);
      });
      _saveToHistory(
        '${_inputController.text} $_fromUnit to $_toUnit',
        '$_result $_toUnit'
      );
    } catch (e) {
      // Ignored for now or handle appropriately
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
          'Unit Converter',
          style: AppTextStyles.heroTitle.copyWith(fontSize: 20, color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
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
                    "1. Enter a value to convert.\n2. Select the starting unit and the target unit.\n3. Tap 'Convert' to see the result.", style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _units.keys.map((cat) {
                  final isSelected = _category == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _category = cat;
                          _fromUnit = _units[cat]!.first;
                          _toUnit = _units[cat]![1];
                        });
                        _convert();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.black : Colors.white,
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            NeoCard(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildDropdown('From', _fromUnit, (val) {
                    setState(() => _fromUnit = val!);
                    _convert();
                  }),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _inputController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'Enter value',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.black, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primaryYellow, width: 2),
                      ),
                    ),
                    onChanged: (_) => _convert(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryYellow,
              ),
              child: IconButton(
                icon: const Icon(Icons.swap_vert, color: Colors.black),
                onPressed: () {
                  setState(() {
                    String temp = _fromUnit;
                    _fromUnit = _toUnit;
                    _toUnit = temp;
                  });
                  _convert();
                },
              ),
            ),
            const SizedBox(height: 16),
            NeoCard(
              backgroundColor: AppColors.primaryYellow,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDropdown('To', _toUnit, (val) {
                    setState(() => _toUnit = val!);
                    _convert();
                  }, true),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _result,
                      style: AppTextStyles.heroTitle.copyWith(fontSize: 24, color: Colors.black),
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

  Widget _buildDropdown(String label, String value, ValueChanged<String?> onChanged, [bool isDark = false]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.sectionTitle.copyWith(fontSize: 12, color: isDark ? Colors.black54 : Colors.black54)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black),
              items: _units[_category]!.map((String unit) {
                return DropdownMenuItem<String>(
                  value: unit,
                  child: Text(unit, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
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
                  await prefs.remove('unit_history');
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