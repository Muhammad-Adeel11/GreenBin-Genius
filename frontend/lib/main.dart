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
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Bell Icon inside white-translucent circle
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and body
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title ?? 'Notification',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          notification.body ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.85),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Action button
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(navigatorKey.currentContext!).hideCurrentSnackBar();
                      navigatorKey.currentState?.push(
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    },
                    child: const Text(
                      'View',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            duration: const Duration(seconds: 6),
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