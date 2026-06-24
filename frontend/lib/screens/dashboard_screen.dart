import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/responsive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'camera_scanner_screen.dart';
import 'camera_tutorial_screen.dart';
import 'profile_screen.dart';
import 'bin_locator_screen.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';
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
    return ValueListenableBuilder<String>(
      valueListenable: TranslationService.instance.languageNotifier,
      builder: (context, lang, child) {
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.bubble_chart_outlined),
                label: TranslationService.translate('tab_activity'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.map_outlined),
                label: TranslationService.translate('tab_map'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.language),
                label: TranslationService.translate('tab_impact'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.emoji_events_outlined),
                label: TranslationService.translate('tab_leaderboard'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.assignment_outlined),
                label: TranslationService.translate('tab_tasks'),
              ),
            ],
          ),
        );
      },
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
// ==========================================
// TASKS TAB
// ==========================================
class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _tasksEnabled = false;
  String? _error;
  List<dynamic> _tasks = [];
  late TabController _tabController;
  String _userInitials = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserInitials();
    _fetchTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInitials() async {
    try {
      final name = await ApiService.instance.getUsername();
      if (name != null && name.isNotEmpty) {
        if (mounted) {
          setState(() {
            _userInitials = _getInitials(name);
          });
        }
      } else {
        final profile = await ApiService.instance.getMe();
        final fetchedName = profile['name'] ?? '';
        if (fetchedName.isNotEmpty) {
          if (mounted) {
            setState(() {
              _userInitials = _getInitials(fetchedName);
            });
          }
        }
      }
    } catch (_) {}
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'US';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final second = parts[1].isNotEmpty ? parts[1][0] : '';
      return (first + second).toUpperCase();
    } else if (name.length >= 2) {
      return name.substring(0, 2).toUpperCase();
    } else {
      return name.toUpperCase();
    }
  }

  Future<void> _fetchTasks() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }
      final res = await ApiService.instance.getTasks();
      if (mounted) {
        setState(() {
          _tasksEnabled = res['tasks_enabled'] ?? false;
          _tasks = res['data'] ?? [];
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

  Future<void> _enableTasks() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }
      await ApiService.instance.enableTasks();
      await _fetchTasks();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _enrollTask(String taskId) async {
    try {
      // Optimistic UI update
      setState(() {
        final idx = _tasks.indexWhere((t) => t['id'] == taskId);
        if (idx != -1) {
          _tasks[idx]['enrolled'] = true;
          _tasks[idx]['enrollment_status'] = 'in_progress';
          _tasks[idx]['progress'] = 0;
        }
      });

      await ApiService.instance.enrollTask(taskId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationService.translate('task_enrolled_success')),
          backgroundColor: const Color(0xFF2196F3),
        ),
      );

      _fetchTasks(); // Refresh to get precise state
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
        ),
      );
      _fetchTasks(); // Revert state on error
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter tasks
    final activeTasks = _tasks.where((t) => t['is_active'] == true).toList();
    final myTasks = _tasks.where((t) => t['enrolled'] == true).toList();
    final showTabBar = _tasksEnabled && !_isLoading && _error == null;

    return Column(
      children: [
        // Premium App Bar
        Container(
          color: const Color(0xFF007AFF),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
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
                          child: Center(
                            child: Text(
                              _userInitials.isNotEmpty ? _userInitials : 'US',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: R.fs(context, 11),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Text(
                        TranslationService.translate('tab_tasks'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: R.fs(context, 20),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: R.icon(context, 36)),
                    ],
                  ),
                ),
                // Tab Bar (only shown if tasks are enabled)
                if (showTabBar)
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3.0,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    tabs: [
                      Tab(text: TranslationService.translate('task_active')),
                      Tab(text: TranslationService.translate('task_mine')),
                    ],
                  ),
              ],
            ),
          ),
        ),

        // Tasks List content or Onboarding Gate
        Expanded(
          child: Container(
            color: isDark ? const Color(0xFF121212) : const Color(0xFFF5F8FF), // Dark theme support
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF))))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                            const SizedBox(height: 12),
                            Text(_error!, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: R.fs(context, 14))),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _fetchTasks,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : !_tasksEnabled
                        ? _buildOnboardingGate(context, sp)
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildTaskList(activeTasks, isMineTab: false),
                              _buildTaskList(myTasks, isMineTab: true),
                            ],
                          ),
          ),
        ),
      ],
    );
  }

  Widget _buildOnboardingGate(BuildContext context, double sp) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
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
              decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[100]),
              child: Center(
                child: Text(
                  "tasks_illustration.png goes here",
                  style: TextStyle(color: Colors.grey, fontSize: R.fs(context, 14)),
                ),
              ),
            ),
          ),
          SizedBox(height: sp * 3),
          Padding(
            padding: R.pagePadding(context),
            child: Column(
              children: [
                Text(
                  TranslationService.translate('litter_data_desc'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: R.fs(context, 15),
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                SizedBox(height: sp),
                Text(
                  TranslationService.translate('apply_researcher'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: R.fs(context, 18),
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF007AFF),
                    letterSpacing: 0.5,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: sp * 2.5),
                Container(
                  width: double.infinity,
                  height: R.h(context, 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _enableTasks,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      TranslationService.translate('apply_now'),
                      style: TextStyle(
                        fontSize: R.fs(context, 13),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: R.h(context, 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<dynamic> tasksList, {required bool isMineTab}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (tasksList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isMineTab ? '🎯' : '🌿',
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 12),
              Text(
                TranslationService.translate(isMineTab ? 'task_mine_empty' : 'task_empty'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: R.fs(context, 15),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchTasks,
      child: ListView.builder(
        padding: R.pagePadding(context).copyWith(top: 16, bottom: 24),
        itemCount: tasksList.length,
        itemBuilder: (context, index) {
          final task = tasksList[index];
          return _buildTaskCard(task);
        },
      ),
    );
  }

  Widget _buildTaskCard(dynamic task) {
    final bool showUrdu = TranslationService.isUrdu;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String titleStr = (showUrdu && task['title_ur'] != null && task['title_ur'].toString().isNotEmpty)
        ? task['title_ur']
        : (task['title'] ?? '');
    final String descStr = (showUrdu && task['description_ur'] != null && task['description_ur'].toString().isNotEmpty)
        ? task['description_ur']
        : (task['description'] ?? '');

    final String difficulty = task['difficulty'] ?? 'medium';
    final int rewardPoints = task['reward_points'] ?? 100;
    final String badge = task['badge_icon'] ?? '🌿';
    final bool enrolled = task['enrolled'] ?? false;
    final String status = task['enrollment_status'] ?? 'not_enrolled';
    final int progress = task['progress'] ?? 0;
    final int target = task['target_count'] ?? 10;

    // Difficulty Color
    Color diffColor = Colors.grey;
    if (difficulty == 'easy') diffColor = Colors.green;
    if (difficulty == 'medium') diffColor = Colors.orange;
    if (difficulty == 'hard') diffColor = Colors.red;

    // Calculate deadline days remaining
    int? daysLeft;
    if (task['deadline'] != null) {
      try {
        final deadlineDate = DateTime.parse(task['deadline']);
        daysLeft = deadlineDate.difference(DateTime.now()).inDays;
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(
          color: enrolled ? const Color(0xFF007AFF).withOpacity(0.2) : (isDark ? Colors.white12 : Colors.black12),
          width: enrolled ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Emoji Badge & Title & Difficulty
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFF0F5FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      badge,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleStr,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: R.fs(context, 16),
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Points Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2C2518) : const Color(0xFFFFF4DF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, size: 12, color: Colors.orange),
                                const SizedBox(width: 4),
                                Text(
                                  '+$rewardPoints ${TranslationService.translate('task_points')}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Difficulty Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: diffColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              difficulty.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: diffColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            if (descStr.isNotEmpty)
              Text(
                descStr,
                style: TextStyle(
                  fontSize: R.fs(context, 13),
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.4,
                ),
              ),
            const SizedBox(height: 12),

            // Deadline & Status row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Deadline
                if (daysLeft != null && daysLeft >= 0)
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: isDark ? Colors.white60 : Colors.black45),
                      const SizedBox(width: 4),
                      Text(
                        '$daysLeft ${TranslationService.translate('task_days_left')}',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
                      ),
                    ],
                  )
                else if (daysLeft != null && daysLeft < 0)
                  Row(
                    children: [
                      const Icon(Icons.error_outline, size: 14, color: Colors.redAccent),
                      const SizedBox(width: 4),
                      Text(
                        TranslationService.translate('task_expired'),
                        style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                else
                  const SizedBox.shrink(),

                // Action / Status Indicator
                _buildActionWidget(task, status, enrolled, isDark),
              ],
            ),

            // Progress bar if enrolled
            if (enrolled && status == 'in_progress') ...[
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${TranslationService.translate('task_in_progress').toUpperCase()}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF007AFF),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '$progress / $target',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: target > 0 ? progress / target : 0,
                      backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionWidget(dynamic task, String status, bool enrolled, bool isDark) {
    if (!enrolled) {
      return TextButton(
        onPressed: () => _enrollTask(task['id']),
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFF007AFF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          TranslationService.translate('task_apply_now'),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (status == 'completed') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 14, color: Colors.green),
            const SizedBox(width: 4),
            Text(
              TranslationService.translate('task_completed'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'expired') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey[200],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          TranslationService.translate('task_expired'),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white54 : Colors.grey,
          ),
        ),
      );
    }

    // In Progress badge
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        TranslationService.translate('task_in_progress'),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF007AFF),
        ),
      ),
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
  String _userInitials = '';

  @override
  void initState() {
    super.initState();
    _loadUserInitials();
    _fetchLeaderboard();
  }

  Future<void> _loadUserInitials() async {
    try {
      final name = await ApiService.instance.getUsername();
      if (name != null && name.isNotEmpty) {
        if (mounted) {
          setState(() {
            _userInitials = _getInitials(name);
          });
        }
      } else {
        final profile = await ApiService.instance.getMe();
        final fetchedName = profile['name'] ?? '';
        if (fetchedName.isNotEmpty) {
          if (mounted) {
            setState(() {
              _userInitials = _getInitials(fetchedName);
            });
          }
        }
      }
    } catch (_) {}
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'US';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final second = parts[1].isNotEmpty ? parts[1][0] : '';
      return (first + second).toUpperCase();
    } else if (name.length >= 2) {
      return name.substring(0, 2).toUpperCase();
    } else {
      return name.toUpperCase();
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                Text('Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: R.fs(context, 16), color: isDark ? Colors.white : Colors.black)),
                SizedBox(height: sp),
                for (int i = 0; i < options.length; i++) ...[
                  if (i > 0) Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : const Color(0xFFEEEEEE)),
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: R.w(context, 6), vertical: 4),
                    title: Text(options[i], style: TextStyle(fontSize: R.fs(context, 15), fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black)),
                    trailing: _selectedTimeFilter == options[i]
                        ? Icon(Icons.check_circle, color: const Color(0xFF007AFF), size: R.icon(context, 24))
                        : Container(width: R.icon(context, 24), height: R.icon(context, 24), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300, width: 2))),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                        child: Center(
                          child: Text(
                            _userInitials.isNotEmpty ? _userInitials : 'US',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: R.fs(context, 11),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(TranslationService.translate('tab_leaderboard'), style: TextStyle(color: Colors.white, fontSize: R.fs(context, 18), fontWeight: FontWeight.bold)),
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
                    Icon(Icons.access_time, size: R.icon(context, 22), color: isDark ? Colors.white70 : Colors.black87),
                    SizedBox(width: R.w(context, 2)),
                    Text(
                      _selectedTimeFilter == 'Last 24 Hours' ? (TranslationService.isUrdu ? 'پچھلے 24 گھنٹے' : 'Last 24 Hours') :
                      _selectedTimeFilter == 'Last 7 Days' ? (TranslationService.isUrdu ? 'پچھلے 7 دن' : 'Last 7 Days') :
                      _selectedTimeFilter == 'Last 15 Days' ? (TranslationService.isUrdu ? 'پچھلے 15 دن' : 'Last 15 Days') :
                      _selectedTimeFilter == 'Last 30 Days' ? (TranslationService.isUrdu ? 'پچھلے 30 دن' : 'Last 30 Days') : _selectedTimeFilter,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: R.fs(context, 15), color: isDark ? Colors.white : Colors.black87),
                    ),
                    SizedBox(width: R.w(context, 1)),
                    Icon(Icons.keyboard_arrow_down, size: R.icon(context, 22), color: isDark ? Colors.white70 : Colors.black87),
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
                        child: Center(child: Text(TranslationService.translate('leaderboard_members'), style: TextStyle(color: _isMembersActive ? const Color(0xFF007AFF) : (isDark ? Colors.white54 : Colors.grey), fontWeight: FontWeight.bold, fontSize: R.fs(context, 14)))),
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
                        child: Center(child: Text(TranslationService.translate('leaderboard_countries'), style: TextStyle(color: !_isMembersActive ? const Color(0xFF007AFF) : (isDark ? Colors.white54 : Colors.grey), fontWeight: FontWeight.bold, fontSize: R.fs(context, 14)))),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : const Color(0xFFEEEEEE)),
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
                          Text(TranslationService.translate('leaderboard_fail'), style: TextStyle(color: Colors.red, fontSize: R.fs(context, 14))),
                          TextButton(onPressed: _fetchLeaderboard, child: Text(TranslationService.translate('retry'))),
                        ],
                      ),
                    )
                  : _leaderboardData.isEmpty
                      ? Center(child: Text(TranslationService.translate('no_records'), style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: R.fs(context, 14))))
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    if (rank == '1' || rank == '3') bgColor = isDark ? const Color(0xFF231F16) : const Color(0xFFFCF4E6);
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
                    : Center(child: Text(rank, style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontWeight: FontWeight.bold, fontSize: R.fs(context, 13)))),
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
                  text: TextSpan(style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: R.fs(context, 14), fontFamily: 'Roboto'), children: [TextSpan(text: item['name'], style: const TextStyle(fontWeight: FontWeight.bold)), if (isMe) TextSpan(text: ' (You)', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey))]),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(item['score'], style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: R.fs(context, 10), fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              SizedBox(width: R.w(context, 4)),
            ],
          ),
        ),
        if (isMe) Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : const Color(0xFFEEEEEE)),
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
  String _userInitials = '';

  @override
  void initState() {
    super.initState();
    _loadUserInitials();
    _fetchHistory();
  }

  Future<void> _loadUserInitials() async {
    try {
      final name = await ApiService.instance.getUsername();
      if (name != null && name.isNotEmpty) {
        if (mounted) {
          setState(() {
            _userInitials = _getInitials(name);
          });
        }
      } else {
        final profile = await ApiService.instance.getMe();
        final fetchedName = profile['name'] ?? '';
        if (fetchedName.isNotEmpty) {
          if (mounted) {
            setState(() {
              _userInitials = _getInitials(fetchedName);
            });
          }
        }
      }
    } catch (_) {}
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'US';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final second = parts[1].isNotEmpty ? parts[1][0] : '';
      return (first + second).toUpperCase();
    } else if (name.length >= 2) {
      return name.substring(0, 2).toUpperCase();
    } else {
      return name.toUpperCase();
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Text(TranslationService.translate('delete_confirm_desc'), textAlign: TextAlign.center, style: TextStyle(fontSize: R.fs(context, 16), fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () { Navigator.pop(ctx); _deleteSelected(); },
                        style: TextButton.styleFrom(backgroundColor: isDark ? const Color(0xFF5C1919) : const Color(0xFFFFEBEE), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                        child: Text(TranslationService.translate('yes'), style: TextStyle(color: isDark ? Colors.white : const Color(0xFFD32F2F), fontWeight: FontWeight.bold, fontSize: R.fs(context, 13))),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(backgroundColor: isDark ? Colors.white10 : const Color(0xFFE3F2FD), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                        child: Text(TranslationService.translate('no'), style: TextStyle(color: const Color(0xFF007AFF), fontWeight: FontWeight.bold, fontSize: R.fs(context, 13))),
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
                      child: Center(
                        child: Text(
                          _userInitials.isNotEmpty ? _userInitials : 'US',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: R.fs(context, 11),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(TranslationService.translate('tab_activity'), style: TextStyle(color: Colors.white, fontSize: R.fs(context, 18), fontWeight: FontWeight.bold)),
                  if (_isSelectionMode)
                    TextButton(onPressed: () { setState(() { _isSelectionMode = false; _selectedIndices.clear(); }); }, child: Text(TranslationService.translate('cancel'), style: TextStyle(color: Colors.white, fontSize: R.fs(context, 15))))
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
                    Text(TranslationService.translate('history_fail'), style: TextStyle(color: Colors.red)),
                    TextButton(onPressed: _fetchHistory, child: Text(TranslationService.translate('retry')))
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
                      decoration: BoxDecoration(color: isDark ? const Color(0xFF5C1919) : const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))]),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.delete_outline, color: _selectedIndices.isEmpty ? Colors.grey : (isDark ? Colors.white : const Color(0xFFD32F2F))),
                          Text(
                            TranslationService.isUrdu
                                ? "${_selectedIndices.length} ریکارڈز حذف کریں"
                                : "DELETE ${_selectedIndices.length} RECORD${_selectedIndices.length != 1 ? 'S' : ''}",
                            style: TextStyle(color: _selectedIndices.isEmpty ? Colors.grey : (isDark ? Colors.white : const Color(0xFFD32F2F)), fontWeight: FontWeight.bold, fontSize: R.fs(context, 13), letterSpacing: 1.0),
                          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: R.h(context, 25), width: R.h(context, 25),
          decoration: BoxDecoration(color: isDark ? Colors.white10 : const Color(0xFFE3F2FD), shape: BoxShape.circle),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(angle: -0.2, child: Icon(Icons.note, size: R.icon(context, 110), color: const Color(0xFF007AFF))),
            ],
          ),
        ),
        SizedBox(height: R.h(context, 4)),
        Text(TranslationService.translate('no_scans'), style: TextStyle(fontSize: R.fs(context, 22), fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        SizedBox(height: R.h(context, 10)),
      ],
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              color: isSelected ? Colors.blue.withValues(alpha: 0.1) : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? const Color(0xFF007AFF) : (isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.2)), width: isSelected ? 2 : 1),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                // Thumbnail
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey[200],
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
                      Text(item['object_detected'] ?? 'Unknown Object', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
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
                      Text(item['timestamp']?.toString().substring(0, 10) ?? '', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[400], fontSize: 11)),
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
  String _userInitials = '';

  @override
  void initState() {
    super.initState();
    _loadUserInitials();
    _fetchStats();
  }

  Future<void> _loadUserInitials() async {
    try {
      final name = await ApiService.instance.getUsername();
      if (name != null && name.isNotEmpty) {
        if (mounted) {
          setState(() {
            _userInitials = _getInitials(name);
          });
        }
      } else {
        final profile = await ApiService.instance.getMe();
        final fetchedName = profile['name'] ?? '';
        if (fetchedName.isNotEmpty) {
          if (mounted) {
            setState(() {
              _userInitials = _getInitials(fetchedName);
            });
          }
        }
      }
    } catch (_) {}
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'US';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final second = parts[1].isNotEmpty ? parts[1][0] : '';
      return (first + second).toUpperCase();
    } else if (name.length >= 2) {
      return name.substring(0, 2).toUpperCase();
    } else {
      return name.toUpperCase();
    }
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
                              child: Center(
                                child: Text(
                                  _userInitials.isNotEmpty ? _userInitials : 'US',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: R.fs(context, 12),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Text(TranslationService.translate('tab_impact'), style: TextStyle(color: Colors.white, fontSize: R.fs(context, 20), fontWeight: FontWeight.bold)),
                          SizedBox(width: R.icon(context, 40)),
                        ],
                      ),
                      SizedBox(height: sp * 1.5),
                      Text(TranslationService.translate('total_global_litter'), style: TextStyle(color: Colors.white70, fontSize: R.fs(context, 14))),
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
                      Text(TranslationService.translate('pickup_this_month'), style: TextStyle(color: Colors.white70, fontSize: R.fs(context, 14))),
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
                    Text(
                      TranslationService.translate('my_activity_week'),
                      style: TextStyle(fontSize: R.fs(context, 26), fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                    ),
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
                Text(TranslationService.translate('stories_impact'), style: TextStyle(fontSize: R.fs(context, 26), fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ImpactStoriesScreen()),
                    );
                  },
                  child: Text(TranslationService.translate('view_all'), style: TextStyle(color: Colors.pink[400], fontWeight: FontWeight.bold)),
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
                      TranslationService.translate('no_stories'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          width: 8, height: height,
          decoration: BoxDecoration(color: isActive ? const Color(0xFF007AFF) : (isDark ? Colors.white12 : Colors.grey[200]), borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(height: 12),
        Text(label, style: TextStyle(fontSize: R.fs(context, 10), color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDateCircle(BuildContext context, String date, {bool isActive = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: R.icon(context, 54), margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(color: isActive ? const Color(0xFF007AFF) : (isDark ? Colors.white24 : Colors.grey[400]), shape: BoxShape.circle),
      child: Center(child: Text(date, style: TextStyle(color: Colors.white, fontSize: R.fs(context, 13), fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildStoryCard(BuildContext context, Map<String, dynamic> item) {
    final title = item['title'] ?? '';
    final imageUrl = item['image_url'] ?? '';
    final sp = R.sp(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: R.w(context, 56), margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(16),
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
            Padding(padding: EdgeInsets.all(sp), child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: R.fs(context, 13), height: 1.2, color: isDark ? Colors.white : Colors.black87), maxLines: 3, overflow: TextOverflow.ellipsis)),
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