import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';
import '../../data/finance_service.dart';

class FinanceCalculatorScreen extends StatefulWidget {
  final Map<String, dynamic> tool;

  const FinanceCalculatorScreen({super.key, required this.tool});

  @override
  State<FinanceCalculatorScreen> createState() => _FinanceCalculatorScreenState();
}

class _FinanceCalculatorScreenState extends State<FinanceCalculatorScreen> {
  final FinanceService _service = FinanceService();
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;
  Map<String, dynamic>? _results;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    final config = widget.tool['config'] as List<Map<String, dynamic>>?;
    if (config != null) {
      for (var field in config) {
        _controllers[field['key']] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyList = prefs.getStringList('toolHistory') ?? [];
    
    setState(() {
      _history = historyList
          .map((item) => jsonDecode(item) as Map<String, dynamic>)
          .where((item) => item['toolName'] == widget.tool['title'])
          .toList();
    });
  }

  Future<void> _calculate() async {
    final Map<String, dynamic> data = {};
    for (var entry in _controllers.entries) {
      final value = entry.value.text.trim();
      if (value.isEmpty) {
        SnackbarUtils.showNeoSnackBar(context, message: 'Please fill in all fields');
        return;
      }
      
      // Parse boolean specifically for GST
      if (value.toLowerCase() == 'true') {
        data[entry.key] = true;
      } else if (value.toLowerCase() == 'false') {
        data[entry.key] = false;
      } else {
        // Try parsing as double for all numeric fields
        final number = double.tryParse(value);
        if (number == null && entry.key.contains('currency')) {
          // If it's a currency string (like 'USD')
          data[entry.key] = value.toUpperCase();
        } else if (number == null) {
          SnackbarUtils.showNeoSnackBar(context, message: 'Invalid number for ${entry.key}');
          return;
        } else {
          // Check if integer is required
          if (entry.key.contains('months') || entry.key.contains('years') || entry.key.contains('frequency')) {
            data[entry.key] = number.toInt();
          } else {
            data[entry.key] = number;
          }
        }
      }
    }

    setState(() {
      _isLoading = true;
      _results = null;
    });

    try {
      final result = await _service.calculate(widget.tool['endpoint'], data);
      setState(() {
        _results = result;
      });
      await _saveHistory(data, result);
    } catch (e) {
      if (mounted) SnackbarUtils.showNeoSnackBar(context, message: e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveHistory(Map<String, dynamic> data, Map<String, dynamic> result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = prefs.getStringList('toolHistory') ?? [];
      
      final historyItem = {
        'toolName': widget.tool['title'],
        'timestamp': DateTime.now().toIso8601String(),
        'inputs': data,
        'results': result,
      };
      
      historyList.insert(0, jsonEncode(historyItem));
      if (historyList.length > 10) {
        historyList.removeLast();
      }
      
      await prefs.setStringList('toolHistory', historyList);
      
      setState(() {
        _history = historyList
            .map((item) => jsonDecode(item) as Map<String, dynamic>)
            .where((item) => item['toolName'] == widget.tool['title'])
            .toList();
      });
    } catch (e) {
      debugPrint('Failed to save history: $e');
    }
  }

  String _formatKey(String key) {
    return key.replaceAll('_', ' ').split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '').join(' ');
  }

  Widget _buildHistoryCard() {
    final color = widget.tool['color'] as Color;
    return NeoCard(
      backgroundColor: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final historyList = prefs.getStringList('toolHistory') ?? [];
                  final newHistory = historyList.where((item) {
                    final decoded = jsonDecode(item) as Map<String, dynamic>;
                    return decoded['toolName'] != widget.tool['title'];
                  }).toList();
                  await prefs.setStringList('toolHistory', newHistory);
                  setState(() {
                    _history.clear();
                  });
                },
                child: const Text('Clear', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._history.map((entry) {
            final date = DateTime.parse(entry['timestamp'] as String);
            final formattedDate = DateFormat('MMM d, yyyy - h:mm a').format(date);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formattedDate, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    const SizedBox(height: 8),
                    const Text('Inputs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                    ...(entry['inputs'] as Map<String, dynamic>).entries.map((e) => Text('${_formatKey(e.key)}: ${e.value}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 8),
                    const Text('Results', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                    ...(entry['results'] as Map<String, dynamic>).entries.map((e) => Text('${_formatKey(e.key)}: ${e.value}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color))),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.tool['color'] as Color;
    final config = widget.tool['config'] as List<Map<String, dynamic>>?;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: color,
        title: Text(widget.tool['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const NeoCard(
              backgroundColor: Color(0xFFE0FBFC), // Light Blue tint
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.black),
                      SizedBox(width: 8),
                      Text('How to use', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    "1. Fill in all the required input fields.\n2. Tap the 'Calculate' or 'Action' button at the bottom.\n3. View your detailed breakdown in the results card.",
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(widget.tool['subtitle'], style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 24),
            
            if (config != null)
              ...config.map((field) {
                if (field['type'] == 'dropdown') {
                  final options = field['options'] as List<String>;
                  if (_controllers[field['key']]!.text.isEmpty && options.isNotEmpty) {
                    _controllers[field['key']]!.text = options[0];
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DropdownButtonFormField<String>(
                      initialValue: _controllers[field['key']]!.text,
                      items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          _controllers[field['key']]!.text = val;
                        }
                      },
                      decoration: InputDecoration(
                        labelText: field['label'],
                        prefixIcon: Icon(field['icon'], color: color),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  );
                }

                if (field['type'] == 'checkbox') {
                  if (_controllers[field['key']]!.text.isEmpty) {
                    _controllers[field['key']]!.text = 'false';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: StatefulBuilder(
                        builder: (context, setStateBuilder) {
                          bool isChecked = _controllers[field['key']]!.text == 'true';
                          return CheckboxListTile(
                            title: Text(field['label']),
                            value: isChecked,
                            onChanged: (val) {
                              if (val != null) {
                                setStateBuilder(() {
                                  _controllers[field['key']]!.text = val.toString();
                                });
                              }
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        }
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: _controllers[field['key']],
                    keyboardType: field['key'].contains('currency') ? TextInputType.text : const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: field['label'],
                      prefixIcon: Icon(field['icon'], color: color),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                );
              }),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? () {} : _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _isLoading ? 'Calculating...' : widget.tool['actionText'],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),

            if (_results != null) ...[
              const Text('Results', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              NeoCard(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: _results!.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatKey(e.key), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text(e.value.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildHistoryCard(),
            ],
          ],
        ),
      ),
    );
  }
}
