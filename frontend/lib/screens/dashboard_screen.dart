import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import 'camera_scanner_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 2;

  final List<Widget> _pages = [
    const Center(child: Text("Activity Page")),
    const Center(child: Text("Challenges Page")),
    const ImpactTab(),
    const Center(child: Text("Leaderboard Page")),
    const Center(child: Text("Tasks Page")),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AiScannerScreen()),
        ),
        backgroundColor: const Color(0xFF2196F3),
        child: Icon(Icons.camera_alt, color: Colors.white,
            size: R.icon(context, 26)),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF2196F3),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: TextStyle(
            fontSize: R.fs(context, 11), fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: R.fs(context, 11)),
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.bubble_chart_outlined), label: 'Activity'),
          BottomNavigationBarItem(
              icon: Icon(Icons.flag_outlined), label: 'Challenges'),
          BottomNavigationBarItem(
              icon: Icon(Icons.language), label: 'Impact'),
          BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined), label: 'Leaderboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined), label: 'Tasks'),
        ],
      ),
    );
  }
}

// ── Impact Tab ──────────────────────────────────────────────

class ImpactTab extends StatelessWidget {
  const ImpactTab({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Blue Header
          ClipPath(
            clipper: HeaderCurveClipper(),
            child: Container(
              height: R.h(context, 38),
              width: double.infinity,
              color: const Color(0xFF2196F3),
              child: SafeArea(
                child: Padding(
                  padding: R.pagePadding(context).add(
                      EdgeInsets.only(top: sp)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              width: R.icon(context, 40),
                              height: R.icon(context, 40),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.cyanAccent, Colors.blue],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.public,
                                  color: Colors.white),
                            ),
                          ),
                          Text(
                            "Impact",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: R.fs(context, 20),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: R.icon(context, 40)),
                        ],
                      ),

                      SizedBox(height: sp * 2),

                      Text(
                        "Total Global Litter Pickup",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: R.fs(context, 15),
                        ),
                      ),
                      SizedBox(height: sp * 0.5),
                      Text(
                        "24,291,206",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: R.fs(context, 44),
                          fontWeight: FontWeight.w400,
                          letterSpacing: -1.0,
                        ),
                      ),

                      SizedBox(height: sp * 1.5),

                      Text(
                        "Overall Pickup For November, 2025",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: R.fs(context, 15),
                        ),
                      ),
                      SizedBox(height: sp * 0.5),
                      Text(
                        "85,450",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: R.fs(context, 44),
                          fontWeight: FontWeight.w400,
                          letterSpacing: -1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: sp * 1.5),

          // Bar Chart
          Padding(
            padding: R.pagePadding(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar(context, "APR", 60, false),
                _buildBar(context, "MAY", 80, false),
                _buildBar(context, "JUN", 40, false),
                _buildBar(context, "JUL", 70, false),
                _buildBar(context, "AUG", 50, false),
                _buildBar(context, "SEP", 65, false),
                _buildBar(context, "OCT", 45, false),
                _buildBar(context, "NOV", 55, true),
              ],
            ),
          ),

          SizedBox(height: sp * 2.5),

          // Activity Section Title
          Padding(
            padding: R.pagePadding(context),
            child: SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Text("My ",
                        style: TextStyle(
                            fontSize: R.fs(context, 26),
                            fontWeight: FontWeight.w300)),
                    Text("Activity ",
                        style: TextStyle(
                            fontSize: R.fs(context, 26),
                            fontWeight: FontWeight.bold)),
                    Text("This Week",
                        style: TextStyle(
                            fontSize: R.fs(context, 26),
                            fontWeight: FontWeight.w300)),
                    SizedBox(width: sp * 0.75),
                    Icon(Icons.info,
                        color: Colors.blue[500],
                        size: R.icon(context, 26)),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: sp),

          // Date Circles
          SizedBox(
            height: R.h(context, 7),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: R.pagePadding(context),
              children: [
                _buildDateCircle(context, "11/27"),
                _buildDateCircle(context, "11/28"),
                _buildDateCircle(context, "11/29"),
                _buildDateCircle(context, "11/30"),
                _buildDateCircle(context, "12/1"),
                _buildDateCircle(context, "12/2"),
                _buildDateCircle(context, "12/3", isActive: true),
              ],
            ),
          ),

          SizedBox(height: sp * 2.5),

          // Stories of Impact
          Padding(
            padding: R.pagePadding(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Stories of\nImpact",
                  style: TextStyle(
                      fontSize: R.fs(context, 24),
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  "View All",
                  style: TextStyle(
                      color: Colors.pink[400],
                      fontWeight: FontWeight.bold,
                      fontSize: R.fs(context, 14)),
                ),
              ],
            ),
          ),

          SizedBox(height: sp),

          SizedBox(
            height: R.h(context, 26),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: R.pagePadding(context),
              children: [
                _buildStoryCard(context, "Litter Data Helps San Francisco Win Court Case",
                    "https://picsum.photos/300/200?random=10"),
                _buildStoryCard(context, "How Lodi brought together its local businesses",
                    "https://picsum.photos/300/200?random=11"),
              ],
            ),
          ),
          SizedBox(height: sp * 6), // FAB space
        ],
      ),
    );
  }

  Widget _buildBar(
      BuildContext context, String label, double barH, bool isActive) {
    final scaledH = R.isSmall(context) ? barH * 0.75 : barH;
    return Column(
      children: [
        Container(
          width: R.isSmall(context) ? 6.0 : 8.0,
          height: scaledH,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF2196F3)
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: R.fs(context, 9),
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDateCircle(BuildContext context, String date,
      {bool isActive = false}) {
    final size = R.h(context, 6.5).clamp(42.0, 60.0);
    return Container(
      width: size,
      height: size,
      margin: EdgeInsets.only(right: R.sp(context) * 0.75),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2196F3) : Colors.grey[400],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          date,
          style: TextStyle(
            color: Colors.white,
            fontSize: R.fs(context, 11),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStoryCard(
      BuildContext context, String title, String imageUrl) {
    final sp = R.sp(context);
    return Container(
      width: R.w(context, 56),
      margin: EdgeInsets.only(right: sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              imageUrl,
              height: R.h(context, 14),
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(sp),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: R.fs(context, 13),
                height: 1.2,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height * 0.85)
      ..quadraticBezierTo(size.width * 0.25, size.height,
          size.width * 0.6, size.height * 0.85)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.75,
          size.width, size.height * 0.6)
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}