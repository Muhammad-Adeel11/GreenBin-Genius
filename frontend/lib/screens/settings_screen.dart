import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../utils/responsive.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // State variables for the toggles
  bool _aiSuggestions = true;
  bool _wifiOnly = false;
  bool _maxLocation = true;

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Settings",
          style: TextStyle(
            color: Colors.black,
            fontSize: R.fs(context, 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: R.pagePadding(context),
        child: Column(
          children: [
            SizedBox(height: sp),

            // Toggles
            _buildSwitchOption(context, "GreenBin Suggestions", _aiSuggestions, (val) {
              setState(() => _aiSuggestions = val);
            }),
            SizedBox(height: sp * 2.5),

            _buildSwitchOption(context, "Upload only via Wi-Fi", _wifiOnly, (val) {
              setState(() => _wifiOnly = val);
            }),
            SizedBox(height: sp * 2.5),

            _buildSwitchOption(context, "Maximum Location Accuracy", _maxLocation, (val) {
              setState(() => _maxLocation = val);
            }),
            SizedBox(height: sp * 3.5),

            // App Version Text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "App Version",
                  style: TextStyle(
                    fontSize: R.fs(context, 15),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "4.1.11 Build 760",
                  style: TextStyle(
                    fontSize: R.fs(context, 14),
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Helper widget to build the switch rows
  Widget _buildSwitchOption(BuildContext context, String title, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: R.fs(context, 15),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        CupertinoSwitch(
          value: value,
          activeColor: const Color(0xFF2196F3), // App's primary blue
          onChanged: onChanged,
        ),
      ],
    );
  }
}
