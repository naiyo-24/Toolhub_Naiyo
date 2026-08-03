import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class WorldClockScreen extends StatefulWidget {
  const WorldClockScreen({super.key});

  @override
  State<WorldClockScreen> createState() => _WorldClockScreenState();
}

class _WorldClockScreenState extends State<WorldClockScreen> {
  Timer? _timer;
  
  final List<Map<String, dynamic>> _cities = [
    {'name': 'New York', 'offset': -4},
    {'name': 'London', 'offset': 1},
    {'name': 'Paris', 'offset': 2},
  ];

  final List<Map<String, dynamic>> _availableCities = [
    {'name': 'Los Angeles', 'offset': -7},
    {'name': 'Denver', 'offset': -6},
    {'name': 'Chicago', 'offset': -5},
    {'name': 'New York', 'offset': -4},
    {'name': 'Toronto', 'offset': -4},
    {'name': 'Sao Paulo', 'offset': -3},
    {'name': 'London', 'offset': 1},
    {'name': 'Paris', 'offset': 2},
    {'name': 'Berlin', 'offset': 2},
    {'name': 'Cairo', 'offset': 3},
    {'name': 'Moscow', 'offset': 3},
    {'name': 'Dubai', 'offset': 4},
    {'name': 'Mumbai', 'offset': 5.5},
    {'name': 'Bangkok', 'offset': 7},
    {'name': 'Beijing', 'offset': 8},
    {'name': 'Tokyo', 'offset': 9},
    {'name': 'Sydney', 'offset': 10},
    {'name': 'Auckland', 'offset': 12},
  ];

  void _showAddCityDialog() {
    final unselectedCities = _availableCities.where((city) => !_cities.any((c) => c['name'] == city['name'])).toList();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Colors.black, width: 2),
      ),
      builder: (context) {
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Add Time Zone', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const Divider(color: Colors.black, thickness: 2, height: 0),
            Expanded(
              child: unselectedCities.isEmpty
                  ? const Center(child: Text('All time zones added!', style: TextStyle(fontWeight: FontWeight.bold)))
                  : ListView.builder(
                      itemCount: unselectedCities.length,
                      itemBuilder: (context, index) {
                        final city = unselectedCities[index];
                        return ListTile(
                          title: Text(city['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('UTC ${city['offset'] >= 0 ? '+' : ''}${city['offset']}'),
                          trailing: const Icon(Icons.add_circle_outline, color: Colors.black),
                          onTap: () {
                            setState(() {
                              _cities.add(city);
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
          'World Clock',
          style: AppTextStyles.heroTitle.copyWith(fontSize: 20, color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.black, size: 30),
            onPressed: _showAddCityDialog,
          ),
          const SizedBox(width: 8),
        ],
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
                    "1. View the current time across various popular timezones.\n2. The times update automatically in real-time.", style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            ),
            const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.primaryYellow,
              border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
            ),
            child: Column(
              children: [
                Text(
                  'Local Time',
                  style: AppTextStyles.sectionTitle.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('hh:mm:ss a').format(DateTime.now()),
                  style: AppTextStyles.heroTitle.copyWith(fontSize: 40, color: Colors.black),
                ),
                Text(
                  DateFormat('EEEE, MMM d').format(DateTime.now()),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _cities.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final city = _cities[index];
                
                // Calculate time
                final nowUtc = DateTime.now().toUtc();
                final offsetHours = city['offset'].truncate();
                final offsetMinutes = ((city['offset'] - offsetHours) * 60).round();
                
                final cityTime = nowUtc.add(Duration(hours: offsetHours, minutes: offsetMinutes));
                
                return NeoCard(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(city['name'], style: AppTextStyles.sectionTitle.copyWith(fontSize: 18)),
                          const SizedBox(height: 4),
                          Text(
                            'UTC ${city['offset'] >= 0 ? '+' : ''}${city['offset']}',
                            style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            DateFormat('hh:mm a').format(cityTime),
                            style: AppTextStyles.heroTitle.copyWith(fontSize: 24, color: Colors.black),
                          ),
                          Text(
                            DateFormat('MMM d').format(cityTime),
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _cities.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
