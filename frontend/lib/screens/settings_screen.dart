import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/responsive.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';
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
  bool _isDarkMode = false;
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
      _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
      
      // Update global notifier if needed
      AppTheme.themeNotifier.value = _isDarkMode ? ThemeMode.dark : ThemeMode.light;
      
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
      if (key == 'is_dark_mode') {
        _isDarkMode = value;
        AppTheme.themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
      }
    });
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(TranslationService.translate('logout_confirm_title')),
        content: Text(TranslationService.translate('logout_confirm_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(TranslationService.translate('cancel').toUpperCase()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              TranslationService.translate('log_out').toUpperCase(),
              style: const TextStyle(color: Colors.red),
            ),
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          TranslationService.translate('settings'),
          style: TextStyle(
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

            _buildSectionTitle(context, TranslationService.translate('appearance')),
            SizedBox(height: sp),
            
            _buildSwitchOption(context, TranslationService.translate('dark_mode'), _isDarkMode, (val) {
              _updateSetting('is_dark_mode', val);
            }),
            const Divider(height: 32),

            _buildSectionTitle(context, TranslationService.translate('preferences')),
            SizedBox(height: sp),

            // Toggles
            _buildSwitchOption(context, TranslationService.translate('greenbin_suggestions'), _aiSuggestions, (val) {
              _updateSetting('ai_suggestions', val);
            }),
            const Divider(height: 32),

            _buildSwitchOption(context, TranslationService.translate('upload_wifi'), _wifiOnly, (val) {
              _updateSetting('wifi_only', val);
            }),
            const Divider(height: 32),

            _buildSwitchOption(context, TranslationService.translate('location_accuracy'), _maxLocation, (val) {
              _updateSetting('max_location', val);
            }),
            const Divider(height: 32),

            _buildLanguageOption(context),
            
            SizedBox(height: sp * 4),
            _buildSectionTitle(context, TranslationService.translate('account')),
            SizedBox(height: sp),

            // Logout Button
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: Text(
                TranslationService.translate('log_out'),
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
              leading: Icon(Icons.delete_sweep_outlined, color: Theme.of(context).colorScheme.onSurface),
              title: Text(
                TranslationService.translate('clear_cache'),
                style: TextStyle(
                  fontSize: R.fs(context, 15),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(TranslationService.isUrdu ? "ہسٹری کیشے کامیابی سے صاف ہو گیا" : "History cache cleared successfully")),
                );
              },
            ),

            const Divider(height: 32),
            
            // Reset Tutorial
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.help_outline, color: Theme.of(context).colorScheme.onSurface),
              title: Text(
                TranslationService.translate('show_tutorial'),
                style: TextStyle(
                  fontSize: R.fs(context, 15),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('has_seen_camera_tutorial', false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(TranslationService.isUrdu ? "کیمرہ ٹیوٹوریل اگلے اسکین پر دکھایا جائے گا" : "Camera tutorial will be shown on next scan")),
                  );
                }
              },
            ),

            const Divider(height: 32),

            SizedBox(height: sp * 4),
            _buildSectionTitle(context, TranslationService.translate('about')),
            SizedBox(height: sp),

            // App Version Text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  TranslationService.translate('app_version'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: R.fs(context, 15),
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
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

  Widget _buildLanguageOption(BuildContext context) {
    final isUrdu = TranslationService.isUrdu;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.language, color: Theme.of(context).colorScheme.onSurface),
      title: Text(
        TranslationService.translate('app_language'),
        style: TextStyle(
          fontSize: R.fs(context, 15),
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          isUrdu ? "اردو" : "English",
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: () async {
        await TranslationService.instance.toggleLanguage();
        setState(() {});
      },
    );
  }
}
