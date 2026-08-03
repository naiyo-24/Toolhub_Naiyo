import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'dart:async';

class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({super.key});

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  final List<String> _laps = [];

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (mounted) setState(() {});
    });
    _stopwatch.start();
  }

  void _stopTimer() {
    _timer?.cancel();
    _stopwatch.stop();
    setState(() {});
  }

  void _resetTimer() {
    _stopTimer();
    _stopwatch.reset();
    _laps.clear();
    setState(() {});
  }

  void _addLap() {
    if (_stopwatch.isRunning) {
      setState(() {
        _laps.insert(0, _formatDuration(_stopwatch.elapsed));
      });
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String threeDigits(int n) => n.toString().padLeft(3, '0');
    
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    final milliseconds = threeDigits(d.inMilliseconds.remainder(1000)).substring(0, 2); // just 2 digits for UI
    
    if (d.inHours > 0) {
      final hours = twoDigits(d.inHours);
      return "$hours:$minutes:$seconds.$milliseconds";
    }
    return "$minutes:$seconds.$milliseconds";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = _stopwatch.isRunning;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryPurple,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Stopwatch',
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
                    "1. Tap the Play button to start the stopwatch.\n2. Tap Pause to halt the time.\n3. Tap the Reset icon to clear it.", style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            ),
            const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
            child: NeoCard(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  _formatDuration(_stopwatch.elapsed),
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: isRunning ? AppColors.primaryPink : AppColors.primaryGreen,
                  onTap: isRunning ? _stopTimer : _startTimer,
                ),
                _buildControlButton(
                  icon: Icons.flag_rounded,
                  color: AppColors.primaryYellow,
                  onTap: _addLap,
                ),
                _buildControlButton(
                  icon: Icons.replay_rounded,
                  color: AppColors.primaryBlue,
                  onTap: _resetTimer,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.black, thickness: 2, height: 1),
          Expanded(
            child: Container(
              color: AppColors.primaryPurple.withValues(alpha: 0.1),
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: _laps.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final lapNum = _laps.length - index;
                  return NeoCard(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Lap $lapNum', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                        Text(
                          _laps[index],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFeatures: [FontFeature.tabularFigures()]),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(3, 3),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black, size: 32),
      ),
    );
  }
}
