import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/notifications_screen.dart';
import 'services/api_service.dart';
import 'services/translation_service.dart';

// ── Background message handler (must be top-level function) ──
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No UI work here – Flutter isn't running yet.
  // The OS notification tray handles display automatically.
}

// ── Navigation key for deep-linking from notifications ────────
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Firebase
  await Firebase.initializeApp();

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Translation Service
  await TranslationService.instance.init();

  runApp(const GreenBinGeniusApp());
}

class GreenBinGeniusApp extends StatefulWidget {
  const GreenBinGeniusApp({super.key});

  @override
  State<GreenBinGeniusApp> createState() => _GreenBinGeniusAppState();
}

class _GreenBinGeniusAppState extends State<GreenBinGeniusApp> {
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    final messaging = FirebaseMessaging.instance;

    // Request permission (Android 13+ and iOS)
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Get device token and save to backend
      final token = await messaging.getToken();
      if (token != null) {
        await _saveFcmToken(token);
      }

      // Refresh token when it rotates
      messaging.onTokenRefresh.listen(_saveFcmToken);
    }

    // Foreground messages — show a SnackBar / navigate
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null && navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('🔔  ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Text(
                    '${notification.title ?? ''}: ${notification.body ?? ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                navigatorKey.currentState?.push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });

    // When user taps a notification that opened the app from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
    });

    // Check if app was launched by tapping a notification (terminated state)
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      // Delay so the navigator is ready
      Future.delayed(const Duration(seconds: 1), () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
      });
    }
  }

  /// POST the FCM token to the backend so the server knows where to push.
  Future<void> _saveFcmToken(String token) async {
    try {
      final jwtToken = await ApiService.instance.getToken();
      if (jwtToken == null) return; // not logged in yet — will retry on next startup

      await http.post(
        Uri.parse('${ApiService.baseUrl}/api/auth/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({'fcm_token': token}),
      );
    } catch (_) {
      // Silent fail — non-critical
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return ValueListenableBuilder<String>(
          valueListenable: TranslationService.instance.languageNotifier,
          builder: (_, String lang, __) {
            return MaterialApp(
              title: 'GreenBin Genius',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: currentMode,
              navigatorKey: navigatorKey,
              locale: Locale(lang),
              builder: (context, child) {
                return Directionality(
                  textDirection: lang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
                  child: child!,
                );
              },
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}