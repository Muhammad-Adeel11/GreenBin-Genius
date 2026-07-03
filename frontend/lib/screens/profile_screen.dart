import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'claim_account_flow.dart';
import 'login_selection_screen.dart';
import 'faqs_resources_screen.dart';
import 'privacy_policy_screen.dart';
import 'help_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final info = await ApiService.instance.getMe();
      if (mounted) {
        setState(() {
          _userInfo = info;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _isAnonymous => _userInfo?['is_anonymous'] == true;
  String get _displayName => _userInfo?['name'] ?? 'Guest User';
  String get _email => _userInfo?['email'] ?? '';
  String get _username => _userInfo?['username'] ?? '';
  String get _profileImage => _userInfo?['profile_image'] ?? '';
  String? get _claimedAt => _userInfo?['claimed_at'];

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return ValueListenableBuilder<String>(
      valueListenable: TranslationService.instance.languageNotifier,
      builder: (context, lang, child) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          appBar: AppBar(
            backgroundColor: primary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              TranslationService.translate('tab_profile'),
              style: TextStyle(
                color: Colors.white,
                fontSize: R.fs(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            // Reload button
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadUserInfo();
                },
              ),
            ],
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: primary))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // ── 1. Hero Header ──────────────────────────────────────
                      SizedBox(
                        height: R.h(context, 32),
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            // Blue Wave Background
                            ClipPath(
                              clipper: ProfileWaveClipper(),
                              child: Container(
                                height: R.h(context, 24),
                                width: double.infinity,
                                color: primary,
                              ),
                            ),
                            // Avatar overlapping the wave
                            Positioned(
                              bottom: 0,
                              child: Container(
                                width: R.icon(context, 110),
                                height: R.icon(context, 110),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? const Color(0xFF121212) : Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: _profileImage.isNotEmpty
                                      ? CircleAvatar(
                                          backgroundImage: NetworkImage(_profileImage),
                                          radius: 50,
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [Colors.cyanAccent, primary],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: Center(
                                            child: _isAnonymous
                                                ? const Icon(Icons.person, color: Colors.white, size: 52)
                                                : Text(
                                                    _displayName.isNotEmpty
                                                        ? _displayName[0].toUpperCase()
                                                        : '?',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 46,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── 2. Name & Account Info ──────────────────────────────
                      SizedBox(height: sp),
                      Text(
                        _isAnonymous
                            ? TranslationService.translate('profile_member_title')
                            : _displayName,
                        style: TextStyle(
                          fontSize: R.fs(context, 26),
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),

                      if (!_isAnonymous && _username.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '@$_username',
                          style: TextStyle(
                            fontSize: R.fs(context, 13),
                            color: primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],

                      if (!_isAnonymous && _email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _email,
                          style: TextStyle(
                            fontSize: R.fs(context, 12),
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],

                      if (_isAnonymous) ...[
                        SizedBox(height: sp * 0.5),
                        Text(
                          TranslationService.translate('profile_member_since'),
                          style: TextStyle(
                            fontSize: R.fs(context, 12),
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],

                      SizedBox(height: sp * 2),

                      // ── 3. Status Badge / Claim Button ──────────────────────
                      if (_isAnonymous)
                        // Show "CLAIM YOUR ACCOUNT" if still anonymous
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: R.w(context, 6)),
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const ClaimDisplayNameScreen()),
                              );
                              // Reload profile after returning from claim flow
                              setState(() => _isLoading = true);
                              _loadUserInfo();
                            },
                            icon: const Icon(Icons.verified_user_outlined, size: 18),
                            label: Text(
                              TranslationService.translate('claim_account'),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: R.fs(context, 13),
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.white10 : const Color(0xFFE3F2FD),
                              foregroundColor: primary,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                  horizontal: R.w(context, 8), vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        )
                      else
                        // Show "Verified Account" badge if claimed
                        _buildVerifiedBadge(context, isDark, sp),

                      SizedBox(height: sp * 3),

                      // ── 4. Options List ─────────────────────────────────────
                      _buildListOption(context, Icons.notifications_none_rounded,
                          TranslationService.translate('notifications'),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (context) => const NotificationsScreen()))),
                      _buildListOption(context, Icons.help_outline_rounded,
                          TranslationService.translate('faqs_resources'),
                          isBlue: true,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (context) => const FAQsResourcesScreen()))),
                      _buildListOption(context, Icons.settings_outlined,
                          TranslationService.translate('settings'),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (context) => const SettingsScreen()))),
                      _buildListOption(context, Icons.privacy_tip_outlined,
                          TranslationService.translate('privacy_policy'),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()))),
                      _buildListOption(context, Icons.help_outline_rounded,
                          TranslationService.translate('help'),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (context) => const HelpScreen()))),
                      _buildListOption(context, Icons.logout_rounded,
                          TranslationService.translate('log_out'),
                          isLast: true,
                          onTap: () async {
                            await ApiService.instance.clearToken();
                            await ApiService.instance.clearUsername();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginSelectionScreen()),
                                (route) => false,
                              );
                            }
                          }),

                      SizedBox(height: R.h(context, 5)),
                    ],
                  ),
                ),
        );
      },
    );
  }

  /// Displayed after account claiming — shows the Gmail + verified badge + claimed date
  Widget _buildVerifiedBadge(BuildContext context, bool isDark, double sp) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: R.w(context, 6)),
      padding: EdgeInsets.symmetric(horizontal: sp * 1.5, vertical: sp),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2E1A) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verified Google Account',
                  style: TextStyle(
                    color: const Color(0xFF2E7D32),
                    fontWeight: FontWeight.w900,
                    fontSize: R.fs(context, 13),
                  ),
                ),
                if (_email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _email,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: R.fs(context, 12),
                    ),
                  ),
                ],
                if (_claimedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Claimed on ${_formatDate(_claimedAt!)}',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: R.fs(context, 11),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }

  Widget _buildListOption(BuildContext context, IconData icon, String title,
      {bool isBlue = false, bool isLast = false, VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final color = isBlue ? primary : (isDark ? Colors.white : Colors.black87);
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          leading: Icon(icon, color: color, size: R.icon(context, 26)),
          title: Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: R.fs(context, 16),
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: Icon(Icons.arrow_forward_ios, color: color, size: 16),
          onTap: onTap,
        ),
        if (!isLast)
          Divider(
              height: 1,
              thickness: 1,
              color: isDark ? Colors.white10 : const Color(0xFFEEEEEE),
              indent: 24,
              endIndent: 24),
      ],
    );
  }
}

class ProfileWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.9,
      size.width * 0.5, size.height * 0.9,
    );
    path.quadraticBezierTo(
      size.width * 0.8, size.height * 0.9,
      size.width, size.height * 0.5,
    );
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
