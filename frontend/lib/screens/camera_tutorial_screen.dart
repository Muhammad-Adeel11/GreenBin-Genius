import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import 'dashboard_screen.dart';
import 'camera_scanner_screen.dart';

// ==========================================
// PAGE 1: What is a good photo?
// ==========================================
class TutorialStep1 extends StatelessWidget {
  const TutorialStep1({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: sp),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TutorialStep2()),
                );
              },
              child: Text("Next", style: TextStyle(color: Colors.white, fontSize: R.fs(context, 16))),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: R.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.white, fontSize: R.fs(context, 32), fontWeight: FontWeight.w300),
                  children: const [
                    TextSpan(text: 'What is a good '),
                    TextSpan(text: 'photo?', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              SizedBox(height: sp * 2),

              Expanded(
                child: Center(
                  child: Image.asset(
                    'assets/images/tut_grid.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(16)
                        ),
                        child: Center(
                          child: Text(
                              "Tut Grid Image",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white54, fontSize: R.fs(context, 14))
                          ),
                        ),
                      );
                    },
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
}

// ==========================================
// PAGE 2: Turn litter into data
// ==========================================
class TutorialStep2 extends StatelessWidget {
  const TutorialStep2({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: sp),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TutorialStep3()),
                );
              },
              child: Text("Next", style: TextStyle(color: Colors.white, fontSize: R.fs(context, 16))),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Turn litter...", style: TextStyle(color: Colors.white, fontSize: R.fs(context, 18), fontWeight: FontWeight.bold)),
              SizedBox(height: sp),

              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/tut_can1.png',
                  height: R.h(context, 24),
                  width: R.w(context, 65),
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    height: R.h(context, 24), 
                    width: R.w(context, 65), 
                    color: Colors.grey[800], 
                    child: Center(child: Text("Before Image", style: TextStyle(color: Colors.white, fontSize: R.fs(context, 14))))
                  ),
                ),
              ),

              SizedBox(height: sp),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("into data! ", style: TextStyle(color: Colors.white, fontSize: R.fs(context, 18), fontWeight: FontWeight.bold)),
                  Icon(Icons.arrow_downward, color: Colors.white, size: R.icon(context, 24)),
                ],
              ),
              SizedBox(height: sp),

              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: sp, left: sp, right: sp),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/tut_can2.png',
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => Container(
                          width: double.infinity,
                          color: Colors.grey[800],
                          child: Center(child: Text("After Image (Tagged)", style: TextStyle(color: Colors.white, fontSize: R.fs(context, 14))))
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// PAGE 3: Activate Camera (Permissions Mock)
// ==========================================
class TutorialStep3 extends StatelessWidget {
  const TutorialStep3({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: sp),
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AiScannerScreen()),
                );
              },
              child: Text("Next", style: TextStyle(color: Colors.white, fontSize: R.fs(context, 16))),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: R.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.white, fontSize: R.fs(context, 32), fontWeight: FontWeight.w300),
                  children: const [
                    TextSpan(text: 'Activate your '),
                    TextSpan(text: 'camera', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              SizedBox(height: sp),
              Text(
                "GreenBin needs access to your camera to let you take photos of litter to upload to challenges.",
                style: TextStyle(color: Colors.white70, fontSize: R.fs(context, 16), height: 1.4),
              ),
              const Spacer(),

              // Mock Android Permission Dialog
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    SizedBox(height: sp * 1.5),
                    Icon(Icons.camera_alt, color: const Color(0xFF2196F3), size: R.icon(context, 32)),
                    SizedBox(height: sp),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        "Allow GreenBin to take pictures and record video?",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black, fontSize: R.fs(context, 16), fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: sp * 1.5),

                    _buildDialogButton(context, "WHILE USING THE APP", const Color(0xFF2196F3), Colors.white, () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AiScannerScreen()));
                    }),
                    const Divider(height: 1, thickness: 1),
                    _buildDialogButton(context, "ONLY THIS TIME", Colors.white, Colors.black, () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AiScannerScreen()));
                    }),
                    const Divider(height: 1, thickness: 1),
                    _buildDialogButton(context, "DENY", Colors.white, Colors.black, () {
                      Navigator.pop(context);
                    }),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogButton(BuildContext context, String text, Color bgColor, Color textColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        color: bgColor,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: R.fs(context, 14)),
        ),
      ),
    );
  }
}

// ==========================================
// THE ACTUAL CAMERA SCREEN (Placeholder)
// ==========================================
class ActiveCameraScreen extends StatelessWidget {
  const ActiveCameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Icon(Icons.fullscreen, color: Colors.white.withOpacity(0.3), size: R.icon(context, 200)),
            ),

            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: R.icon(context, 30)),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const DashboardScreen()),
                      (route) => false
                  );
                },
              ),
            ),

            Positioned(
              bottom: R.h(context, 5),
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    // 1. ADD MOCK PHOTO
                    DashboardScreen.globalActivityPhotos.add('assets/images/tut_can1.png');

                    // 2. NAVIGATE BACK
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DashboardScreen(
                          initialTabIndex: 0, 
                          justUploaded: true,
                        ),
                      ),
                      (route) => false,
                    );
                  },
                  child: Container(
                    height: R.icon(context, 80),
                    width: R.icon(context, 80),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
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
    );
  }
}
