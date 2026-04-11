import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import 'goal_selection_screen.dart';
import 'login_selection_screen.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: sp * 2),

            Padding(
              padding: R.pagePadding(context),
              child: Text(
                'GREENBIN',
                style: TextStyle(
                  color: const Color(0xFF2196F3),
                  fontSize: R.fs(context, 20),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: Image.asset(
                'assets/images/intro_illustration.png',
                fit: BoxFit.fitWidth,
                height: R.h(context, 32),
              ),
            ),

            const Spacer(),

            Padding(
              padding: R.pagePadding(context),
              child: Column(
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: R.fs(context, 26),
                        fontWeight: FontWeight.w400,
                      ),
                      children: const [
                        TextSpan(text: 'Welcome to '),
                        TextSpan(
                          text: 'GreenBin',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: sp * 0.75),
                  Text(
                    'Let\'s Begin Your Eco Journey',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: R.fs(context, 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: sp * 0.5),
                  Text(
                    'Together we make the world cleaner.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: R.fs(context, 14),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            Padding(
              padding: R.pagePadding(context),
              child: SizedBox(
                width: double.infinity,
                height: R.buttonHeight(context),
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const GoalSelectionScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: Text(
                    'GET STARTED',
                    style: TextStyle(
                      fontSize: R.fs(context, 15),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: sp * 1.5),

            Padding(
              padding: R.pagePadding(context),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(color: Colors.grey[500], fontSize: R.fs(context, 11)),
                  children: [
                    const TextSpan(text: 'by continuing you agree to GreenBin '),
                    TextSpan(
                      text: 'Terms of Service',
                      style: const TextStyle(
                          color: Color(0xFFFF4081), fontWeight: FontWeight.w600),
                      recognizer: TapGestureRecognizer()..onTap = () {},
                    ),
                    const TextSpan(text: ', GreenBin '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: const TextStyle(
                          color: Color(0xFFFF4081), fontWeight: FontWeight.w600),
                      recognizer: TapGestureRecognizer()..onTap = () {},
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: sp * 2),

            Padding(
              padding: R.pagePadding(context),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.grey[600], fontSize: R.fs(context, 13)),
                  children: [
                    const TextSpan(text: 'Already have an account? '),
                    TextSpan(
                      text: 'Login here',
                      style: const TextStyle(
                          color: Color(0xFFFF4081), fontWeight: FontWeight.w600),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const LoginSelectionScreen()),
                            ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
            SizedBox(height: sp),
          ],
        ),
      ),
    );
  }
}