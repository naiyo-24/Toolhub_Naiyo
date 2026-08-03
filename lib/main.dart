import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tool_hub/core/theme/app_theme.dart';
import 'package:tool_hub/core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/config/app_config.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Firebase initialization removed
  } catch (e) {
    debugPrint("Firebase init error (you can ignore this during dev if testing mock): $e");
  }
  
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

  final NotificationAppLaunchDetails? notificationAppLaunchDetails =
      await FlutterLocalNotificationsPlugin().getNotificationAppLaunchDetails();
  
  bool launchedFromNotification = notificationAppLaunchDetails?.didNotificationLaunchApp ?? false;

  runApp(ProviderScope(
    child: ToolHubApp(
      hasSeenOnboarding: hasSeenOnboarding,
      launchedFromNotification: launchedFromNotification,
    ),
  ));
}

class ToolHubApp extends ConsumerWidget {
  final bool hasSeenOnboarding;
  final bool launchedFromNotification;

  const ToolHubApp({
    super.key, 
    required this.hasSeenOnboarding,
    required this.launchedFromNotification,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: createAppRouter(hasSeenOnboarding, launchedFromNotification),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
    );
  }
}
