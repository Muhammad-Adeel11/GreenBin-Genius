import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/responsive.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  bool _showUrdu = false;

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
    final bg     = isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA);
    const accent = Color(0xFF2196F3);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Text(
              _showUrdu ? 'اطلاعات' : 'Notifications',
              style: TextStyle(fontSize: R.fs(context, 18), fontWeight: FontWeight.bold),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
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
            onPressed: () => setState(() => _showUrdu = !_showUrdu),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _showUrdu ? 'EN' : 'اردو',
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
        color: accent,
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF2196F3)))
            : _notifications.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
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
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🔔', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _showUrdu ? 'کوئی اطلاع نہیں' : 'No Notifications Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _showUrdu
                ? 'جب آپ اسکین کریں گے تو یہاں اطلاعات ظاہر ہوں گی۔'
                : 'Your scan results & updates will appear here.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
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
    final title    = _showUrdu ? (n['title_ur'] ?? n['title_en'] ?? '') : (n['title_en'] ?? '');
    final message  = _showUrdu ? (n['message_ur'] ?? n['message_en'] ?? '') : (n['message_en'] ?? '');
    final timeAgo  = _relativeTime(n['created_at']);

    return GestureDetector(
      onTap: () {
        if (!isRead && id.isNotEmpty) _markRead(id, index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isDark
              ? (isRead ? const Color(0xFF1E1E1E) : const Color(0xFF1A2535))
              : (isRead ? Colors.white : const Color(0xFFE8F4FD)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isRead
                ? Colors.transparent
                : typeClr.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: typeClr.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            textDirection: _showUrdu ? TextDirection.rtl : TextDirection.ltr,
                            style: TextStyle(
                              fontSize: R.fs(context, 14),
                              fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: BoxDecoration(
                              color: typeClr,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      message,
                      textDirection: _showUrdu ? TextDirection.rtl : TextDirection.ltr,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: R.fs(context, 12.5),
                        color: isDark ? Colors.white60 : Colors.grey[700],
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: typeClr.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            type.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: typeClr,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
      ),
    );
  }
}
