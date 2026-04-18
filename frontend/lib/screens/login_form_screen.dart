import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';

class LoginFormScreen extends StatefulWidget {
  const LoginFormScreen({super.key});

  @override
  State<LoginFormScreen> createState() => _LoginFormScreenState();
}

class _LoginFormScreenState extends State<LoginFormScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ApiService.instance.login(email: email, password: password);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);

    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient Background ───────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF2196F3)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ── Background Decorative Circles ─────────────────────────────────
          Positioned(
            top: -50,
            right: -50,
            child: _buildGlassCircle(200),
          ),
          Positioned(
            bottom: 100,
            left: -30,
            child: _buildGlassCircle(120),
          ),

          // ── Main Content ──────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: R.pagePadding(context),
              child: Column(
                children: [
                  SizedBox(height: R.h(context, 8)),

                  // Brand Header
                  _buildBrandHeader(context),

                  SizedBox(height: R.h(context, 6)),

                  // Login Card
                  _buildLoginCard(context, sp),

                  SizedBox(height: sp * 2),

                  // Register text
                  _buildRegisterLink(context),
                  
                  SizedBox(height: sp),
                ],
              ),
            ),
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildBrandHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: const Icon(
            Icons.recycling,
            color: Colors.white,
            size: 50,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'GREENBIN GENIUS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: R.fs(context, 26),
            letterSpacing: 2,
          ),
        ),
        Text(
          'Intelligent Waste Classification',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: R.fs(context, 14),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(BuildContext context, double sp) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Back!',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: R.fs(context, 22),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to your account',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: R.fs(context, 14),
            ),
          ),
          SizedBox(height: sp * 1.5),

          // Email Field
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.alternate_email,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: sp),

          // Password Field
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock_outline,
            isPassword: true,
            obscureText: _obscurePassword,
            onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
          ),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: const Color(0xFF1976D2),
                  fontWeight: FontWeight.bold,
                  fontSize: R.fs(context, 13),
                ),
              ),
            ),
          ),

          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
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
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red[700], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: sp),
          ],

          SizedBox(
            width: double.infinity,
            height: R.buttonHeight(context),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: const Color(0xFF0D47A1).withOpacity(0.5),
              ),
              child: _isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      'LOG IN',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: R.fs(context, 15), letterSpacing: 1),
                    ),
            ),
          ),

          SizedBox(height: sp * 1.2),

          // Social Login Separator
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey[300])),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('OR', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ),
              Expanded(child: Divider(color: Colors.grey[300])),
            ],
          ),

          SizedBox(height: sp * 1.2),

          // Social Login Buttons
          Row(
            children: [
              Expanded(child: _buildSocialButton('Google', Icons.g_mobiledata, Colors.red[400]!)),
              const SizedBox(width: 16),
              Expanded(child: _buildSocialButton('Apple', Icons.apple, Colors.black)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: label,
              prefixIcon: Icon(icon, color: const Color(0xFF1976D2), size: 22),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: onToggleVisibility,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(String label, IconData icon, Color color) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account? ",
          style: TextStyle(color: Colors.white70),
        ),
        GestureDetector(
          onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          ),
          child: const Text(
            'Create Account',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}