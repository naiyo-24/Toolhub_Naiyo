import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tool_hub/core/theme/app_theme.dart';
import 'package:tool_hub/core/providers/theme_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'core/router/app_router.dart';
import 'core/api/api_config.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tool_hub/core/widgets/network_overlay.dart';

import 'package:tool_hub/features/tools/docu_forge/data/docuforge_database_service.dart';
import 'package:tool_hub/features/tools/docu_forge/data/models/document_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await DocuForgeDatabaseService.init();
  
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

class ToolHubApp extends ConsumerStatefulWidget {
  final bool hasSeenOnboarding;
  final bool launchedFromNotification;

  const ToolHubApp({
    super.key, 
    required this.hasSeenOnboarding,
    required this.launchedFromNotification,
  });

  @override
  ConsumerState<ToolHubApp> createState() => _ToolHubAppState();
}

class _ToolHubAppState extends ConsumerState<ToolHubApp> {
  late StreamSubscription _intentDataStreamSubscription;
  final _router = createAppRouter(false, false); // Will be recreated below but we can use rootNavigatorKey

  @override
  void initState() {
    super.initState();
    _handleExternalIntents();
  }

  void _handleExternalIntents() {
    // For sharing or opening when app is in memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) _processSharedFile(value.first);
    }, onError: (err) {
      debugPrint("getIntentDataStream error: $err");
    });

    // For sharing or opening when app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        // Add a slight delay to ensure router is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          _processSharedFile(value.first);
        });
      }
      ReceiveSharingIntent.instance.reset();
    });
  }

  void _processSharedFile(SharedMediaFile file) {
    // Android shares often use content:// URIs which don't end in .pdf
    // We can assume if it was shared to our app's PDF intent filter, it's a valid file.
    final docName = file.path.split('/').last;
    final tempDoc = Document()
      ..name = docName
      ..pdfPath = file.path
      ..pageCount = 1
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
      
    if (rootNavigatorKey.currentContext != null) {
      rootNavigatorKey.currentContext!.go('/pdf-viewer', extra: tempDoc);
    }
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: ApiConfig.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: createAppRouter(widget.hasSeenOnboarding, widget.launchedFromNotification),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      builder: (context, child) {
        return NetworkOverlay(child: child!);
      },
    );
  }
}
