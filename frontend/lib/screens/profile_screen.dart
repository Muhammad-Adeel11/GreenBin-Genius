import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../services/api_service.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'claim_account_flow.dart';
import 'login_selection_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3), // Match app theme
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Profile",
          style: TextStyle(
            color: Colors.white,
            fontSize: R.fs(context, 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Custom Wavy Header with Avatar
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
                      color: const Color(0xFF2196F3),
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
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.cyanAccent, Colors.blue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. User Info
            SizedBox(height: sp),
            Text(
              "GreenBin Member",
              style: TextStyle(
                fontSize: R.fs(context, 28),
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            SizedBox(height: sp * 0.5),
            Text(
              "Member Since APRIL, 2026",
              style: TextStyle(
                fontSize: R.fs(context, 12),
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),

            SizedBox(height: sp * 2),

            // 3. Claim Account Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ClaimDisplayNameScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE3F2FD),
                foregroundColor: const Color(0xFF2196F3),
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: R.w(context, 10), vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                "CLAIM YOUR ACCOUNT",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: R.fs(context, 13),
                  letterSpacing: 0.5,
                ),
              ),
            ),

            SizedBox(height: sp * 3),

            // 4. Options List
            _buildListOption(context, Icons.notifications_none_rounded, "Notifications", onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
            }),
            _buildListOption(context, Icons.help_outline_rounded, "FAQs & Resources", isBlue: true),
            _buildListOption(context, Icons.settings_outlined, "Settings", onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            }),
            _buildListOption(context, Icons.privacy_tip_outlined, "Privacy Policy"),
            _buildListOption(context, Icons.help_outline_rounded, "Help"),
            _buildListOption(context, Icons.logout_rounded, "Log Out", isLast: true, onTap: () async {
              await ApiService.instance.clearToken();
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
  }

  Widget _buildListOption(BuildContext context, IconData icon, String title, {bool isBlue = false, bool isLast = false, VoidCallback? onTap}) {
    final color = isBlue ? const Color(0xFF2196F3) : Colors.black87;
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
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE), indent: 24, endIndent: 24),
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
