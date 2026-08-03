import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';
import '../../data/health_service.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tool_hub/core/utils/permission_disclosure_utils.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


class HealthToolScreen extends StatefulWidget {
  final Map<String, dynamic> tool;

  const HealthToolScreen({
    super.key,
    required this.tool,
  });

  @override
  State<HealthToolScreen> createState() => _HealthToolScreenState();
}

class _HealthToolScreenState extends State<HealthToolScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _dropdownValues = {};
  bool _isLoading = false;
  Map<String, dynamic>? _results;
  final HealthService _service = HealthService();
  
  StreamSubscription<StepCount>? _stepCountStream;
  String _steps = '0';
  bool _isListeningSteps = false;
  String? _lastSyncedSteps;

  void _initPedometer() async {
    final hasPermission = await PermissionDisclosureUtils.requestWithDisclosure(
      context,
      permission: Permission.activityRecognition,
      title: 'Activity Recognition Permission',
      description: 'We need access to your physical activity to count your steps and provide accurate health metrics.',
      icon: Icons.directions_run_rounded,
      color: Colors.blue,
    );

    if (!hasPermission) {
      setState(() => _steps = 'Permission not granted');
      return;
    }

    if (await Permission.activityRecognition.request().isGranted) {
      _stepCountStream = Pedometer.stepCountStream.listen((StepCount event) {
        setState(() {
          _steps = event.steps.toString();
          if (_controllers.containsKey('steps')) {
            _controllers['steps']!.text = _steps;
          }
        });
      }, onError: (error) {
        setState(() => _steps = 'Step Count not available');
      });
      setState(() => _isListeningSteps = true);
    } else {
      if (mounted) {
        SnackbarUtils.showNeoSnackBar(context, message: 'Activity Recognition permission denied');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final config = widget.tool['config'] as List?;
    if (config != null) {
      for (var field in config) {
        if (field['type'] == 'dropdown') {
          _dropdownValues[field['key']] = field['options'][0];
        } else if (field['type'] != 'checkbox') {
          _controllers[field['key']] = TextEditingController();
        }
        
        if (field['type'] == 'live_pedometer') {
          _initPedometer();
        }
      }
    }
  }

  @override
  void dispose() {
    _stepCountStream?.cancel();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _calculate() async {
    if (widget.tool['endpoint'] == '/step-counter') {
      if (_steps == _lastSyncedSteps) {
        SnackbarUtils.showNeoSnackBar(context, message: 'These steps are already synced! Walk a bit more.');
        return;
      }
    }

    final Map<String, dynamic> data = {};
    
    // Collect dropdown values
    data.addAll(_dropdownValues);

    // Collect text values
    for (var entry in _controllers.entries) {
      final value = entry.value.text.trim();
      if (value.isEmpty) {
        // Optional fields can be skipped if empty, let backend handle it, or we could add 'required' logic.
        // For now, only send if not empty
        continue;
      }

      // Check if we need to parse as number
      final fieldConfig = (widget.tool['config'] as List).firstWhere((f) => f['key'] == entry.key);
      if (fieldConfig['type'] == 'number') {
        final parsedValue = double.tryParse(value);
        if (parsedValue != null) {
          // If it's an integer field, it should still be fine as a number.
          data[entry.key] = parsedValue;
        } else {
          SnackbarUtils.showNeoSnackBar(context, message: 'Invalid number format for ${fieldConfig['label']}');
          return;
        }
      } else {
        data[entry.key] = value;
      }
    }

    setState(() {
      _isLoading = true;
      _results = null;
    });

    try {
      final result = await _service.calculate(widget.tool['endpoint'], data);
      
      if (widget.tool['endpoint'] == '/medicine-alert') {
        await _service.scheduleMedicineAlarm(
          // ignore: use_build_context_synchronously
          context,
          data['medication_name'], 
          data['dosage'], 
          data['time_to_take']
        );
        if (mounted) {
          SnackbarUtils.showNeoSnackBar(context, message: 'Medicine Alarm scheduled successfully!');
        }
      }

      if (widget.tool['endpoint'] == '/water-tracker') {
        final amount = data['amount_ml']?.toString() ?? '250';
        final type = data['reminder_type']?.toString() ?? 'After 30 mins';
        final specificTime = data['specific_time']?.toString();
        
        // ignore: use_build_context_synchronously
        await _service.scheduleWaterAlarm(context, amount, type, specificTime);
        
        if (mounted) {
          SnackbarUtils.showNeoSnackBar(context, message: 'Water Reminder scheduled successfully!');
        }
      }

      if (widget.tool['endpoint'] == '/step-counter') {
        _lastSyncedSteps = _steps;
      }

      setState(() {
        _results = result;
      });
      await _saveHistory(widget.tool['title'], data, result);
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showNeoSnackBar(context, message: e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveHistory(String title, Map<String, dynamic> data, Map<String, dynamic> result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'history_$title';
      final historyList = prefs.getStringList(key) ?? [];
      
      final newRecord = {
        'timestamp': DateTime.now().toIso8601String(),
        'input': data,
        'result': result,
      };
      
      historyList.insert(0, jsonEncode(newRecord));
      if (historyList.length > 10) {
        historyList.removeLast();
      }
      
      await prefs.setStringList(key, historyList);
    } catch (e) {
      debugPrint('Failed to save history: $e');
    }
  }

  String _formatKey(String key) {
    return key.replaceAll('_', ' ').split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '').join(' ');
  }

  void _showManageAlarmsBottomSheet() async {
    final pendingAlarms = await _service.getPendingAlarms();
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                border: Border(top: BorderSide(color: Colors.black, width: 3), left: BorderSide(color: Colors.black, width: 3), right: BorderSide(color: Colors.black, width: 3)),
              ),
              padding: const EdgeInsets.all(24),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 6,
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(height: 24),
                  const Text('Active Reminders', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (pendingAlarms.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No active reminders found.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: pendingAlarms.length,
                        itemBuilder: (context, index) {
                          final alarm = pendingAlarms[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black, width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                            ),
                            child: ListTile(
                              leading: Icon(
                                alarm.title?.contains('Water') == true ? Icons.water_drop_rounded : Icons.medication_rounded,
                                color: widget.tool['color'],
                              ),
                              title: Text(alarm.title ?? 'Reminder', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(alarm.body ?? ''),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                onPressed: () async {
                                  await _service.cancelAlarm(alarm.id);
                                  setSheetState(() {
                                    pendingAlarms.removeAt(index);
                                  });
                                  if (mounted) {
                                    // ignore: use_build_context_synchronously
                                    SnackbarUtils.showNeoSnackBar(context, message: 'Reminder cancelled');
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (pendingAlarms.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await _service.cancelAllAlarms();
                          setSheetState(() {
                            pendingAlarms.clear();
                          });
                          if (mounted) {
                            // ignore: use_build_context_synchronously
                            SnackbarUtils.showNeoSnackBar(context, message: 'All reminders cancelled');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 2),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancel All Reminders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.tool['color'] as Color;
    final config = widget.tool['config'] as List? ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.tool['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (widget.tool['endpoint'] == '/medicine-alert' || widget.tool['endpoint'] == '/water-tracker')
            IconButton(
              icon: const Icon(Icons.alarm_on_rounded),
              tooltip: 'Manage Reminders',
              onPressed: _showManageAlarmsBottomSheet,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    "1. Fill in your health data or select options.\n2. Tap the action button below.\n3. View your personalized health metrics and insights.",
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.tool['subtitle'] ?? widget.tool['title'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            ...config.map((field) {
                if (field['type'] == 'dropdown') {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DropdownButtonFormField<String>(
                      initialValue: _dropdownValues[field['key']],
                      decoration: InputDecoration(
                        labelText: field['label'],
                        prefixIcon: Icon(field['icon'], color: color),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items: (field['options'] as List<String>).map((opt) {
                        return DropdownMenuItem(value: opt, child: Text(opt));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _dropdownValues[field['key']] = val;
                          });
                        }
                      },
                    ),
                  );
                }

                if (field['type'] == 'timepicker') {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextField(
                      controller: _controllers[field['key']],
                      readOnly: true,
                      onTap: () async {
                        final TimeOfDay? time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          final hh = time.hour.toString().padLeft(2, '0');
                          final mm = time.minute.toString().padLeft(2, '0');
                          _controllers[field['key']]!.text = '$hh:$mm:00';
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

                if (field['type'] == 'datepicker') {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextField(
                      controller: _controllers[field['key']],
                      readOnly: true,
                      onTap: () async {
                        final DateTime? date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          final yyyy = date.year.toString();
                          final mm = date.month.toString().padLeft(2, '0');
                          final dd = date.day.toString().padLeft(2, '0');
                          _controllers[field['key']]!.text = '$yyyy-$mm-$dd';
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

                if (field['type'] == 'live_pedometer') {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.directions_run_rounded, size: 64, color: color),
                          const SizedBox(height: 16),
                          Text(
                            _isListeningSteps ? _steps : 'Waiting for sensor...',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: _isListeningSteps ? color : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(field['label'], style: const TextStyle(color: Colors.grey)),
                        ],
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
                    keyboardType: field['type'] == 'number' ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
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
                    if (e.value is Map) {
                       return Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: (e.value as Map).entries.map((subE) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_formatKey(subE.key.toString()), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(subE.value.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 20, color: Colors.grey),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: subE.value.toString()));
                                      SnackbarUtils.showNeoSnackBar(context, message: 'Copied to clipboard');
                                    },
                                  ),
                                ],
                              ),
                            );
                         }).toList(),
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
                                SelectableText(
                                  e.value.toString(), 
                                  style: TextStyle(fontSize: e.value.toString().length > 50 ? 16 : 18, fontWeight: FontWeight.w500, color: color)
                                ),
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
            ]
          ],
        ),
      ),
    );
  }
}
