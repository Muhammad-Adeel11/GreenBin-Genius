import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import 'login_form_screen.dart';

class LoginSelectionScreen extends StatelessWidget {
  const LoginSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'GREENBIN',
          style: TextStyle(
            color: Colors.grey[400],
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            fontSize: R.fs(context, 22),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: R.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: sp * 3),

              Text(
                'Login to your existing GreenBin\naccount',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: R.fs(context, 17),
                  height: 1.4,
                ),
              ),

              SizedBox(height: sp * 2.5),

              SizedBox(
                width: double.infinity,
                height: R.buttonHeight(context),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginFormScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE3F2FD),
                    foregroundColor: const Color(0xFF2196F3),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  icon: Icon(Icons.mail_outline, size: R.icon(context, 22)),
                  label: Text(
                    'LOGIN WITH EMAIL',
                    style: TextStyle(
                      fontSize: R.fs(context, 14),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(
                height: R.h(context, 22),
                width: double.infinity,
                child: Image.asset(
                  'assets/images/intro_illustration.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                ),
              ),

              SizedBox(height: sp),
            ],
          ),
        ),
      ),
    );
  }
}