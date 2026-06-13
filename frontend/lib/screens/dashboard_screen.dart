import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/responsive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'camera_scanner_screen.dart';
import 'camera_tutorial_screen.dart';
import 'profile_screen.dart';
import 'bin_locator_screen.dart';
import '../services/api_service.dart';
import 'classification_result_screen.dart';
import 'impact_stories_screen.dart';
import 'impact_story_detail_screen.dart';

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
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          final bool hasSeenTutorial = prefs.getBool('has_seen_camera_tutorial') ?? false;

          if (context.mounted) {
            if (hasSeenTutorial) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AiScannerScreen()),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TutorialStep1()),
              );
            }
          }
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
  bool _isLoading = true;
  String? _error;
  List<dynamic> _leaderboardData = [];

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = _isMembersActive
          ? await ApiService.instance.getMemberLeaderboard()
          : await ApiService.instance.getCountryLeaderboard();

      if (mounted) {
        setState(() {
          _leaderboardData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

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
                      onTap: () {
                        setState(() => _isMembersActive = true);
                        _fetchLeaderboard();
                      },
                      child: Container(
                        padding: EdgeInsets.only(bottom: R.h(context, 1.5)),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _isMembersActive ? const Color(0xFF007AFF) : Colors.transparent, width: 2))),
                        child: Center(child: Text("Members", style: TextStyle(color: _isMembersActive ? const Color(0xFF007AFF) : Colors.grey, fontWeight: FontWeight.bold, fontSize: R.fs(context, 14)))),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _isMembersActive = false);
                        _fetchLeaderboard();
                      },
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: sp * 2),
                          SizedBox(height: sp),
                          Text("Failed to load leaderboard", style: TextStyle(color: Colors.red, fontSize: R.fs(context, 14))),
                          TextButton(onPressed: _fetchLeaderboard, child: const Text("Retry")),
                        ],
                      ),
                    )
                  : _leaderboardData.isEmpty
                      ? Center(child: Text("No records found", style: TextStyle(color: Colors.grey, fontSize: R.fs(context, 14))))
                      : ListView.builder(
                          padding: EdgeInsets.only(bottom: R.h(context, 12)),
                          itemCount: _leaderboardData.length,
                          itemBuilder: (context, index) {
                            return _buildLeaderboardItem(_leaderboardData[index]);
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
  final List<String> photos; // Kept for interface compatibility but ignored
  final bool justUploaded;

  const ActivityTab({super.key, required this.photos, this.justUploaded = false});

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _history = [];
  bool _isSelectionMode = false;
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      setState(() { _isLoading = true; _error = null; });
      final res = await ApiService.instance.getHistory(limit: 50);
      if (mounted) {
        setState(() {
          _history = res['entries'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) { _selectedIndices.remove(index); }
      else { _selectedIndices.add(index); }
    });
  }

  Future<void> _deleteSelected() async {
    final indices = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
    
    // Show a loading overlay here ideally, but for MVP we delete sequentially and pop
    for (var index in indices) {
      final id = _history[index]['id'] ?? _history[index]['_id'];
      if (id != null) {
        try {
          await ApiService.instance.deleteHistoryEntry(id);
        } catch (e) {
          debugPrint("Failed to delete $id: $e");
        }
      }
    }
    _fetchHistory();
    setState(() {
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
                Text("Are you sure you want to delete these records?", textAlign: TextAlign.center, style: TextStyle(fontSize: R.fs(context, 16), fontWeight: FontWeight.bold)),
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
                          onTap: () { if (_history.isNotEmpty) setState(() { _isSelectionMode = true; }); },
                          child: Icon(Icons.delete_outline, color: Colors.white, size: R.icon(context, 26)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        
        Expanded(
          child: Stack(
            children: [
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 50),
                    const SizedBox(height: 10),
                    Text("Failed to load history", style: TextStyle(color: Colors.red)),
                    TextButton(onPressed: _fetchHistory, child: const Text("Retry"))
                  ],
                ))
              else if (_history.isEmpty)
                _buildEmptyState(context)
              else
                _buildHistoryList(context),

              if (_isSelectionMode && _history.isNotEmpty)
                Positioned(
                  bottom: 16, left: 16, right: 16,
                  child: GestureDetector(
                    onTap: _selectedIndices.isEmpty ? null : () => _showDeleteDialog(context),
                    child: Container(
                      height: 56, padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))]),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.delete_outline, color: _selectedIndices.isEmpty ? Colors.grey : const Color(0xFFD32F2F)),
                          Text("DELETE ${_selectedIndices.length} RECORD${_selectedIndices.length != 1 ? 'S' : ''}", style: TextStyle(color: _selectedIndices.isEmpty ? Colors.grey : const Color(0xFFD32F2F), fontWeight: FontWeight.bold, fontSize: R.fs(context, 13), letterSpacing: 1.0)),
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
            ],
          ),
        ),
        SizedBox(height: R.h(context, 4)),
        Text("No Scans Yet", style: TextStyle(fontSize: R.fs(context, 22), fontWeight: FontWeight.bold, color: Colors.black87)),
        SizedBox(height: R.h(context, 10)),
      ],
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: R.w(context, 4), vertical: 8),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        final isSelected = _selectedIndices.contains(index);
        final bool isRecyclable = item['recyclable'] == true;
        final String mode = item['mode'] ?? (() {
          final category = item['category'] ?? '';
          if (category == 'food_waste' || category == 'not_food_waste') {
            return 'food';
          } else if ((item['yolo_confidence'] as num?) != null && (item['yolo_confidence'] as num)! > 0.0) {
            return 'multiple';
          } else if (item['detections'] is List && (item['detections'] as List).isNotEmpty) {
            return 'multiple';
          }
          return 'single';
        })();
        
        return GestureDetector(
          onTap: () {
            if (_isSelectionMode) {
              _toggleSelection(index);
            } else {
              // Parse to ClassificationResult
              final resultObj = ClassificationResult.fromJson(Map<String, dynamic>.from(item));
              
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ClassificationResultScreen(
                  preloadedResult: resultObj,
                  imageUrl: item['image_url'],
                  mode: resultObj.mode,
                )
              ));
            }
          },
          onLongPress: () {
            if (!_isSelectionMode) {
              setState(() { _isSelectionMode = true; _selectedIndices.add(index); });
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? const Color(0xFF007AFF) : Colors.grey.withValues(alpha: 0.2), width: isSelected ? 2 : 1),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                // Thumbnail
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    image: item['image_url'] != null ? DecorationImage(image: NetworkImage(item['image_url']), fit: BoxFit.cover) : null,
                  ),
                  child: item['image_url'] == null ? const Icon(Icons.image, color: Colors.grey) : null,
                ),
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['object_detected'] ?? 'Unknown Object', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (mode == 'single' || mode == 'food')
                            _buildMiniConfBadge("CNN", (item['cnn_confidence'] as num?)?.toDouble() ?? (item['confidence'] as num?)?.toDouble() ?? 0.0),
                          if (mode == 'multiple')
                            _buildMiniConfBadge("YOLO", (item['yolo_confidence'] as num?)?.toDouble() ?? 0.0),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(item['timestamp']?.toString().substring(0, 10) ?? '', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                    ],
                  ),
                ),
                
                // Recyclable Badge
                Column(
                  children: [
                    Icon(
                      isRecyclable ? Icons.recycling : Icons.delete_outline,
                      color: isRecyclable ? Colors.green : Colors.orange,
                    ),
                    if (_isSelectionMode && isSelected) ...[
                      const SizedBox(height: 8),
                      Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Color(0xFF007AFF), shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.white, size: 14)),
                    ]
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniConfBadge(String label, double confidence) {
    final color = confidence >= 0.8 ? const Color(0xFF4CAF50) : 
                  confidence >= 0.6 ? Colors.orange : Colors.red;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$label: ",
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
          ),
          Text(
            "${(confidence * 100).toStringAsFixed(0)}%",
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// IMPACT TAB
// ==========================================
class ImpactTab extends StatefulWidget {
  const ImpactTab({super.key});

  @override
  State<ImpactTab> createState() => _ImpactTabState();
}

class _ImpactTabState extends State<ImpactTab> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _myStats;
  Map<String, dynamic>? _globalStats;
  List<dynamic> _stories = [];

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      setState(() { _isLoading = true; _error = null; });
      final personal = await ApiService.instance.getMyAnalytics();
      final global = await ApiService.instance.getGlobalAnalytics();
      final stories = await ApiService.instance.getImpactStories();
      
      if (mounted) {
        setState(() {
          _myStats = personal;
          _globalStats = global;
          _stories = stories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text("Failed to load impact data", style: TextStyle(color: Colors.red)),
            TextButton(onPressed: _fetchStats, child: const Text("Retry")),
          ],
        ),
      );
    }

    final sp = R.sp(context);
    final globalTotal = _globalStats?['total_global_scans']?.toString() ?? "0";
    final monthlyTotal = _globalStats?['monthly_scans']?.toString() ?? "0";
    
    // Formatter for large numbers (adding commas)
    String formatNum(String s) {
      if (s.length <= 3) return s;
      return s.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipPath(
            clipper: HeaderCurveClipper(),
            child: Container(
              height: R.h(context, 48), width: double.infinity, color: const Color(0xFF007AFF),
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
                      SizedBox(height: sp * 1.5),
                      Text("Total Global Litter Pickup", style: TextStyle(color: Colors.white70, fontSize: R.fs(context, 14))),
                      SizedBox(height: sp * 0.25),
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(formatNum(globalTotal), style: TextStyle(color: Colors.white, fontSize: R.fs(context, 44), fontWeight: FontWeight.w400, letterSpacing: -1.0)),
                        ),
                      ),
                      SizedBox(height: sp * 1.25),
                      Text("Overall Pickup This Month", style: TextStyle(color: Colors.white70, fontSize: R.fs(context, 14))),
                      SizedBox(height: sp * 0.25),
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(formatNum(monthlyTotal), style: TextStyle(color: Colors.white, fontSize: R.fs(context, 44), fontWeight: FontWeight.w400, letterSpacing: -1.0)),
                        ),
                      ),
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
              children: (() {
                final history = _myStats?['monthly_history'] as List? ?? [];
                // Default months if history is empty or short
                final defaultMonths = ["APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV"];
                final List<Widget> bars = [];
                
                for (int i = 0; i < defaultMonths.length; i++) {
                  final monthName = defaultMonths[i];
                  // Find if we have real data for this month
                  final record = history.firstWhere((h) => h['month'] == monthName, orElse: () => null);
                  final count = record != null ? (record['count'] as num).toDouble() : 0.0;
                  
                  // Scale height: min 10, max 80. Base it on count.
                  double h = 10 + (count * 2.0);
                  if (h > 80) h = 80;

                  bars.add(_buildBar(context, monthName, R.h(context, h / 10), i == defaultMonths.length - 1));
                }
                return bars;
              })(),
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
                _buildDateCircle(context, "T"), 
                _buildDateCircle(context, "W"), 
                _buildDateCircle(context, "T"),
                _buildDateCircle(context, "F"), 
                _buildDateCircle(context, "S"), 
                _buildDateCircle(context, "S"),
                _buildDateCircle(context, "M", isActive: true),
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
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ImpactStoriesScreen()),
                    );
                  },
                  child: Text("View All", style: TextStyle(color: Colors.pink[400], fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          SizedBox(height: sp),
          SizedBox(
            height: R.h(context, 30),
            child: _stories.isEmpty
                ? Center(
                    child: Text(
                      "No stories available",
                      style: TextStyle(color: Colors.grey, fontSize: R.fs(context, 13)),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: R.pagePadding(context),
                    itemCount: _stories.length,
                    itemBuilder: (context, index) {
                      final item = _stories[index];
                      return _buildStoryCard(
                        context,
                        item,
                      );
                    },
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

  Widget _buildStoryCard(BuildContext context, Map<String, dynamic> item) {
    final title = item['title'] ?? '';
    final imageUrl = item['image_url'] ?? '';
    final sp = R.sp(context);
    return Container(
      width: R.w(context, 56), margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImpactStoryDetailScreen(story: item),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: imageUrl.startsWith('http')
                  ? Image.network(imageUrl, height: R.h(context, 14), width: double.infinity, fit: BoxFit.cover)
                  : Image.asset(imageUrl, height: R.h(context, 14), width: double.infinity, fit: BoxFit.cover),
            ),
            Padding(padding: EdgeInsets.all(sp), child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: R.fs(context, 13), height: 1.2), maxLines: 3, overflow: TextOverflow.ellipsis)),
          ],
        ),
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