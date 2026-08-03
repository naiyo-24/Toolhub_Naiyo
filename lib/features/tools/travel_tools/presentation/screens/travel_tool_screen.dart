import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';
import '../../data/travel_service.dart';

class TravelToolScreen extends StatefulWidget {
  final Map<String, dynamic> tool;

  const TravelToolScreen({super.key, required this.tool});

  @override
  State<TravelToolScreen> createState() => _TravelToolScreenState();
}

class _TravelToolScreenState extends State<TravelToolScreen> {
  final TravelService _service = TravelService();
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;
  Map<String, dynamic>? _results;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    final config = widget.tool['config'] as List<dynamic>?;
    if (config != null) {
      for (var field in config) {
        if (field['key'] != null) {
          _controllers[field['key']] = TextEditingController();
        }
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
    final config = widget.tool['config'] as List<dynamic>? ?? [];
    
    for (var entry in _controllers.entries) {
      final value = entry.value.text.trim();
      final fieldConfig = config.firstWhere((c) => c['key'] == entry.key);
      final type = fieldConfig['type'] ?? 'text';
      final isOptional = fieldConfig['label']?.toString().toLowerCase().contains('optional') ?? false;
      
      if (value.isEmpty && type != 'checkbox' && !isOptional) {
        SnackbarUtils.showNeoSnackBar(context, message: 'Please fill in all required fields');
        return;
      }
      
      if (type == 'number') {
        final sanitized = value.replaceAll(',', '.');
        data[entry.key] = num.tryParse(sanitized) ?? 0;
      } else if (type == 'checkbox') {
        data[entry.key] = value.toLowerCase() == 'true';
      } else {
        if (fieldConfig['key'] == 'timezones') {
          // parse comma separated list
          data[entry.key] = value.split(',').map((e) => e.trim()).toList();
        } else {
          data[entry.key] = value;
        }
      }
    }

    setState(() {
      _isLoading = true;
      _results = null;
    });

    try {
      final result = await _service.submit(widget.tool['endpoint'], data);
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

  Widget _buildListResult(List<dynamic> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: list.map((item) {
        if (item is Map) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: item.entries.map((e) {
                if (e.value is List) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_formatKey(e.key.toString())}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ...(e.value as List).map((v) => Text('  • $v')),
                    ],
                  );
                }
                return Text('${_formatKey(e.key.toString())}: ${e.value}', style: const TextStyle(fontWeight: FontWeight.bold));
              }).toList(),
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text('• $item'),
          );
        }
      }).toList(),
    );
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
                    // Limit the result preview to not be overwhelming
                    Text('Completed successfully. Expand tool to view full output again.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color, fontStyle: FontStyle.italic)),
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
    final config = widget.tool['config'] as List<dynamic>?;

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
            Text(widget.tool['subtitle'], style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 24),
            
            if (config != null)
              ...config.map((field) {
                final type = field['type'] ?? 'text';
                
                if (type == 'dropdown') {
                  final options = field['options'] as List<dynamic>;
                  if (_controllers[field['key']]!.text.isEmpty && options.isNotEmpty) {
                    _controllers[field['key']]!.text = options[0].toString();
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DropdownButtonFormField<String>(
                      initialValue: _controllers[field['key']]!.text,
                      items: options.map((opt) => DropdownMenuItem(value: opt.toString(), child: Text(opt.toString()))).toList(),
                      onChanged: (val) {
                         _controllers[field['key']]!.text = val ?? '';
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

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: _controllers[field['key']],
                    maxLines: null,
                    minLines: field['key'] == 'text' ? 3 : 1,
                    keyboardType: type == 'number' ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.multiline,
                    decoration: InputDecoration(
                      labelText: field['label'],
                      prefixIcon: field['key'] == 'text' ? null : Icon(field['icon'], color: color),
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
                _isLoading ? 'Processing...' : widget.tool['actionText'],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),

            if (_results != null) ...[
              const Text('Result', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              NeoCard(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _results!.entries.map((e) {
                    
                    Widget contentWidget;
                    if (e.value is List) {
                       contentWidget = _buildListResult(e.value as List);
                    } else if (e.value is Map) {
                       contentWidget = Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: (e.value as Map).entries.map((subE) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text('${_formatKey(subE.key.toString())}: ${subE.value}'),
                            );
                         }).toList(),
                       );
                    } else {
                       contentWidget = SelectableText(
                          e.value.toString(), 
                          style: TextStyle(fontSize: e.value.toString().length > 50 ? 16 : 18, fontWeight: FontWeight.w500, color: color)
                       );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_results!.length > 1) 
                                   Text(_formatKey(e.key), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                contentWidget,
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20, color: Colors.grey),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: e.value.toString()));
                              SnackbarUtils.showNeoSnackBar(context, message: 'Copied to clipboard');
                            },
                          ),
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
