import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/widgets/universal_tool_card.dart';

class InternetToolsScreen extends StatefulWidget {
  const InternetToolsScreen({super.key});

  @override
  State<InternetToolsScreen> createState() => _InternetToolsScreenState();
}

class _InternetToolsScreenState extends State<InternetToolsScreen> {
  String _searchQuery = '';
  bool _showAllTools = false;
  
  final List<Map<String, dynamic>> tools = [
      {'title': 'URL Shortener', 'subtitle': 'Shorten long links', 'icon': Icons.link_rounded, 'color': AppColors.primaryPurple, 'actionText': 'Shorten', 'route': '/internet-tools/url-shortener'},
      {'title': 'URL Expander', 'subtitle': 'Expand short links', 'icon': Icons.unfold_more_rounded, 'color': AppColors.primaryPink, 'actionText': 'Expand', 'route': '/internet-tools/url-expander'},
      {'title': 'Link Checker', 'subtitle': 'Check link safety', 'icon': Icons.security_rounded, 'color': AppColors.primaryYellow, 'actionText': 'Check', 'route': '/internet-tools/link-checker'},
      {'title': 'WiFi QR Gen', 'subtitle': 'Share WiFi easily', 'icon': Icons.wifi_rounded, 'color': AppColors.primaryGreen, 'actionText': 'Generate', 'route': '/internet-tools/wifi-qr'},
      {'title': 'UPI QR Gen', 'subtitle': 'Create payment QR', 'icon': Icons.qr_code_2_rounded, 'color': AppColors.primaryBlue, 'actionText': 'Generate', 'route': '/internet-tools/upi-qr'},
      {'title': 'Email Validator', 'subtitle': 'Verify email address', 'icon': Icons.email_rounded, 'color': AppColors.primaryPurple, 'actionText': 'Validate', 'route': '/internet-tools/email-validator'},
      {'title': 'IP Finder', 'subtitle': 'Find your IP address', 'icon': Icons.location_on_rounded, 'color': AppColors.primaryOrange, 'actionText': 'Find', 'route': '/internet-tools/ip-finder'},
      {'title': 'Web Screenshot', 'subtitle': 'Capture full webpage', 'icon': Icons.camera_alt_rounded, 'color': AppColors.primaryTeal, 'actionText': 'Capture', 'route': '/internet-tools/web-screenshot'},
      {'title': 'Status Checker', 'subtitle': 'Is website down?', 'icon': Icons.monitor_heart_rounded, 'color': AppColors.primaryPink, 'actionText': 'Check', 'route': '/internet-tools/site-status'},
      {'title': 'DNS Lookup', 'subtitle': 'Find DNS records', 'icon': Icons.dns_rounded, 'color': AppColors.primaryBlue, 'actionText': 'Lookup', 'route': '/internet-tools/dns-lookup'},
      {'title': 'Ping Test', 'subtitle': 'Check latency', 'icon': Icons.network_ping_rounded, 'color': AppColors.primaryGreen, 'actionText': 'Test', 'route': '/internet-tools/ping-test'},
      {'title': 'Speed Test', 'subtitle': 'Check internet speed', 'icon': Icons.speed_rounded, 'color': AppColors.primaryYellow, 'actionText': 'Test', 'route': '/internet-tools/speed-test'},
      {'title': 'JSON Formatter', 'subtitle': 'Format & validate', 'icon': Icons.data_object_rounded, 'color': AppColors.primaryPurple, 'actionText': 'Format', 'route': '/internet-tools/json-formatter'},
      {'title': 'Base64 Encoder', 'subtitle': 'Encode / Decode text', 'icon': Icons.code_rounded, 'color': AppColors.primaryRed, 'actionText': 'Encode', 'route': '/internet-tools/base64-tool'},
  ];

  @override
  Widget build(BuildContext context) {
    var filteredTools = tools.where((tool) {
      final title = (tool['title'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query);
    }).toList();

    if (_searchQuery.isEmpty && !_showAllTools) {
      filteredTools = filteredTools.take(6).toList();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: filteredTools.length,
                      itemBuilder: (context, index) {
                        final tool = filteredTools[index];
                        return _buildUtilityCard(context, tool);
                      },
                    ),
                    if (_searchQuery.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _showAllTools = !_showAllTools;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryYellow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(4, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              _showAllTools ? 'View Less' : 'View More',
                              style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: NeoCard(
        backgroundColor: AppColors.primaryBlue,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        borderRadius: 12,
        shadowOffset: const Offset(4, 4),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                  ],
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.black, size: 18),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Internet ',
                        style: AppTextStyles.heroTitle.copyWith(fontSize: 22, color: Colors.white),
                      ),
                      Text(
                        'Tools',
                        style: AppTextStyles.logoText.copyWith(fontSize: 22, color: Colors.white, fontWeight: FontWeight.normal, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                  Text(
                    'EVERYTHING YOU NEED ONLINE',
                    style: AppTextStyles.caption.copyWith(fontSize: 9, letterSpacing: 2, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search tools...',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.onSurface),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }

  Widget _buildUtilityCard(BuildContext context, Map<String, dynamic> tool) {
    final cardColor = tool['color'] as Color;

    return UniversalToolCard(
      title: tool['title'] as String,
      subtitle: tool['subtitle'] as String?,
      color: cardColor,
      icon: tool['icon'] as IconData,
      actionText: tool['actionText'] as String,
      onTap: () {
        if (tool.containsKey('route')) {
          context.push(tool['route'] as String);
        }
      },
    );
  }
}
