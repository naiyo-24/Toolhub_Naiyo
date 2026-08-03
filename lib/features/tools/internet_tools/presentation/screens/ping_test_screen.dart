import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import '../providers/internet_tools_providers.dart';

class PingTestScreen extends ConsumerStatefulWidget {
  const PingTestScreen({super.key});

  @override
  ConsumerState<PingTestScreen> createState() => _PingTestScreenState();
}

class _PingTestScreenState extends ConsumerState<PingTestScreen> {
  final _hostController = TextEditingController();
  Map<String, dynamic>? _result;
  bool _isLoading = false;
  String? _error;

  Future<void> _pingTest() async {
    final host = _hostController.text.trim();
    if (host.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final service = ref.read(internetToolsServiceProvider);
      final res = await service.pingTest(host);
      setState(() {
        _result = res;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to ping host.';
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
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'PING Test',
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
                    "1. Enter a hostname or IP address.\n2. Tap 'Start Ping' to measure latency and packet loss.\n3. View real-time ping statistics.",
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Enter Hostname or IP', style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _hostController,
                    decoration: InputDecoration(
                      hintText: 'e.g. google.com or 8.8.8.8',
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
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      onPressed: _isLoading ? null : _pingTest,
                      child: _isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Start PING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                backgroundColor: (_result!['is_reachable'] as bool) ? Colors.white : Colors.red.withValues(alpha: 0.1),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildStatRow('Reachable', (_result!['is_reachable'] as bool) ? 'YES' : 'NO', (_result!['is_reachable'] as bool) ? AppColors.primaryGreen : Colors.red),
                    if (_result!.containsKey('latency_ms')) ...[
                      const Divider(color: Colors.black26, height: 24),
                      _buildStatRow('Latency', '${_result!['latency_ms']} ms', Colors.black),
                    ],
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
          style: AppTextStyles.heroTitle.copyWith(fontSize: 18, color: valueColor),
        ),
      ],
    );
  }
}
