import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import '../providers/internet_tools_providers.dart';

class SpeedTestScreen extends ConsumerStatefulWidget {
  const SpeedTestScreen({super.key});

  @override
  ConsumerState<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends ConsumerState<SpeedTestScreen> {
  Map<String, dynamic>? _result;
  bool _isLoading = false;
  String? _error;

  Future<void> _runSpeedTest() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final service = ref.read(internetToolsServiceProvider);
      final res = await service.runSpeedTest();
      setState(() {
        _result = res;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to run speed test. Please check your connection and try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
          'Speed Test',
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    "1. Tap 'Start Speed Test' to measure your network performance.\n2. Wait for the download and upload tests to complete.",
                    style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            NeoCard(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.speed, size: 60, color: AppColors.primaryYellow),
                  const SizedBox(height: 16),
                  Text(
                    'Test Your Connection',
                    style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This may take 10-30 seconds to complete.',
                    style: TextStyle(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryYellow,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      onPressed: _isLoading ? null : _runSpeedTest,
                      child: _isLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)),
                                SizedBox(width: 12),
                                Text('Testing...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            )
                          : const Text('Start Speed Test', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 20),
              Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
            if (_result != null) ...[
              const SizedBox(height: 20),
              NeoCard(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildStatRow('Download', '${_result!['download_mbps']} Mbps', Colors.green),
                    const Divider(color: Colors.black26, height: 24),
                    _buildStatRow('Upload', '${_result!['upload_mbps']} Mbps', Colors.blue),
                    const Divider(color: Colors.black26, height: 24),
                    _buildStatRow('Ping', '${_result!['ping_ms']} ms', Colors.purple),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold)),
        Text(
          value,
          style: AppTextStyles.heroTitle.copyWith(fontSize: 22, color: valueColor),
        ),
      ],
    );
  }
}
