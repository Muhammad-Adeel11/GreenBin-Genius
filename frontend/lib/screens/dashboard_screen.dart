import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import 'camera_tutorial_screen.dart';
import 'profile_screen.dart';
import 'bin_locator_screen.dart';

class DashboardScreen extends StatefulWidget {
  final int initialTabIndex;
  final bool justUploaded;

  const DashboardScreen({
    super.key,
    this.initialTabIndex = 2,
    this.justUploaded = false,
  });

  static List<String> globalActivityPhotos = [];

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      ActivityTab(
        photos: DashboardScreen.globalActivityPhotos,
        justUploaded: widget.justUploaded,
      ),
      const BinLocatorScreen(isTabMode: true),
      const ImpactTab(),
      const LeaderboardTab(),
      const TasksTab(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: pages[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TutorialStep1()),
          );
        },
        backgroundColor: const Color(0xFF007AFF),
        shape: const CircleBorder(),
        child: Icon(Icons.camera_alt, color: Colors.white, size: R.icon(context, 28)),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF007AFF),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: TextStyle(fontSize: R.fs(context, 11), fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: R.fs(context, 11)),
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bubble_chart_outlined), label: 'Activity'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.language), label: 'Impact'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), label: 'Leaderboard'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Tasks'),
        ],
      ),
    );
  }
}

// Helper function to handle the custom slide animation to the Profile Screen
void _navigateToProfile(BuildContext context) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = const Offset(-1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.easeInOutQuart;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    ),
  );
}

// ==========================================
// TASKS TAB
// ==========================================
class TasksTab extends StatelessWidget {
  const TasksTab({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);

    return Column(
      children: [
        Container(
          color: const Color(0xFF007AFF),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: R.pagePadding(context).add(EdgeInsets.symmetric(vertical: R.h(context, 1.5))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _navigateToProfile(context),
                    child: Container(
                      width: R.icon(context, 36),
                      height: R.icon(context, 36),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.cyanAccent, Colors.blue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                  Text("Tasks", style: TextStyle(color: Colors.white, fontSize: R.fs(context, 18), fontWeight: FontWeight.bold)),
                  SizedBox(width: R.icon(context, 36)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: sp * 2),
                Image.asset(
                  'assets/images/tasks_illustration.png',
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: R.h(context, 30),
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.grey[100]),
                    child: Center(child: Text("tasks_illustration.png goes here", style: TextStyle(color: Colors.grey, fontSize: R.fs(context, 14)))),
                  ),
                ),
                SizedBox(height: sp * 3),
                Padding(
                  padding: R.pagePadding(context),
                  child: Column(
                    children: [
                      Text(
                        "Want To Collect More Detailed Litter Data?",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: R.fs(context, 15), fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      SizedBox(height: sp),
                      Text(
                        "APPLY TO BECOME A GREENBIN\nRESEARCHER NOW",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: R.fs(context, 18), fontWeight: FontWeight.w900, color: const Color(0xFF007AFF), letterSpacing: 0.5, height: 1.4),
                      ),
                      SizedBox(height: sp * 2.5),
                      Container(
                        width: double.infinity,
                        height: R.h(context, 7),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))],
                        ),
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text("APPLY NOW!", style: TextStyle(fontSize: R.fs(context, 13), fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                        ),
                      ),
                      SizedBox(height: R.h(context, 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// LEADERBOARD TAB
// ==========================================
class LeaderboardTab extends StatefulWidget {
  const LeaderboardTab({super.key});

  @override
  State<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<LeaderboardTab> {
  bool _isMembersActive = true;
  String _selectedTimeFilter = 'Last 24 Hours';

  final List<Map<String, dynamic>> membersData = [
    {'rank': '999+', 'name': 'Red Pioneer', 'score': '0 PIECE', 'isMe': true},
    {'rank': '1', 'name': 'World Litter Run', 'score': '898 PIECES', 'avatar': 'https://picsum.photos/100?random=1'},
    {'rank': '2', 'name': 'Joel Hibshman', 'score': '315 PIECES', 'avatar': 'https://picsum.photos/100?random=2'},
    {'rank': '3', 'name': 'JobPriem', 'score': '238 PIECES', 'avatar': 'https://picsum.photos/100?random=3'},
    {'rank': '4', 'name': 'Riemke Visser', 'score': '204 PIECES', 'avatar': 'https://picsum.photos/100?random=4'},
    {'rank': '5', 'name': 'Lekjutter', 'score': '195 PIECES', 'avatar': 'https://picsum.photos/100?random=5'},
  ];

  final List<Map<String, dynamic>> countriesData = [
    {'rank': '1', 'name': 'Canada', 'score': '898 PIECES', 'avatar': 'https://flagcdn.com/w160/ca.png'},
    {'rank': '2', 'name': 'Netherlands', 'score': '886 PIECES', 'avatar': 'https://flagcdn.com/w160/nl.png'},
    {'rank': '3', 'name': 'United States of America', 'score': '445 PIECES', 'avatar': 'https://flagcdn.com/w160/us.png'},
    {'rank': '4', 'name': 'Bulgaria', 'score': '188 PIECES', 'avatar': 'https://flagcdn.com/w160/bg.png'},
    {'rank': '5', 'name': 'Japan', 'score': '158 PIECES', 'avatar': 'https://flagcdn.com/w160/jp.png'},
    {'rank': '6', 'name': 'Spain', 'score': '158 PIECES', 'avatar': 'https://flagcdn.com/w160/es.png'},
  ];

  void _showTimeFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final options = ['Last 24 Hours', 'Last 7 Days', 'Last 15 Days', 'Last 30 Days'];
        final sp = R.sp(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: R.fs(context, 16))),
                SizedBox(height: sp),
                for (int i = 0; i < options.length; i++) ...[
                  if (i > 0) const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: R.w(context, 6), vertical: 4),
                    title: Text(options[i], style: TextStyle(fontSize: R.fs(context, 15), fontWeight: FontWeight.w600, color: Colors.black)),
                    trailing: _selectedTimeFilter == options[i]
                        ? Icon(Icons.check_circle, color: const Color(0xFF007AFF), size: R.icon(context, 24))
                        : Container(width: R.icon(context, 24), height: R.icon(context, 24), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 2))),
                    onTap: () {
                      setState(() { _selectedTimeFilter = options[i]; });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentData = _isMembersActive ? membersData : countriesData;
    final sp = R.sp(context);

    return Column(
      children: [
        ClipPath(
          clipper: HeaderCurveClipper(),
          child: Container(
            height: R.h(context, 20), width: double.infinity, color: const Color(0xFF007AFF),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: R.w(context, 4), vertical: R.h(context, 1.5)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _navigateToProfile(context),
                      child: Container(
                        width: R.icon(context, 36), height: R.icon(context, 36),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blue], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                    Text("Leaderboard", style: TextStyle(color: Colors.white, fontSize: R.fs(context, 18), fontWeight: FontWeight.bold)),
                    SizedBox(width: R.icon(context, 36)),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: R.w(context, 4)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _showTimeFilterSheet,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: R.icon(context, 22), color: Colors.black87),
                    SizedBox(width: R.w(context, 2)),
                    Text(_selectedTimeFilter, style: TextStyle(fontWeight: FontWeight.bold, fontSize: R.fs(context, 15))),
                    SizedBox(width: R.w(context, 1)),
                    Icon(Icons.keyboard_arrow_down, size: R.icon(context, 22), color: Colors.black87),
                  ],
                ),
              ),
              SizedBox(height: sp),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isMembersActive = true),
                      child: Container(
                        padding: EdgeInsets.only(bottom: R.h(context, 1.5)),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _isMembersActive ? const Color(0xFF007AFF) : Colors.transparent, width: 2))),
                        child: Center(child: Text("Members", style: TextStyle(color: _isMembersActive ? const Color(0xFF007AFF) : Colors.grey, fontWeight: FontWeight.bold, fontSize: R.fs(context, 14)))),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isMembersActive = false),
                      child: Container(
                        padding: EdgeInsets.only(bottom: R.h(context, 1.5)),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: !_isMembersActive ? const Color(0xFF007AFF) : Colors.transparent, width: 2))),
                        child: Center(child: Text("Countries", style: TextStyle(color: !_isMembersActive ? const Color(0xFF007AFF) : Colors.grey, fontWeight: FontWeight.bold, fontSize: R.fs(context, 14)))),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(bottom: R.h(context, 12)),
            itemCount: currentData.length,
            itemBuilder: (context, index) {
              return _buildLeaderboardItem(currentData[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(Map<String, dynamic> item) {
    final rank = item['rank'];
    final isMe = item['isMe'] == true;
    Color bgColor = Colors.white;
    if (rank == '1' || rank == '3') bgColor = const Color(0xFFFCF4E6);
    Color? ribbonColor;
    if (rank == '1') ribbonColor = const Color(0xFFEAB233);
    if (rank == '2') ribbonColor = const Color(0xFFA8A8A8);
    if (rank == '3') ribbonColor = const Color(0xFFC88D4D);

    return Column(
      children: [
        Container(
          color: bgColor, padding: EdgeInsets.symmetric(vertical: R.h(context, 2)),
          child: Row(
            children: [
              SizedBox(
                width: R.w(context, 13), height: R.h(context, 3.5),
                child: ribbonColor != null
                    ? ClipPath(clipper: RibbonClipper(), child: Container(color: ribbonColor, alignment: Alignment.centerLeft, padding: EdgeInsets.only(left: R.w(context, 3)), child: Text(rank, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: R.fs(context, 13)))))
                    : Center(child: Text(rank, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: R.fs(context, 13)))),
              ),
              SizedBox(width: R.w(context, 2)),
              CircleAvatar(
                radius: R.icon(context, 20), backgroundColor: Colors.blue.shade50,
                backgroundImage: item['avatar'] != null ? NetworkImage(item['avatar']) : null,
                child: item['avatar'] == null ? Container(decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Colors.cyanAccent, Colors.blue], begin: Alignment.topLeft, end: Alignment.bottomRight))) : null,
              ),
              SizedBox(width: R.w(context, 4)),
              Expanded(
                child: RichText(
                  text: TextSpan(style: TextStyle(color: Colors.black, fontSize: R.fs(context, 14), fontFamily: 'Roboto'), children: [TextSpan(text: item['name'], style: const TextStyle(fontWeight: FontWeight.bold)), if (isMe) const TextSpan(text: ' (You)', style: TextStyle(color: Colors.grey))]),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(item['score'], style: TextStyle(color: Colors.grey, fontSize: R.fs(context, 10), fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              SizedBox(width: R.w(context, 4)),
            ],
          ),
        ),
        if (isMe) const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
      ],
    );
  }
}

class RibbonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(size.width - 12, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width - 12, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// ==========================================
// ACTIVITY TAB
// ==========================================
class ActivityTab extends StatefulWidget {
  final List<String> photos;
  final bool justUploaded;

  const ActivityTab({super.key, required this.photos, this.justUploaded = false});

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  bool _isUploading = false;
  bool _isSelectionMode = false;
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    if (widget.justUploaded) {
      _isUploading = true;
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() { _isUploading = false; });
      });
    }
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) { _selectedIndices.remove(index); }
      else { _selectedIndices.add(index); }
    });
  }

  void _deleteSelected() {
    final indices = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
    setState(() {
      for (var index in indices) { DashboardScreen.globalActivityPhotos.removeAt(index); }
      _isSelectionMode = false;
      _selectedIndices.clear();
    });
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Text("Are you sure you want to delete this litter?", textAlign: TextAlign.center, style: TextStyle(fontSize: R.fs(context, 16), fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () { Navigator.pop(ctx); _deleteSelected(); },
                        style: TextButton.styleFrom(backgroundColor: const Color(0xFFFFEBEE), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                        child: Text("YES", style: TextStyle(color: const Color(0xFFD32F2F), fontWeight: FontWeight.bold, fontSize: R.fs(context, 13))),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(backgroundColor: const Color(0xFFE3F2FD), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                        child: Text("NO", style: TextStyle(color: const Color(0xFF007AFF), fontWeight: FontWeight.bold, fontSize: R.fs(context, 13))),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);

    return Column(
      children: [
        Container(
          color: const Color(0xFF007AFF),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: R.w(context, 4), vertical: R.h(context, 1.5)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _navigateToProfile(context),
                    child: Container(
                      width: R.icon(context, 36), height: R.icon(context, 36),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blue], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                  Text("Activity", style: TextStyle(color: Colors.white, fontSize: R.fs(context, 18), fontWeight: FontWeight.bold)),
                  if (_isSelectionMode)
                    TextButton(onPressed: () { setState(() { _isSelectionMode = false; _selectedIndices.clear(); }); }, child: Text("Cancel", style: TextStyle(color: Colors.white, fontSize: R.fs(context, 15))))
                  else
                    Row(
                      children: [
                        Icon(Icons.local_offer_outlined, color: Colors.white, size: R.icon(context, 26)),
                        SizedBox(width: sp),
                        GestureDetector(
                          onTap: () { if (widget.photos.isNotEmpty) setState(() { _isSelectionMode = true; }); },
                          child: Icon(Icons.delete_outline, color: Colors.white, size: R.icon(context, 26)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: R.w(context, 5), vertical: R.h(context, 1.5)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text("Show Untagged", style: TextStyle(fontWeight: FontWeight.bold, fontSize: R.fs(context, 13))),
              SizedBox(width: sp * 0.5),
              SizedBox(height: R.icon(context, 24), child: Switch(value: false, onChanged: (value) {}, activeColor: const Color(0xFF007AFF))),
            ],
          ),
        ),
        if (_isUploading)
          Container(
            margin: EdgeInsets.symmetric(horizontal: R.w(context, 5), vertical: R.h(context, 1)),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]),
            child: Row(
              children: [
                CircleAvatar(radius: R.icon(context, 20), backgroundColor: Colors.grey, backgroundImage: const AssetImage('assets/images/tut_can1.png')),
                SizedBox(width: sp),
                Text("Uploading Photo ", style: TextStyle(color: Colors.grey, fontSize: R.fs(context, 14))),
                Text("1/1", style: TextStyle(fontWeight: FontWeight.bold, fontSize: R.fs(context, 14))),
                const Spacer(),
                Text("Check it out", style: TextStyle(color: Colors.pink[400], fontWeight: FontWeight.bold, fontSize: R.fs(context, 12))),
                SizedBox(width: sp * 0.5),
              ],
            ),
          ),
        Expanded(
          child: Stack(
            children: [
              (widget.photos.isEmpty || (_isUploading && widget.photos.length <= 1)) ? _buildEmptyState(context) : _buildImageGrid(context),
              if (_isSelectionMode && widget.photos.isNotEmpty)
                Positioned(
                  bottom: 16, left: 16, right: 90,
                  child: GestureDetector(
                    onTap: _selectedIndices.isEmpty ? null : () => _showDeleteDialog(context),
                    child: Container(
                      height: 56, padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))]),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.delete_outline, color: _selectedIndices.isEmpty ? Colors.grey : const Color(0xFFD32F2F)),
                          Text("DELETE ${_selectedIndices.length} PHOTO${_selectedIndices.length != 1 ? 'S' : ''}", style: TextStyle(color: _selectedIndices.isEmpty ? Colors.grey : const Color(0xFFD32F2F), fontWeight: FontWeight.bold, fontSize: R.fs(context, 12), letterSpacing: 1.0)),
                          const SizedBox(width: 24),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: R.h(context, 25), width: R.h(context, 25),
          decoration: const BoxDecoration(color: Color(0xFFE3F2FD), shape: BoxShape.circle),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(angle: -0.2, child: Icon(Icons.note, size: R.icon(context, 110), color: const Color(0xFF007AFF))),
              Positioned(right: 30, bottom: 50, child: Transform.rotate(angle: 0.5, child: Icon(Icons.note, size: R.icon(context, 50), color: Colors.blue.withOpacity(0.2)))),
              Positioned(left: 30, top: 70, child: Transform.rotate(angle: -0.8, child: Icon(Icons.note, size: R.icon(context, 40), color: Colors.blue.withOpacity(0.2)))),
              Positioned(bottom: 40, child: Icon(Icons.waves, size: R.icon(context, 40), color: Colors.blue.withOpacity(0.4))),
            ],
          ),
        ),
        SizedBox(height: R.h(context, 4)),
        Text("No Photos", style: TextStyle(fontSize: R.fs(context, 22), fontWeight: FontWeight.bold, color: Colors.black87)),
        SizedBox(height: R.h(context, 10)),
      ],
    );
  }

  Widget _buildImageGrid(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: R.w(context, 4)),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: widget.photos.length,
      itemBuilder: (context, index) {
        final isSelected = _selectedIndices.contains(index);
        return GestureDetector(
          onTap: () { if (_isSelectionMode) _toggleSelection(index); },
          onLongPress: () { if (!_isSelectionMode) { setState(() { _isSelectionMode = true; _selectedIndices.add(index); }); } },
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(widget.photos[index], fit: BoxFit.cover)),
              if (_isSelectionMode && isSelected) Container(decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(12))),
              if (!_isSelectionMode) Positioned(bottom: 8, right: 8, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle), child: Icon(Icons.local_offer_outlined, color: Colors.white, size: R.icon(context, 16)))),
              if (_isSelectionMode && isSelected) Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Color(0xFF007AFF), shape: BoxShape.circle), child: Icon(Icons.check, color: Colors.white, size: R.icon(context, 14)))),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// IMPACT TAB
// ==========================================
class ImpactTab extends StatelessWidget {
  const ImpactTab({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipPath(
            clipper: HeaderCurveClipper(),
            child: Container(
              height: R.h(context, 45), width: double.infinity, color: const Color(0xFF007AFF),
              child: SafeArea(
                child: Padding(
                  padding: R.pagePadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => _navigateToProfile(context),
                            child: Container(
                              width: R.icon(context, 40), height: R.icon(context, 40),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blue], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                          Text("Impact", style: TextStyle(color: Colors.white, fontSize: R.fs(context, 20), fontWeight: FontWeight.bold)),
                          SizedBox(width: R.icon(context, 40)),
                        ],
                      ),
                      SizedBox(height: sp * 2.5),
                      Text("Total Global Litter Pickup", style: TextStyle(color: Colors.white70, fontSize: R.fs(context, 16))),
                      SizedBox(height: sp * 0.5),
                      Text("24,291,206", style: TextStyle(color: Colors.white, fontSize: R.fs(context, 50), fontWeight: FontWeight.w400, letterSpacing: -1.0)),
                      SizedBox(height: sp * 2),
                      Text("Overall Pickup For November, 2025", style: TextStyle(color: Colors.white70, fontSize: R.fs(context, 16))),
                      SizedBox(height: sp * 0.5),
                      Text("85,450", style: TextStyle(color: Colors.white, fontSize: R.fs(context, 50), fontWeight: FontWeight.w400, letterSpacing: -1.0)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: sp * 1.5),
          Padding(
            padding: R.pagePadding(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar(context, "APR", R.h(context, 8), false), 
                _buildBar(context, "MAY", R.h(context, 10), false), 
                _buildBar(context, "JUN", R.h(context, 5), false),
                _buildBar(context, "JUL", R.h(context, 9), false), 
                _buildBar(context, "AUG", R.h(context, 6), false), 
                _buildBar(context, "SEP", R.h(context, 7.5), false),
                _buildBar(context, "OCT", R.h(context, 5.5), false), 
                _buildBar(context, "NOV", R.h(context, 7), true),
              ],
            ),
          ),
          SizedBox(height: sp * 2.5),
          Padding(
            padding: R.pagePadding(context),
            child: SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Text("My ", style: TextStyle(fontSize: R.fs(context, 28), fontWeight: FontWeight.w300)),
                    Text("Activity ", style: TextStyle(fontSize: R.fs(context, 28), fontWeight: FontWeight.bold)),
                    Text("This Week", style: TextStyle(fontSize: R.fs(context, 28), fontWeight: FontWeight.w300)),
                    const SizedBox(width: 10),
                    Icon(Icons.info, color: Colors.blue[500], size: R.icon(context, 28)),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: sp),
          SizedBox(
            height: R.h(context, 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: R.pagePadding(context),
              children: [
                _buildDateCircle(context, "11/27"), _buildDateCircle(context, "11/28"), _buildDateCircle(context, "11/29"),
                _buildDateCircle(context, "11/30"), _buildDateCircle(context, "12/1"), _buildDateCircle(context, "12/2"),
                _buildDateCircle(context, "12/3", isActive: true),
              ],
            ),
          ),
          SizedBox(height: sp * 2.5),
          Padding(
            padding: R.pagePadding(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("Stories of\nImpact", style: TextStyle(fontSize: R.fs(context, 26), fontWeight: FontWeight.bold)),
                Text("View All", style: TextStyle(color: Colors.pink[400], fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          SizedBox(height: sp),
          SizedBox(
            height: R.h(context, 30),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: R.pagePadding(context),
              children: [
                _buildStoryCard(context, "Litter Data Helps San Francisco Win Court Case", "assets/images/cup_example.png"),
                _buildStoryCard(context, "How Lodi brought together its local businesses", "assets/images/fgfg.png"),
              ],
            ),
          ),
          SizedBox(height: R.h(context, 12)),
        ],
      ),
    );
  }

  Widget _buildBar(BuildContext context, String label, double height, bool isActive) {
    return Column(
      children: [
        Container(
          width: 8, height: height,
          decoration: BoxDecoration(color: isActive ? const Color(0xFF007AFF) : Colors.grey[200], borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(height: 12),
        Text(label, style: TextStyle(fontSize: R.fs(context, 10), color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDateCircle(BuildContext context, String date, {bool isActive = false}) {
    return Container(
      width: R.icon(context, 54), margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(color: isActive ? const Color(0xFF007AFF) : Colors.grey[400], shape: BoxShape.circle),
      child: Center(child: Text(date, style: TextStyle(color: Colors.white, fontSize: R.fs(context, 13), fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildStoryCard(BuildContext context, String title, String imagePath) {
    final sp = R.sp(context);
    return Container(
      width: R.w(context, 56), margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: Image.asset(imagePath, height: R.h(context, 14), width: double.infinity, fit: BoxFit.cover)),
          Padding(padding: EdgeInsets.all(sp), child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: R.fs(context, 13), height: 1.2), maxLines: 3, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.85);
    path.quadraticBezierTo(size.width * 0.25, size.height, size.width * 0.6, size.height * 0.85);
    path.quadraticBezierTo(size.width * 0.85, size.height * 0.75, size.width, size.height * 0.6);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}