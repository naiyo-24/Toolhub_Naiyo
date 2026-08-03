import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import '../providers/internet_tools_providers.dart';

class DnsLookupScreen extends ConsumerStatefulWidget {
  const DnsLookupScreen({super.key});

  @override
  ConsumerState<DnsLookupScreen> createState() => _DnsLookupScreenState();
}

class _DnsLookupScreenState extends ConsumerState<DnsLookupScreen> {
  final _domainController = TextEditingController();
  Map<String, dynamic>? _result;
  bool _isLoading = false;
  String? _error;

  Future<void> _lookupDns() async {
    final domain = _domainController.text.trim();
    if (domain.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final service = ref.read(internetToolsServiceProvider);
      final res = await service.lookupDns(domain);
      setState(() {
        _result = res;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to lookup DNS records.';
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
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'DNS Lookup',
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
                    "1. Enter a domain name (e.g., google.com).\n2. Select the record type (A, MX, TXT, etc.).\n3. Tap 'Lookup' to retrieve the DNS records.",
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
                  Text('Enter Domain Name', style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _domainController,
                    decoration: InputDecoration(
                      hintText: 'e.g. google.com',
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
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      onPressed: _isLoading ? null : _lookupDns,
                      child: _isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Lookup DNS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                    Text('DNS Records for ${_result!['domain']}', style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
                    const Divider(color: Colors.black26, height: 24),
                    ...['A', 'MX', 'TXT', 'NS'].map((type) {
                      final records = _result!['records'][type] as List?;
                      
                      final recordNames = {
                        'A': 'A (Address)',
                        'MX': 'MX (Mail Exchange)',
                        'TXT': 'TXT (Text)',
                        'NS': 'NS (Name Server)',
                      };
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(recordNames[type] ?? type, style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                            const SizedBox(height: 4),
                            if (records != null && records.isNotEmpty)
                              ...records.map((r) => SelectableText('• $r', style: AppTextStyles.bodyText.copyWith(fontSize: 14)))
                            else
                              const Text('No records found', style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
