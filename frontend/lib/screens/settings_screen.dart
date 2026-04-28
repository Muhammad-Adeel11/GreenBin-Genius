import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/responsive.dart';
import '../services/api_service.dart';
import 'login_selection_screen.dart';

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _aiSuggestions = prefs.getBool('ai_suggestions') ?? true;
      _wifiOnly = prefs.getBool('wifi_only') ?? false;
      _maxLocation = prefs.getBool('max_location') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _updateSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    setState(() {
      if (key == 'ai_suggestions') _aiSuggestions = value;
      if (key == 'wifi_only') _wifiOnly = value;
      if (key == 'max_location') _maxLocation = value;
    });
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("LOGOUT", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.instance.clearToken();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginSelectionScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: sp),

            _buildSectionTitle(context, "PREFERENCES"),
            SizedBox(height: sp),

            // Toggles
            _buildSwitchOption(context, "GreenBin Suggestions", _aiSuggestions, (val) {
              _updateSetting('ai_suggestions', val);
            }),
            const Divider(height: 32),

            _buildSwitchOption(context, "Upload only via Wi-Fi", _wifiOnly, (val) {
              _updateSetting('wifi_only', val);
            }),
            const Divider(height: 32),

            _buildSwitchOption(context, "Maximum Location Accuracy", _maxLocation, (val) {
              _updateSetting('max_location', val);
            }),
            
            SizedBox(height: sp * 4),
            _buildSectionTitle(context, "ACCOUNT"),
            SizedBox(height: sp),

            // Logout Button
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: Text(
                "Log Out",
                style: TextStyle(
                  fontSize: R.fs(context, 15),
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              onTap: _handleLogout,
            ),
            
            const Divider(height: 32),

            // Clear Cache (Mock)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_sweep_outlined, color: Colors.black87),
              title: Text(
                "Clear History Cache",
                style: TextStyle(
                  fontSize: R.fs(context, 15),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("History cache cleared successfully")),
                );
              },
            ),

            const Divider(height: 32),
            
            // Reset Tutorial
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.help_outline, color: Colors.black87),
              title: Text(
                "Show Camera Tutorial Again",
                style: TextStyle(
                  fontSize: R.fs(context, 15),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('has_seen_camera_tutorial', false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Camera tutorial will be shown on next scan")),
                  );
                }
              },
            ),

            SizedBox(height: sp * 4),
            _buildSectionTitle(context, "ABOUT"),
            SizedBox(height: sp),

            // App Version Text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "App Version",
                  style: TextStyle(
                    fontSize: R.fs(context, 14),
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  "1.0.0+1 (Production)",
                  style: TextStyle(
                    fontSize: R.fs(context, 14),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: sp * 4),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: R.fs(context, 12),
        fontWeight: FontWeight.w900,
        color: Colors.grey[400],
        letterSpacing: 1.2,
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
