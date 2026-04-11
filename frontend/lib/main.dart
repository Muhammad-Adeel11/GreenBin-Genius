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
    return MaterialApp(
      title: 'GreenBin Genius',
      debugShowCheckedModeBanner: false, // Hides the 'Debug' banner in the corner

      // Apply the custom theme defined in lib/utils/app_theme.dart
      theme: AppTheme.lightTheme,

      // This is Comment
      // theme: AppTheme.light,
      // home: ImpactScreen(),
      // This is comment

      // Start the app with the Splash Screen
      home: const SplashScreen(),
    );
  }
}