import 'package:flutter/material.dart';
import 'utils/app_theme.dart'; // Imports your custom Blue Theme
import 'screens/splash_screen.dart'; // Imports your Splash Screen

void main() {
  runApp(const GreenBinGeniusApp());
}

class GreenBinGeniusApp extends StatelessWidget {
  const GreenBinGeniusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'GreenBin Genius',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}