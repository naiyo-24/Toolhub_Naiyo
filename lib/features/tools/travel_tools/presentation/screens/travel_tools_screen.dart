import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/widgets/universal_tool_card.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';

class TravelToolsScreen extends StatefulWidget {
  const TravelToolsScreen({super.key});

  @override
  State<TravelToolsScreen> createState() => _TravelToolsScreenState();
}

class _TravelToolsScreenState extends State<TravelToolsScreen> {
  String _searchQuery = '';
  bool _showAllTools = false;
  
  final List<Map<String, dynamic>> tools = [
      {'title': 'Currency Converter', 'subtitle': 'Live exchange rates', 'icon': Icons.currency_exchange_rounded, 'color': AppColors.primaryGreen, 'actionText': 'Convert', 'endpoint': '/travel-tools/currency-converter', 'config': [
        {'key': 'amount', 'label': 'Amount', 'icon': Icons.attach_money, 'type': 'number'},
        {'key': 'from_currency', 'label': 'From Currency (e.g. USD)', 'icon': Icons.money, 'type': 'text'},
        {'key': 'to_currency', 'label': 'To Currency (e.g. EUR)', 'icon': Icons.money, 'type': 'text'}
      ]},
      {'title': 'World Clock', 'subtitle': 'Global timezones', 'icon': Icons.public_rounded, 'color': AppColors.primaryBlue, 'actionText': 'View', 'endpoint': '/travel-tools/world-clock', 'config': [
        {'key': 'timezones', 'label': 'Timezones (comma-separated, e.g. UTC, Asia/Tokyo)', 'icon': Icons.language, 'type': 'text'}
      ]},
      // {'title': 'Translator', 'subtitle': 'Translate languages', 'icon': Icons.translate_rounded, 'color': AppColors.primaryRed, 'actionText': 'Translate', 'endpoint': '/travel-tools/translator', 'config': [
      //   {'key': 'source_language', 'label': 'Source Language (Optional)', 'icon': Icons.language, 'type': 'text'},
      //   {'key': 'target_language', 'label': 'Target Language', 'icon': Icons.language, 'type': 'text'},
      //   {'key': 'text', 'label': 'Text to Translate', 'icon': Icons.text_fields, 'type': 'text'}
      // ]},
      {'title': 'Distance Calc', 'subtitle': 'Calculate distance', 'icon': Icons.route_rounded, 'color': AppColors.primaryYellow, 'actionText': 'Calculate', 'endpoint': '/travel-tools/distance-calc', 'config': [
        {'key': 'origin', 'label': 'Origin', 'icon': Icons.location_on, 'type': 'text'},
        {'key': 'destination', 'label': 'Destination', 'icon': Icons.location_on, 'type': 'text'}
      ]},
      {'title': 'Fuel Cost Calc', 'subtitle': 'Calculate fuel expenses', 'icon': Icons.local_gas_station_rounded, 'color': AppColors.primaryPurple, 'actionText': 'Calculate', 'endpoint': '/travel-tools/fuel-cost-calc', 'config': [
        {'key': 'distance', 'label': 'Distance (km/miles)', 'icon': Icons.route, 'type': 'number'},
        {'key': 'efficiency', 'label': 'Fuel Efficiency (km/l or mpg)', 'icon': Icons.speed, 'type': 'number'},
        {'key': 'fuel_price', 'label': 'Fuel Price per unit', 'icon': Icons.attach_money, 'type': 'number'}
      ]},
      // {'title': 'Trip Planner', 'subtitle': 'Plan your itinerary', 'icon': Icons.map_rounded, 'color': AppColors.primaryPink, 'actionText': 'Plan', 'endpoint': '/travel-tools/trip-planner', 'config': [
      //   {'key': 'destination', 'label': 'Destination', 'icon': Icons.location_city, 'type': 'text'},
      //   {'key': 'days', 'label': 'Number of Days', 'icon': Icons.calendar_today, 'type': 'number'},
      //   {'key': 'travel_style', 'label': 'Travel Style', 'icon': Icons.card_travel, 'type': 'dropdown', 'options': ['Relaxing', 'Adventure', 'Cultural', 'Budget', 'Luxury']}
      // ]},
      // {'title': 'Packing List', 'subtitle': 'Checklist for trips', 'icon': Icons.luggage_rounded, 'color': AppColors.primaryBlue, 'actionText': 'Check', 'endpoint': '/travel-tools/packing-list', 'config': [
      //   {'key': 'destination', 'label': 'Destination', 'icon': Icons.location_city, 'type': 'text'},
      //   {'key': 'days', 'label': 'Number of Days', 'icon': Icons.calendar_today, 'type': 'number'},
      //   {'key': 'weather', 'label': 'Expected Weather', 'icon': Icons.wb_sunny, 'type': 'dropdown', 'options': ['Hot', 'Cold', 'Rainy', 'Moderate']}
      // ]},
      {'title': 'Weather', 'subtitle': 'Check forecasts', 'icon': Icons.wb_sunny_rounded, 'color': AppColors.primaryYellow, 'actionText': 'Check', 'endpoint': '/travel-tools/weather', 'config': [
        {'key': 'location', 'label': 'Location (e.g. Paris, France)', 'icon': Icons.location_on, 'type': 'text'}
      ]},
  ];

  void _showComingSoon(BuildContext context) {
    SnackbarUtils.showNeoSnackBar(context, message: 'This tool is temporarily deactivated.');
  }

  void _navigateToTool(BuildContext context, Map<String, dynamic> tool) {
    if (['Trip Planner', 'Packing List', 'Translator'].contains(tool['title'])) {
      _showComingSoon(context);
      return;
    }
    if (tool['title'] == 'Currency Converter') {
      context.push('/currency-converter');
      return;
    }
    if (tool['title'] == 'World Clock') {
      context.push('/world-clock');
      return;
    }
    context.push('/travel/tool', extra: tool);
  }

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
                    if (_searchQuery.isEmpty && tools.length > 6)
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
        backgroundColor: const Color(0xFF00B0FF), // A bright sky blue
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
                        'Travel ',
                        style: AppTextStyles.heroTitle.copyWith(fontSize: 22, color: Colors.black),
                      ),
                      Text(
                        'Tools',
                        style: AppTextStyles.logoText.copyWith(fontSize: 22, color: Colors.black, fontWeight: FontWeight.normal, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                  Text(
                    'EXPLORE THE WORLD',
                    style: AppTextStyles.caption.copyWith(fontSize: 9, letterSpacing: 2, color: Colors.black87),
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
            hintText: 'Search travel tools...',
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
      onTap: () => _navigateToTool(context, tool),
    );
  }
}
