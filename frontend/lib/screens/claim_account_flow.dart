import 'package:flutter/material.dart';
import '../utils/responsive.dart';

// ==========================================
// STEP 1: DISPLAY NAME
// ==========================================
class ClaimDisplayNameScreen extends StatelessWidget {
  const ClaimDisplayNameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: sp),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ClaimUsernameScreen()),
                );
              },
              child: Text(
                "Next",
                style: TextStyle(
                  color: const Color(0xFFFF4081),
                  fontWeight: FontWeight.bold,
                  fontSize: R.fs(context, 15),
                ),
              ),
            ),
          )
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
                  color: Colors.black,
                  fontSize: R.fs(context, 34),
                  fontWeight: FontWeight.w300,
                  height: 1.2,
                ),
                children: const [
                  TextSpan(text: 'What is your '),
                  TextSpan(text: 'public\ndisplay name', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: '?'),
                ],
              ),
            ),
            SizedBox(height: sp * 2.5),
            TextField(
              decoration: InputDecoration(
                hintText: "Your public display name",
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: R.fs(context, 14)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
                ),
              ),
            ),
            SizedBox(height: sp),
            Text(
              "Please enter at least 2 characters.",
              style: TextStyle(color: Colors.grey, fontSize: R.fs(context, 12)),
            ),
            SizedBox(height: sp * 0.5),
            Text(
              "Your display name, username and profile picture will be visible to the GreenBin community.",
              style: TextStyle(color: Colors.grey, fontSize: R.fs(context, 12), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// STEP 2: USERNAME
// ==========================================
class ClaimUsernameScreen extends StatefulWidget {
  const ClaimUsernameScreen({super.key});

  @override
  State<ClaimUsernameScreen> createState() => _ClaimUsernameScreenState();
}

class _ClaimUsernameScreenState extends State<ClaimUsernameScreen> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isAvailable = false;

  // A mock list of "already taken" usernames
  final List<String> _takenUsernames = ['admin', 'test', 'user', 'greenbin', 'syedmuhammad'];

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_checkUsernameAvailability);
  }

  void _checkUsernameAvailability() {
    final text = _usernameController.text.trim().toLowerCase();
    setState(() {
      _isAvailable = text.isNotEmpty && !_takenUsernames.contains(text);
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: sp),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ClaimLoginDetailsScreen()),
                );
              },
              child: Text(
                "Next",
                style: TextStyle(
                  color: const Color(0xFFFF4081),
                  fontWeight: FontWeight.bold,
                  fontSize: R.fs(context, 15),
                ),
              ),
            ),
          )
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
                  color: Colors.black,
                  fontSize: R.fs(context, 34),
                  fontWeight: FontWeight.w300,
                ),
                children: const [
                  TextSpan(text: 'Choose your '),
                  TextSpan(text: 'username', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            SizedBox(height: sp * 2.5),
            TextField(
              controller: _usernameController,
              autocorrect: false,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE3F2FD), width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE3F2FD), width: 2),
                ),
                suffixIcon: _isAvailable
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Icon(Icons.check_circle, color: Color(0xFF8BC34A), size: 28),
                      )
                    : null,
              ),
            ),
            SizedBox(height: sp),
            Text(
              "Please only use letters, numbers, or hyphens for Username (no spaces)",
              style: TextStyle(color: Colors.grey, fontSize: R.fs(context, 12)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// STEP 3: LOGIN DETAILS
// ==========================================
class ClaimLoginDetailsScreen extends StatefulWidget {
  const ClaimLoginDetailsScreen({super.key});

  @override
  State<ClaimLoginDetailsScreen> createState() => _ClaimLoginDetailsScreenState();
}

class _ClaimLoginDetailsScreenState extends State<ClaimLoginDetailsScreen> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: sp),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ClaimProfileImageScreen()),
                );
              },
              child: Text(
                "Next",
                style: TextStyle(
                  color: const Color(0xFFFF4081),
                  fontWeight: FontWeight.bold,
                  fontSize: R.fs(context, 15),
                ),
              ),
            ),
          )
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
                  color: Colors.black,
                  fontSize: R.fs(context, 34),
                  fontWeight: FontWeight.w300,
                ),
                children: const [
                  TextSpan(text: 'Create your '),
                  TextSpan(text: 'login', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: ' details'),
                ],
              ),
            ),
            SizedBox(height: sp * 2.5),

            // Email Field (Yellow highlight)
            TextField(
              style: TextStyle(fontSize: R.fs(context, 14)),
              decoration: InputDecoration(
                hintText: "Email address",
                fillColor: const Color(0xFFFFF9C4),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            SizedBox(height: sp * 1.5),

            // Password Field
            TextField(
              obscureText: _obscurePassword,
              style: TextStyle(fontSize: R.fs(context, 14)),
              decoration: InputDecoration(
                hintText: "Password",
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE3F2FD), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE3F2FD), width: 1.5),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF2196F3),
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            SizedBox(height: sp),
            Text(
              "Minimum of 8 characters with at least 1 uppercase, 1 lowercase, and 1 number.",
              style: TextStyle(color: Colors.grey, fontSize: R.fs(context, 12), height: 1.4),
            ),
            SizedBox(height: sp * 2),

            // Custom Checkbox
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2196F3),
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(2.0),
                    child: Icon(Icons.check, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "I wish to receive email communication from GreenBin with tips, resources & product updates",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: R.fs(context, 14),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// STEP 4: PROFILE IMAGE
// ==========================================
class ClaimProfileImageScreen extends StatelessWidget {
  const ClaimProfileImageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: sp),
            child: TextButton(
              onPressed: () {
                // Finish Flow: Go all the way back to the Dashboard/Profile
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text(
                "Finish",
                style: TextStyle(
                  color: const Color(0xFFFF4081),
                  fontWeight: FontWeight.bold,
                  fontSize: R.fs(context, 15),
                ),
              ),
            ),
          )
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
                  color: Colors.black,
                  fontSize: R.fs(context, 34),
                  fontWeight: FontWeight.w300,
                  height: 1.2,
                ),
                children: [
                  const TextSpan(text: 'Add a '),
                  const TextSpan(text: 'profile image', style: TextStyle(fontWeight: FontWeight.bold)),
                  const TextSpan(text: ' to\nyour account '),
                  TextSpan(text: '(Optional)', style: TextStyle(fontSize: R.fs(context, 14), color: Colors.grey)),
                ],
              ),
            ),
            SizedBox(height: R.h(context, 8)),

            // Profile Image Upload Circle
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: R.icon(context, 200),
                    height: R.icon(context, 200),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.cyanAccent, Colors.blue, Colors.purpleAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(Icons.person, color: Colors.white, size: R.icon(context, 100)),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        color: const Color(0xFF2196F3),
                        size: R.icon(context, 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
