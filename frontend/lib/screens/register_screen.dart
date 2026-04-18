import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import 'login_form_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name     = _nameController.text.trim();
    final email    = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      await ApiService.instance.register(
        name:     name,
        email:    email,
        password: password,
      );
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
                colors: [Color(0xFF00695C), Color(0xFF00897B), Color(0xFF26A69A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ── Background Decorative Circles ─────────────────────────────────
          Positioned(
            top: -50,
            left: -50,
            child: _buildGlassCircle(200),
          ),
          Positioned(
            bottom: 100,
            right: -30,
            child: _buildGlassCircle(120),
          ),

          // ── Main Content ──────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: R.pagePadding(context),
              child: Column(
                children: [
                  SizedBox(height: R.h(context, 5)),

                  // Header
                  _buildHeader(context),

                  SizedBox(height: R.h(context, 4)),

                  // Register Card
                  _buildRegisterCard(context, sp),

                  SizedBox(height: sp * 2),

                  // Login text
                  _buildLoginLink(context),
                  
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

  Widget _buildHeader(BuildContext context) {
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
            Icons.person_add_alt_1_outlined,
            color: Colors.white,
            size: 50,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'JOIN THE MISSION',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: R.fs(context, 24),
            letterSpacing: 2,
          ),
        ),
        Text(
          'Create your account to start recycling',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: R.fs(context, 14),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterCard(BuildContext context, double sp) {
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
            'Get Started',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: R.fs(context, 22),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your details to register',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: R.fs(context, 14),
            ),
          ),
          SizedBox(height: sp * 1.5),

          // Name Field
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
          ),
          SizedBox(height: sp),

          // Email Field
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.alternate_email,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: sp),

          // Password Field
          _buildTextField(
            controller: _passwordController,
            label: 'Password (min 6 chars)',
            icon: Icons.lock_outline,
            isPassword: true,
            obscureText: _obscurePassword,
            onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
          ),

          SizedBox(height: sp),

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
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00695C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: const Color(0xFF00695C).withOpacity(0.5),
              ),
              child: _isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      'CREATE ACCOUNT',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: R.fs(context, 14), letterSpacing: 1),
                    ),
            ),
          ),
          
          SizedBox(height: sp),
          
          Center(
            child: Text(
              'By registering, you agree to our Terms & Privacy',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
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
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        style: const TextStyle(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF00897B), size: 22),
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
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Already have an account? ",
          style: TextStyle(color: Colors.white70),
        ),
        GestureDetector(
          onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginFormScreen()),
          ),
          child: const Text(
            'Log In',
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
