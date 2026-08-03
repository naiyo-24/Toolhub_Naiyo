import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import '../providers/internet_tools_providers.dart';

class IpFinderScreen extends ConsumerStatefulWidget {
  const IpFinderScreen({super.key});

  @override
  ConsumerState<IpFinderScreen> createState() => _IpFinderScreenState();
}

class _IpFinderScreenState extends ConsumerState<IpFinderScreen> {
  final _ipController = TextEditingController();
  Map<String, dynamic>? _result;
  bool _isLoading = false;
  String? _error;
  String? _localIp;

  @override
  void initState() {
    super.initState();
    // Auto-fetch own IP on load
    _fetchLocalIp();
    _lookupIp('');
  }

  Future<void> _fetchLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLoopback: false);
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            setState(() {
              _localIp = addr.address;
            });
            return;
          }
        }
      }
    } catch (_) {
      // Ignore
    }
  }

  Future<void> _lookupIp(String ip) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final service = ref.read(internetToolsServiceProvider);
      final res = await service.lookupIp(ip);
      setState(() {
        _result = res;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to lookup IP address.';
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
        backgroundColor: AppColors.primaryOrange,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'IP Finder',
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
                    "1. Enter a domain or IP address.\n2. Tap 'Find IP details' to view its geographic location and ISP details.",
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
                  Text('Lookup Specific IP (Optional)', style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ipController,
                    decoration: InputDecoration(
                      hintText: 'e.g. 8.8.8.8',
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
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      onPressed: _isLoading ? null : () => _lookupIp(_ipController.text.trim()),
                      child: _isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Lookup IP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_localIp != null && _ipController.text.trim().isEmpty) ...[
                      _buildStatRow('Local Network IP', _localIp!),
                      const Divider(color: Colors.black26, height: 24),
                    ],
                    _buildStatRow('Public IP Address', _result!['ip']?.toString() ?? 'N/A'),
                    const Divider(color: Colors.black26, height: 24),
                    if (_result!.containsKey('message')) ...[
                      Text(_result!['message'], style: const TextStyle(color: Colors.red)),
                    ] else ...[
                      _buildStatRow('Country', _result!['country']?.toString() ?? 'N/A'),
                      const Divider(color: Colors.black26, height: 24),
                      _buildStatRow('City', _result!['city']?.toString() ?? 'N/A'),
                      const Divider(color: Colors.black26, height: 24),
                      _buildStatRow('Latitude', _result!['latitude']?.toString() ?? 'N/A'),
                      const Divider(color: Colors.black26, height: 24),
                      _buildStatRow('Longitude', _result!['longitude']?.toString() ?? 'N/A'),
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

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyText.copyWith(color: AppColors.primaryOrange, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
