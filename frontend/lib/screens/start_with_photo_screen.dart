import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import 'register_screen.dart';

class StartWithPhotoScreen extends StatelessWidget {
  const StartWithPhotoScreen({super.key});

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
      ),
      body: SafeArea(
        child: Padding(
          padding: R.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: sp * 0.5),

              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: R.fs(context, 26),
                    fontWeight: FontWeight.w400,
                  ),
                  children: const [
                    TextSpan(text: 'Start with a '),
                    TextSpan(
                      text: 'Photo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              Center(
                child: Column(
                  children: [
                    Container(
                      height: R.h(context, 28),
                      width: R.h(context, 28),
                      padding: EdgeInsets.all(sp * 1.5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Image.asset(
                              'assets/images/cup_example.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const Positioned(
                            top: 0,
                            right: 0,
                            child: Icon(Icons.eco,
                                color: Color(0xFF4CAF50), size: 24),
                          ),
                          const Positioned(
                            left: 0,
                            top: 60,
                            child: Icon(Icons.eco,
                                color: Color(0xFF2E7D32), size: 24),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: sp * 1.25),

                    SizedBox(
                      width: R.w(context, 75),
                      child: Column(
                        children: [
                          _buildTagRow(context, 'Category', 'Drink', isFirst: true),
                          _buildTagRow(context, 'Object', 'Cup'),
                          _buildTagRow(context, 'Material', 'Plastic'),
                          _buildTagRow(context, 'Confidence', '98%', isLast: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: R.fs(context, 22),
                    fontWeight: FontWeight.w300,
                  ),
                  children: [
                    const TextSpan(text: 'Find '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2196F3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.camera_alt,
                            color: Colors.white,
                            size: R.icon(context, 18)),
                      ),
                    ),
                    const TextSpan(
                        text: ' on your screen\nto get started'),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              SizedBox(
                width: double.infinity,
                height: R.buttonHeight(context),
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegisterScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: Text(
                    'START',
                    style: TextStyle(
                      fontSize: R.fs(context, 15),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              SizedBox(height: sp * 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagRow(BuildContext context, String label, String value,
      {bool isFirst = false, bool isLast = false}) {
    final sp = R.sp(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 1,
                    color: isFirst ? Colors.transparent : Colors.grey[300],
                    margin: const EdgeInsets.only(left: 20),
                  ),
                ),
                Row(children: [
                  const SizedBox(width: 20),
                  Container(width: 12, height: 1, color: Colors.grey[300]),
                ]),
                Expanded(
                  child: Container(
                    width: 1,
                    color: isLast ? Colors.transparent : Colors.grey[300],
                    margin: const EdgeInsets.only(left: 20),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: sp * 0.4),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: R.fs(context, 13),
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: sp, vertical: sp * 0.35),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: R.fs(context, 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}