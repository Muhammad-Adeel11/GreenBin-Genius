// GreenBin Genius – Claim Account Flow
// A multi-step wizard that lets a guest user claim their anonymous account
// by signing in with Google. The Gmail is verified server-side via
// Google's public tokeninfo API — confirming the inbox is real.
//
// Steps:
//   1. Welcome & "Continue with Google" trigger
//   2. Username selection
//   3. Confirmation & Finish

import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../services/google_auth_service.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

// ─── Shared state passed through the wizard ──────────────────────────────────────────────

class ClaimWizardState {
  String? googleIdToken;
  String? verifiedEmail;
  String? verifiedName;
  String? photoUrl;
  String? username;
}

// ==========================================
// STEP 1: WELCOME & GOOGLE SIGN-IN
// ==========================================
class ClaimDisplayNameScreen extends StatefulWidget {
  const ClaimDisplayNameScreen({super.key});

  @override
  State<ClaimDisplayNameScreen> createState() => _ClaimDisplayNameScreenState();
}

class _ClaimDisplayNameScreenState extends State<ClaimDisplayNameScreen> {
  bool _isLoading = false;
  String? _error;
  final _state = ClaimWizardState();

  Future<void> _handleGoogleSignIn() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final account = await GoogleAuthService.signIn();
      if (account == null) {
        setState(() { _isLoading = false; _error = 'Sign-in was cancelled.'; });
        return;
      }

      final idToken = await GoogleAuthService.getIdToken(account);
      if (idToken == null) {
        setState(() { _isLoading = false; _error = 'Failed to get Google token. Try again.'; });
        return;
      }

      _state.googleIdToken = idToken;
      _state.verifiedEmail = account.email;
      _state.verifiedName  = account.displayName ?? account.email.split('@').first;
      _state.photoUrl      = account.photoUrl;

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ClaimUsernameScreen(claimState: _state),
      ));
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: R.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: sp),

            // ── Title ────────────────────────────────────────────────
            RichText(
              text: TextSpan(
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: R.fs(context, 34),
                  fontWeight: FontWeight.w300,
                  height: 1.2,
                ),
                children: const [
                  TextSpan(text: 'Claim your\n'),
                  TextSpan(
                    text: 'GreenBin Account',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            SizedBox(height: sp * 1.5),

            Text(
              'Sign in with Google to verify your email. '
              'All your scan history and points will be preserved.',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey[600],
                fontSize: R.fs(context, 14),
                height: 1.5,
              ),
            ),

            SizedBox(height: sp * 4),

            // ── What You Keep Card ────────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(sp * 1.5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✅ What you keep after claiming:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: R.fs(context, 14),
                          color: isDark ? Colors.white : Colors.black87)),
                  SizedBox(height: sp * 0.75),
                  ...[
                    '🗂  All your scan history',
                    '🏆  Your leaderboard ranking',
                    '🔥  Current streak & points',
                    '🔔  Notification preferences',
                  ].map((text) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(text,
                            style: TextStyle(
                                fontSize: R.fs(context, 13),
                                color: isDark ? Colors.white70 : Colors.black54,
                                height: 1.4)),
                      )),
                ],
              ),
            ),

            SizedBox(height: sp * 4),

            // ── Error Banner ─────────────────────────────────────────
            if (_error != null) ...[
              Container(
                padding: EdgeInsets.all(sp),
                margin: EdgeInsets.only(bottom: sp),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_error!,
                          style: TextStyle(
                              color: Colors.red[700], fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],

            // ── Google Sign-In Button ─────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: R.h(context, 7.5),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 2,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Color(0xFF2196F3), strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google G logo in circle
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEA4335),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text('G',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'Continue with Google',
                            style: TextStyle(
                                fontSize: R.fs(context, 15),
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
              ),
            ),

            SizedBox(height: sp * 1.5),

            Center(
              child: Text(
                'Your Gmail address is verified directly by Google.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey[400],
                    fontSize: R.fs(context, 11)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// STEP 2: USERNAME SELECTION
// ==========================================
class ClaimUsernameScreen extends StatefulWidget {
  final ClaimWizardState claimState;
  const ClaimUsernameScreen({super.key, required this.claimState});

  @override
  State<ClaimUsernameScreen> createState() => _ClaimUsernameScreenState();
}

class _ClaimUsernameScreenState extends State<ClaimUsernameScreen> {
  final _controller = TextEditingController();
  bool _isAvailable = false;
  bool _isChecking = false;
  String? _usernameError;

  // Simple regex: letters, numbers, hyphens only, no spaces
  static final _validUsername = RegExp(r'^[a-zA-Z0-9\-]{3,30}$');

  @override
  void initState() {
    super.initState();
    // Pre-fill with name derived from Google account
    if (widget.claimState.verifiedName != null) {
      _controller.text = widget.claimState.verifiedName!
          .toLowerCase()
          .replaceAll(' ', '-')
          .replaceAll(RegExp(r'[^a-z0-9\-]'), '');
    }
    _controller.addListener(_onUsernameChanged);
  }

  void _onUsernameChanged() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() { _isAvailable = false; _usernameError = null; });
      return;
    }
    if (!_validUsername.hasMatch(text)) {
      setState(() {
        _isAvailable = false;
        _usernameError = 'Only letters, numbers, hyphens (3–30 chars)';
      });
      return;
    }
    setState(() { _usernameError = null; _isChecking = true; });
    // Debounce: wait 600ms then mark available (real check happens on backend at Finish)
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && _controller.text.trim() == text) {
        setState(() { _isAvailable = true; _isChecking = false; });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: sp),
            child: TextButton(
              onPressed: _isAvailable
                  ? () {
                      widget.claimState.username = _controller.text.trim();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClaimConfirmScreen(
                              claimState: widget.claimState),
                        ),
                      );
                    }
                  : null,
              child: Text(
                'Next',
                style: TextStyle(
                  color: _isAvailable
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: R.fs(context, 15),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: R.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: sp),

            RichText(
              text: TextSpan(
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: R.fs(context, 34),
                  fontWeight: FontWeight.w300,
                ),
                children: const [
                  TextSpan(text: 'Choose your '),
                  TextSpan(
                      text: 'username',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            SizedBox(height: sp * 2.5),

            // ── Verified Google email badge ───────────────────────────
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: sp * 1.2, vertical: sp * 0.8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B2E1C) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded,
                      color: Color(0xFF4CAF50), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Verified Gmail',
                            style: TextStyle(
                                color: const Color(0xFF388E3C),
                                fontSize: R.fs(context, 11),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5)),
                        Text(widget.claimState.verifiedEmail ?? '',
                            style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: R.fs(context, 13),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: sp * 2),

            // ── Username field ────────────────────────────────────────
            TextField(
              controller: _controller,
              autocorrect: false,
              style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'e.g. ali-ahmed, greenuser99',
                hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey[400],
                    fontSize: R.fs(context, 14)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 20),
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.grey[100],
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: _usernameError != null
                          ? Colors.red
                          : const Color(0xFFE3F2FD),
                      width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: _usernameError != null
                          ? Colors.red
                          : const Color(0xFF2196F3),
                      width: 2),
                ),
                suffixIcon: _isChecking
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF2196F3))),
                      )
                    : _isAvailable
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(Icons.check_circle,
                                color: Color(0xFF4CAF50), size: 28),
                          )
                        : null,
              ),
            ),

            SizedBox(height: sp * 0.75),

            if (_usernameError != null)
              Text(_usernameError!,
                  style: TextStyle(
                      color: Colors.red, fontSize: R.fs(context, 12)))
            else
              Text(
                'Letters, numbers, or hyphens only (no spaces). 3–30 characters.',
                style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey,
                    fontSize: R.fs(context, 12)),
              ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// STEP 3: CONFIRMATION & FINISH
// ==========================================
class ClaimConfirmScreen extends StatefulWidget {
  final ClaimWizardState claimState;
  const ClaimConfirmScreen({super.key, required this.claimState});

  @override
  State<ClaimConfirmScreen> createState() => _ClaimConfirmScreenState();
}

class _ClaimConfirmScreenState extends State<ClaimConfirmScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _finish() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      await ApiService.instance.verifyGoogleAndClaim(
        idToken:     widget.claimState.googleIdToken!,
        username:    widget.claimState.username,
        displayName: widget.claimState.verifiedName,
        photoUrl:    widget.claimState.photoUrl,
      );

      if (!mounted) return;
      // Navigate back to dashboard and refresh
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = widget.claimState;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: R.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: sp),

            RichText(
              text: TextSpan(
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: R.fs(context, 34),
                  fontWeight: FontWeight.w300,
                  height: 1.2,
                ),
                children: const [
                  TextSpan(text: 'Almost\n'),
                  TextSpan(
                      text: 'done!',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            SizedBox(height: sp * 3),

            // ── Profile preview card ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(sp * 1.5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 20,
                      offset: const Offset(0, 6)),
                ],
                border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: const Color(0xFF2196F3).withValues(alpha: 0.12),
                    backgroundImage: state.photoUrl != null
                        ? NetworkImage(state.photoUrl!)
                        : null,
                    child: state.photoUrl == null
                        ? Text(
                            (state.verifiedName ?? 'G')[0].toUpperCase(),
                            style: const TextStyle(
                                color: Color(0xFF2196F3),
                                fontSize: 32,
                                fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  SizedBox(height: sp),
                  Text(state.verifiedName ?? '',
                      style: TextStyle(
                          fontSize: R.fs(context, 20),
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.alternate_email,
                          size: 14, color: Color(0xFF2196F3)),
                      const SizedBox(width: 4),
                      Text(state.username ?? '',
                          style: TextStyle(
                              color: const Color(0xFF2196F3),
                              fontSize: R.fs(context, 13),
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  SizedBox(height: sp * 0.75),

                  // Verified Gmail badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color:
                              const Color(0xFF4CAF50).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded,
                            color: Color(0xFF4CAF50), size: 15),
                        const SizedBox(width: 6),
                        Text(state.verifiedEmail ?? '',
                            style: TextStyle(
                                color: const Color(0xFF388E3C),
                                fontSize: R.fs(context, 12),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: sp * 2),

            // ── Info rows ─────────────────────────────────────────────
            _buildSummaryRow(
                context, Icons.shield_outlined, 'Email Verified by Google',
                'Confirmed ownership of this Gmail', isDark),
            SizedBox(height: sp * 0.75),
            _buildSummaryRow(
                context, Icons.history_rounded, 'History Preserved',
                'All scans & points carry over', isDark),
            SizedBox(height: sp * 0.75),
            _buildSummaryRow(
                context, Icons.leaderboard_rounded, 'Leaderboard Name',
                'Will appear as @${state.username}', isDark),

            SizedBox(height: sp * 3),

            // ── Error ─────────────────────────────────────────────────
            if (_error != null) ...[
              Container(
                padding: EdgeInsets.all(sp),
                margin: EdgeInsets.only(bottom: sp),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_error!,
                          style: TextStyle(
                              color: Colors.red[700], fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],

            // ── Finish button ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: R.h(context, 7.5),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _finish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        'CLAIM MY ACCOUNT',
                        style: TextStyle(
                            fontSize: R.fs(context, 14),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8),
                      ),
              ),
            ),

            SizedBox(height: sp * 4),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, IconData icon, String title,
      String subtitle, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF2196F3), size: 20),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: R.fs(context, 13),
                    fontWeight: FontWeight.bold)),
            Text(subtitle,
                style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey,
                    fontSize: R.fs(context, 12))),
          ],
        ),
      ],
    );
  }
}
