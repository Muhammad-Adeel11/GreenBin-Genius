import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/responsive.dart';
import '../services/translation_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.instance.getNotifications();
      setState(() {
        _notifications = (data['data'] as List<dynamic>?) ?? [];
        _unreadCount   = (data['unread'] as int?) ?? 0;
      });
    } catch (_) {
      // silently fail – show empty state
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markRead(String id, int index) async {
    try {
      await ApiService.instance.markNotificationRead(id);
      setState(() {
        _notifications[index]['is_read'] = true;
        if (_unreadCount > 0) _unreadCount--;
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await ApiService.instance.markAllNotificationsRead();
      setState(() {
        for (final n in _notifications) n['is_read'] = true;
        _unreadCount = 0;
      });
    } catch (_) {}
  }

  // ── Icon & colour helpers ─────────────────────────────────
  static const Map<String, String> _typeEmoji = {
    'scan':     '🔍',
    'points':   '🏆',
    'campaign': '📢',
    'system':   '⚙️',
  };

  List<Color> _typeGradient(String type, bool isDark) {
    switch (type) {
      case 'scan':
        return isDark
            ? [const Color(0xFF1E88E5), const Color(0xFF64B5F6)]
            : [const Color(0xFF1565C0), const Color(0xFF1E88E5)];
      case 'points':
        return isDark
            ? [const Color(0xFFF9A825), const Color(0xFFFFD54F)]
            : [const Color(0xFFE65100), const Color(0xFFF57C00)];
      case 'campaign':
        return isDark
            ? [const Color(0xFF2E7D32), const Color(0xFF81C784)]
            : [const Color(0xFF1B5E20), const Color(0xFF2E7D32)];
      default:
        return isDark
            ? [const Color(0xFF424242), const Color(0xFF757575)]
            : [const Color(0xFF616161), const Color(0xFF9E9E9E)];
    }
  }

  Color _typeColor(String type, bool isDark) {
    switch (type) {
      case 'scan':     return isDark ? const Color(0xFF64B5F6) : const Color(0xFF1E88E5);
      case 'points':   return isDark ? const Color(0xFFFFD54F) : const Color(0xFFF9A825);
      case 'campaign': return isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
      default:         return isDark ? Colors.grey[400]! : Colors.grey[600]!;
    }
  }

  String _relativeTime(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt  = DateTime.parse(raw.toString()).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inSeconds < 60)  return 'Just now';
      if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
      if (diff.inHours < 24)    return '${diff.inHours}h ago';
      if (diff.inDays < 7)      return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? const Color(0xFF121212) : const Color(0xFFF8FAF9);
    final accentGrad = const [Color(0xFF2E7D32), Color(0xFF1B5E20)];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: accentGrad,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Text(
              TranslationService.translate('notifications'),
              style: TextStyle(fontSize: R.fs(context, 18), fontWeight: FontWeight.bold),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
        actions: [
          // Language toggle
          TextButton(
            onPressed: () async {
              await TranslationService.instance.toggleLanguage();
              setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                TranslationService.isUrdu ? 'EN' : 'اردو',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          // Mark all read
          if (_unreadCount > 0)
            IconButton(
              tooltip: 'Mark all as read',
              icon: const Icon(Icons.done_all_rounded, color: Colors.white),
              onPressed: _markAllRead,
            ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF2E7D32),
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
            : _notifications.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _buildNotifCard(context, i, isDark),
                  ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2E7D32).withOpacity(0.2), const Color(0xFF1B5E20).withOpacity(0.2)]
                    : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: Text('🔔', style: TextStyle(fontSize: 44)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            TranslationService.translate('no_notifications'),
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              TranslationService.translate('notifications_subtitle'),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifCard(BuildContext context, int index, bool isDark) {
    final n        = _notifications[index];
    final id       = n['id'] as String? ?? '';
    final type     = (n['type'] as String?) ?? 'system';
    final isRead   = (n['is_read'] as bool?) ?? true;
    final emoji    = _typeEmoji[type] ?? '🔔';
    final typeClr  = _typeColor(type, isDark);
    final gradColors = _typeGradient(type, isDark);
    final title    = TranslationService.isUrdu ? (n['title_ur'] ?? n['title_en'] ?? '') : (n['title_en'] ?? '');
    final message  = TranslationService.isUrdu ? (n['message_ur'] ?? n['message_en'] ?? '') : (n['message_en'] ?? '');
    final timeAgo  = _relativeTime(n['created_at']);

    return GestureDetector(
      onTap: () {
        if (!isRead && id.isNotEmpty) _markRead(id, index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark
              ? (isRead ? const Color(0xFF1E1E1E) : const Color(0xFF1A261C))
              : (isRead ? Colors.white : const Color(0xFFF1F8F3)),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Unread border stripe indicator
              if (!isRead)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradColors,
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isRead) const SizedBox(width: 5),
                    // Gradient Emoji avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [gradColors[0].withOpacity(0.18), gradColors[1].withOpacity(0.18)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: gradColors[0].withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  textDirection: TranslationService.isUrdu ? TextDirection.rtl : TextDirection.ltr,
                                  style: TextStyle(
                                    fontSize: R.fs(context, 14.5),
                                    fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(left: 8, top: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.redAccent.withOpacity(0.5),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            message,
                            textDirection: TranslationService.isUrdu ? TextDirection.rtl : TextDirection.ltr,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: R.fs(context, 13),
                              color: isDark ? Colors.white60 : Colors.grey[700],
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [gradColors[0].withOpacity(0.12), gradColors[1].withOpacity(0.12)],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  type.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: gradColors[0],
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                timeAgo,
                                style: TextStyle(
                                  fontSize: R.fs(context, 11),
                                  color: isDark ? Colors.white38 : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
