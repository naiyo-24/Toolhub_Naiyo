import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'dart:async';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  int _setSeconds = 0;
  int _remainingSeconds = 0;
  Timer? _timer;
  bool _isRunning = false;

  void _startTimer() {
    if (_remainingSeconds > 0 && !_isRunning) {
      setState(() {
        _isRunning = true;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          _stopTimer();
          FlutterRingtonePlayer().playAlarm();
        }
      });
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _stopTimer();
    FlutterRingtonePlayer().stop();
    setState(() {
      _remainingSeconds = _setSeconds;
    });
  }

  void _addTime(int seconds) {
    if (!_isRunning) {
      setState(() {
        _setSeconds += seconds;
        _remainingSeconds = _setSeconds;
      });
    }
  }

  void _clearTime() {
    if (!_isRunning) {
      FlutterRingtonePlayer().stop();
      setState(() {
        _setSeconds = 0;
        _remainingSeconds = 0;
      });
    }
  }

  Future<void> _showCustomTimeDialog() async {
    if (_isRunning) return;

    int h = 0, m = 0, s = 0;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
            side: const BorderSide(color: Colors.black, width: 2),
          ),
          title: const Text('Custom Time', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimeInput('H', (val) => h = val),
              const Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              _buildTimeInput('M', (val) => m = val),
              const Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              _buildTimeInput('S', (val) => s = val),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                side: const BorderSide(color: Colors.black, width: 2),
              ),
              onPressed: () {
                setState(() {
                  _setSeconds = (h * 3600) + (m * 60) + s;
                  _remainingSeconds = _setSeconds;
                });
                Navigator.pop(context);
              },
              child: const Text('Set'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeInput(String label, Function(int) onChanged) {
    return SizedBox(
      width: 60,
      child: TextField(
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 14),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Colors.black, width: 2),
          ),
        ),
        onChanged: (val) => onChanged(int.tryParse(val) ?? 0),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    int h = totalSeconds ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    int s = totalSeconds % 60;

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    if (h > 0) {
      return "${twoDigits(h)}:${twoDigits(m)}:${twoDigits(s)}";
    }
    return "${twoDigits(m)}:${twoDigits(s)}";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = _setSeconds > 0 ? _remainingSeconds / _setSeconds : 1.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryPink,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Timer',
          style: AppTextStyles.heroTitle.copyWith(fontSize: 20, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
            // Instructions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                    "1. Scroll to set desired hours, minutes, and seconds.\n2. Tap 'Start' to begin the countdown.\n3. Tap 'Pause' or 'Reset' as needed.", style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            ),
            const SizedBox(height: 20),

          const SizedBox(height: 48),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 250,
                height: 250,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 20,
                  backgroundColor: Colors.black12,
                  color: AppColors.primaryPink,
                ),
              ),
              GestureDetector(
                onTap: _showCustomTimeDialog,
                child: Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatTime(_remainingSeconds),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (!_isRunning && _setSeconds == 0)
                        const Text(
                          'Tap to custom edit',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          if (!_isRunning && _setSeconds == 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _buildTimeAdder('+ 10s', 10),
                  _buildTimeAdder('+ 1m', 60),
                  _buildTimeAdder('+ 5m', 300),
                  _buildTimeAdder('+ 10m', 600),
                  _buildTimeAdder('+ 30m', 1800),
                ],
              ),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!_isRunning && _setSeconds > 0 && _remainingSeconds == _setSeconds)
                  _buildControlButton(
                    icon: Icons.close_rounded,
                    color: Colors.white,
                    onTap: _clearTime,
                  ),
                if (_setSeconds > 0)
                  _buildControlButton(
                    icon: _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: _isRunning ? AppColors.primaryYellow : AppColors.primaryGreen,
                    onTap: _isRunning ? _stopTimer : _startTimer,
                  ),
                if (_setSeconds > 0 && (_remainingSeconds < _setSeconds || !_isRunning))
                  _buildControlButton(
                    icon: Icons.replay_rounded,
                    color: AppColors.primaryBlue,
                    onTap: _resetTimer,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeAdder(String label, int seconds) {
    return GestureDetector(
      onTap: () => _addTime(seconds),
      child: NeoCard(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(4, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black, size: 36),
      ),
    );
  }
}
