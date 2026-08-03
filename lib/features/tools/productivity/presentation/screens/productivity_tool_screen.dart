import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:tool_hub/core/utils/permission_disclosure_utils.dart';
import 'package:tool_hub/features/tools/daily_utility/data/calendar_service.dart';
import 'package:tool_hub/features/tools/daily_utility/data/models/calendar_event.dart';

class ProductivityToolScreen extends StatefulWidget {
  final Map<String, dynamic> tool;

  const ProductivityToolScreen({super.key, required this.tool});

  @override
  State<ProductivityToolScreen> createState() => _ProductivityToolScreenState();
}

class _ProductivityToolScreenState extends State<ProductivityToolScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _dropdownValues = {};
  final Map<String, dynamic> _dateValues = {};
  
  bool _isLoading = false;

  // Voice recording state
  final _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordedFilePath;

  StreamSubscription? _playerStateSubscription;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  // Timer state
  int _timerSetSeconds = 0;
  int _timerRemainingSeconds = 0;
  Timer? _countdownTimer;
  bool _timerIsRunning = false;
  
  List<dynamic> _historyItems = [];
  // ignore: unused_field
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    final config = widget.tool['config'] as List?;
    if (config != null) {
      _initTimer(config);
      for (var field in config) {
        if (field['type'] == 'dropdown') {
          _dropdownValues[field['key']] = field['options'][0];
        } else if (field['type'] != 'voice_recorder' && field['type'] != 'datepicker' && field['type'] != 'timepicker' && field['type'] != 'pomodoro_timer') {
          _controllers[field['key']] = TextEditingController();
        }
      }
    }
    
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
    
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _audioDuration = d);
    });
    
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _audioPosition = p);
    });
    
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _audioPosition = Duration.zero;
        });
      }
    });
    
    _loadHistory();
    if (widget.tool['title'] == 'Clipboard') {
      _syncClipboard();
    }
  }

  Future<void> _syncClipboard() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      if (_controllers.containsKey('content')) {
        setState(() {
          _controllers['content']!.text = data.text!;
        });
      }
    }
  }

  void _initTimer(List<dynamic> config) {
    for (var field in config) {
      if (field['type'] == 'pomodoro_timer') {
        int minutes = field['default_minutes'] ?? 25;
        setState(() {
          _timerSetSeconds = minutes * 60;
          _timerRemainingSeconds = _timerSetSeconds;
        });
      }
    }
  }

  void _startTimer() {
    if (_timerRemainingSeconds == 0) {
      if (_controllers.containsKey('duration_minutes')) {
        int? mins = int.tryParse(_controllers['duration_minutes']!.text);
        if (mins != null && mins > 0) {
          _timerSetSeconds = mins * 60;
          _timerRemainingSeconds = _timerSetSeconds;
        }
      }
    }
    
    if (_timerRemainingSeconds > 0 && !_timerIsRunning) {
      setState(() => _timerIsRunning = true);
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timerRemainingSeconds > 0) {
          setState(() => _timerRemainingSeconds--);
        } else {
          _stopTimer();
          _audioPlayer.setReleaseMode(ReleaseMode.loop);
          _audioPlayer.play(AssetSource('sound/universfield-ringtone.mp3'));
          
          if (mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Time is up!'),
                content: const Text('Your focus session has completed.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      _audioPlayer.stop();
                      Navigator.pop(ctx);
                      
                      if (!_controllers.containsKey('duration_minutes') || _controllers['duration_minutes']!.text.isEmpty) {
                         _controllers['duration_minutes'] ??= TextEditingController();
                         _controllers['duration_minutes']!.text = _timerSetSeconds > 0 ? (_timerSetSeconds ~/ 60).toString() : '25';
                      }
                      
                      _submit();
                    },
                    child: const Text('OK'),
                  )
                ],
              )
            );
          }
        }
      });
    }
  }

  void _stopTimer({bool isDisposing = false}) {
    _countdownTimer?.cancel();
    if (!isDisposing && mounted) {
      setState(() => _timerIsRunning = false);
    }
  }

  void _resetTimer() {
    _stopTimer();
    _audioPlayer.stop();
    setState(() => _timerRemainingSeconds = _timerSetSeconds);
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyList = prefs.getStringList('toolHistory') ?? [];
    
    setState(() {
      _historyItems = historyList
          .map((item) => jsonDecode(item) as Map<String, dynamic>)
          .where((item) => item['toolName'] == widget.tool['title'])
          .toList();
      _isLoadingHistory = false;
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _audioPlayer.dispose();
    _playerStateSubscription?.cancel();
    _audioRecorder.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    try {
      final hasMicPermission = await PermissionDisclosureUtils.requestWithDisclosure(
        context,
        permission: Permission.microphone,
        title: 'Microphone Permission',
        description: 'We need access to your microphone so you can record voice notes.',
        icon: Icons.mic,
        color: widget.tool['color'],
      );

      if (!hasMicPermission) {
        if (mounted) SnackbarUtils.showNeoSnackBar(context, message: 'Microphone permission denied.', isError: true);
        return;
      }

      if (!await _audioRecorder.hasPermission()) {
        if (mounted) SnackbarUtils.showNeoSnackBar(context, message: 'Microphone permission required to record.');
        return;
      }

      if (_isRecording) {
        final path = await _audioRecorder.stop();
        setState(() {
          _isRecording = false;
          _recordedFilePath = path;
        });
        if (mounted) SnackbarUtils.showNeoSnackBar(context, message: 'Audio recorded successfully!');
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() {
          _isRecording = true;
          _recordedFilePath = null;
          _isPlaying = false;
        });
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showNeoSnackBar(context, message: 'Error: $e');
    }
  }


  Future<void> _selectDate(String key) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateValues[key] = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _selectTime(String key) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _dateValues[key] = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00";
      });
    }
  }

  Future<void> _submit() async {
    final Map<String, dynamic> data = {};
    
    data.addAll(_dropdownValues);

    for (var entry in _dateValues.entries) {
      if (entry.key == 'trigger_time' && entry.value.length <= 8) {
        final now = DateTime.now();
        final datePart = _dateValues.containsKey('trigger_date') 
                         ? _dateValues['trigger_date'] 
                         : "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        data[entry.key] = "${datePart}T${entry.value}";
      } else {
        data[entry.key] = entry.value;
      }
    }

    for (var entry in _controllers.entries) {
      final value = entry.value.text.trim();
      if (value.isNotEmpty) {
        final configList = widget.tool['config'] as List? ?? [];
        final matching = configList.where((f) => f['key'] == entry.key);
        final fieldConfig = matching.isNotEmpty ? matching.first : null;
        
        if (fieldConfig != null && fieldConfig['type'] == 'number') {
          data[entry.key] = double.tryParse(value) ?? value;
        } else {
          data[entry.key] = value;
        }
      }
    }
    
    final hasTimer = (widget.tool['config'] as List?)?.any((f) => f['type'] == 'pomodoro_timer') ?? false;
    if (hasTimer && !data.containsKey('duration_minutes')) {
      data['duration_minutes'] = _timerSetSeconds > 0 ? (_timerSetSeconds ~/ 60) : 25;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.tool['endpoint'] == '/productivity-tools/voice-notes' && _recordedFilePath != null) {
         data['voice_note'] = _recordedFilePath;
      }
      
      if (widget.tool['title'] == 'Clipboard' && data.containsKey('content')) {
        await Clipboard.setData(ClipboardData(text: data['content'].toString()));
      }
      
      if (widget.tool['title'] == 'Reminder' && data.containsKey('trigger_time')) {
        final dt = DateTime.tryParse(data['trigger_time'].toString());
        if (dt != null) {
          final calendarService = CalendarService();
          await calendarService.init();
          
          final event = CalendarEvent(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: data['title']?.toString() ?? 'Reminder',
            description: 'Reminder set from Productivity tools',
            dateTime: dt,
            hasReminder: true,
          );
          
          await calendarService.scheduleNotification(event);
        }
      }
      
      await _saveHistory(data, {'status': 'success'});

      for (var controller in _controllers.values) {
        controller.clear();
      }
      _recordedFilePath = null;
      _isPlaying = false;
      
      _resetTimer();
      
      if (mounted) {
        SnackbarUtils.showNeoSnackBar(context, message: '${widget.tool['title']} saved successfully!');
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showNeoSnackBar(context, message: e.toString(), isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
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
        _historyItems = historyList
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
                    _historyItems.clear();
                  });
                },
                child: const Text('Clear', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._historyItems.map((entry) {
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
                    ...(entry['inputs'] as Map<String, dynamic>).entries.map((e) {
                      if (e.key == 'voice_note') {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Voice Recording', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              _buildAudioPlayerUI(e.value.toString()),
                            ],
                          ),
                        );
                      }
                      
                      if (widget.tool['title'] == 'Clipboard') {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: Text('${_formatKey(e.key)}: ${e.value}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: e.value.toString()));
                                  if (mounted) SnackbarUtils.showNeoSnackBar(context, message: 'Copied to system clipboard!');
                                },
                              )
                            ],
                          ),
                        );
                      }
                      
                      return Text('${_formatKey(e.key)}: ${e.value}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold));
                    }),
                    const SizedBox(height: 8),
                    const Text('Results', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                    Text('Completed locally.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  String? _currentlyPlayingPath;

  Future<void> _playAudio(String path) async {
    if (_isPlaying && _currentlyPlayingPath == path) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(DeviceFileSource(path));
      setState(() => _currentlyPlayingPath = path);
    }
  }

  Widget _buildAudioPlayerUI(String path) {
    final isThisPlaying = _currentlyPlayingPath == path;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isThisPlaying ? _formatDuration(_audioPosition) : "00:00", style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(isThisPlaying ? _formatDuration(_audioDuration) : "00:00", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: Colors.black,
              inactiveTrackColor: Colors.grey.shade300,
              thumbColor: Colors.black,
            ),
            child: Slider(
              min: 0,
              max: (isThisPlaying && _audioDuration.inMilliseconds > 0) ? _audioDuration.inMilliseconds.toDouble() : 1.0,
              value: (isThisPlaying) ? _audioPosition.inMilliseconds.toDouble().clamp(0.0, _audioDuration.inMilliseconds > 0 ? _audioDuration.inMilliseconds.toDouble() : 1.0) : 0.0,
              onChanged: (value) {
                if (isThisPlaying) _audioPlayer.seek(Duration(milliseconds: value.toInt()));
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10),
                iconSize: 32,
                color: Colors.black,
                onPressed: () {
                  if (isThisPlaying) {
                    final newPos = _audioPosition - const Duration(seconds: 10);
                    _audioPlayer.seek(newPos < Duration.zero ? Duration.zero : newPos);
                  }
                },
              ),
              IconButton(
                icon: Icon((_isPlaying && isThisPlaying) ? Icons.pause_circle_filled : Icons.play_circle_filled),
                color: Colors.black,
                iconSize: 48,
                onPressed: () => _playAudio(path),
              ),
              IconButton(
                icon: const Icon(Icons.forward_10),
                iconSize: 32,
                color: Colors.black,
                onPressed: () {
                  if (isThisPlaying) {
                    final newPos = _audioPosition + const Duration(seconds: 10);
                    _audioPlayer.seek(newPos > _audioDuration ? _audioDuration : newPos);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFormFields() {
    final config = widget.tool['config'] as List<dynamic>?;
    if (config == null) return [];
    
    return config.map((field) {
      final type = field['type'];
      final key = field['key'];
      final label = field['label'];
      
      Widget inputWidget;
      
      if (type == 'textarea') {
        inputWidget = TextField(
          controller: _controllers[key],
          maxLines: 5,
          decoration: InputDecoration(
            hintText: field['placeholder'],
            border: const OutlineInputBorder(),
          ),
        );
      } else if (type == 'dropdown') {
        inputWidget = DropdownButtonFormField<String>(
          initialValue: _dropdownValues[key],
          items: (field['options'] as List<dynamic>).map((opt) => DropdownMenuItem<String>(
            value: opt.toString(),
            child: Text(opt.toString()),
          )).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _dropdownValues[key] = val);
          },
          decoration: const InputDecoration(border: OutlineInputBorder()),
        );
      } else if (type == 'voice_recorder') {
        inputWidget = Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _toggleRecording,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 3),
                      boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                    ),
                    child: Icon(_isRecording ? Icons.stop : Icons.mic, size: 48, color: _isRecording ? Colors.white : Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(_isRecording ? 'Recording...' : (_recordedFilePath != null ? 'Recording saved!' : 'Tap to record')),
            if (_recordedFilePath != null && !_isRecording) ...[
              const SizedBox(height: 16),
              _buildAudioPlayerUI(_recordedFilePath!),
            ],
          ],
        );
      } else if (type == 'pomodoro_timer') {
        final min = _timerRemainingSeconds ~/ 60;
        final sec = _timerRemainingSeconds % 60;
        final timeStr = '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
        
        inputWidget = Column(
          children: [
            Text(timeStr, style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _timerIsRunning ? _stopTimer : _startTimer,
                  style: ElevatedButton.styleFrom(backgroundColor: _timerIsRunning ? Colors.orange : Colors.green),
                  child: Text(_timerIsRunning ? 'Pause' : 'Start', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _resetTimer,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Reset', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ],
        );
      } else if (type == 'datepicker') {
        inputWidget = InkWell(
          onTap: () => _selectDate(key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_dateValues[key] ?? 'Select Date'),
                const Icon(Icons.calendar_today),
              ],
            ),
          ),
        );
      } else if (type == 'timepicker') {
        inputWidget = InkWell(
          onTap: () => _selectTime(key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_dateValues[key] ?? 'Select Time'),
                const Icon(Icons.access_time),
              ],
            ),
          ),
        );
      } else {
        inputWidget = TextField(
          controller: _controllers[key],
          keyboardType: type == 'number' ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: field['placeholder'],
            border: const OutlineInputBorder(),
          ),
        );
      }
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null) ...[
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
            ],
            inputWidget,
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.tool['color'] as Color;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: color,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.tool['title'],
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const NeoCard(
                backgroundColor: Color(0xFFE0FBFC),
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
                      "1. Fill in the required details or perform the task.\n2. Tap the action button at the bottom to save or execute.\n3. Your items and history will appear in the list below.",
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              NeoCard(
                backgroundColor: color,
                padding: const EdgeInsets.all(20),
                borderRadius: 16,
                child: Row(
                  children: [
                    Icon(widget.tool['icon'], size: 40, color: Colors.white),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.tool['subtitle'] ?? 'Fill out the details below',
                        style: AppTextStyles.bodyText.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ..._buildFormFields(),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                GestureDetector(
                  onTap: _submit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black, offset: Offset(4, 4)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.tool['actionText'] ?? 'Submit',
                      style: AppTextStyles.sectionTitle.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              if (_historyItems.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildHistoryCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
