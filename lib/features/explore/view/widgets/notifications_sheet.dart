import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:speakwise_mobile/app/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// Notifications Bottom Sheet
/// Interactive notifications stream for events, CFP, and speaker updates
/// ═══════════════════════════════════════════════════════════════
class NotificationsSheet extends StatefulWidget {
  const NotificationsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const NotificationsSheet(),
    );
  }

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationItem {
  final String id;
  final String title;
  final String body;
  final String timeAgo;
  final IconData icon;
  final Color iconColor;
  final String type;
  final String? route;
  bool isRead;

  _NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.icon,
    required this.iconColor,
    required this.type,
    this.route,
    this.isRead = false,
  });
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  String _selectedFilter = 'all';

  late List<_NotificationItem> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = [
      _NotificationItem(
        id: 'notif-1',
        title: 'CFP Open • PyCon Ghana 2027',
        body: 'Call for Proposals is now open! Submit your talk on AI, Cloud, or Distributed Systems before slots fill up.',
        timeAgo: '15m ago',
        icon: Icons.mic_external_on_rounded,
        iconColor: AppTheme.primaryAccent,
        type: 'cfp',
        route: '/event/pycon-gh-2027',
        isRead: false,
      ),
      _NotificationItem(
        id: 'notif-2',
        title: 'New Feedback Ratings Collected',
        body: 'Attendees scanned your QR code and submitted 142 ratings for your recent presentation at DevFest Accra.',
        timeAgo: '2h ago',
        icon: Icons.qr_code_2_rounded,
        iconColor: const Color(0xFF00E5FF),
        type: 'talks',
        route: '/shell?tab=1',
        isRead: false,
      ),
      _NotificationItem(
        id: 'notif-3',
        title: 'Featured Speaker Spotlight',
        body: 'Juliana Lawson and Ezra Yendau were announced as Keynote Speakers for PyCon Namibia 2027.',
        timeAgo: '1d ago',
        icon: Icons.person_add_rounded,
        iconColor: const Color(0xFFFFD600),
        type: 'speakers',
        isRead: true,
      ),
      _NotificationItem(
        id: 'notif-4',
        title: 'Cortex Dev Summit 2026',
        body: 'Registration is live! Early access to technical deep dives and Flutter masterclasses in Accra.',
        timeAgo: '2d ago',
        icon: Icons.event_available_rounded,
        iconColor: const Color(0xFF00E676),
        type: 'events',
        route: '/event/cortex-summit-2026',
        isRead: true,
      ),
    ];
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _markAllAsRead() {
    HapticFeedback.mediumImpact();
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    setState(() {
      _notifications.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _notifications.where((n) {
      if (_selectedFilter == 'all') return true;
      if (_selectedFilter == 'unread') return !n.isRead;
      return n.type == _selectedFilter;
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F110B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewPadding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: AppTheme.primaryAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Notifications',
                    style: AppTheme.font(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (_unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAccent,
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      ),
                      child: Text(
                        '$_unreadCount new',
                        style: AppTheme.font(
                          color: Colors.black,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  if (_unreadCount > 0)
                    GestureDetector(
                      onTap: _markAllAsRead,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Text(
                          'Mark read',
                          style: AppTheme.font(
                            color: AppTheme.primaryAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF161811),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: const Center(
                        child: Icon(Icons.close_rounded, color: Colors.white, size: 17),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Filter Pills Row
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip('all', 'All (${_notifications.length})'),
                if (_unreadCount > 0)
                  _filterChip('unread', 'Unread ($_unreadCount)'),
                _filterChip('cfp', 'CFP & Talks'),
                _filterChip('events', 'Events'),
                _filterChip('speakers', 'Speakers'),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Notifications List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_off_outlined,
                              color: AppTheme.textMuted,
                              size: 38,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            "You're all caught up!",
                            style: AppTheme.font(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No notifications in this category right now.',
                            style: AppTheme.font(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => item.isRead = true);
                          if (item.route != null && item.route!.isNotEmpty) {
                            Navigator.pop(context);
                            context.push(item.route!);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: item.isRead
                                ? const Color(0xFF141610)
                                : const Color(0xFF1A1D13),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: item.isRead
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : AppTheme.primaryAccent.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon Pill
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: item.iconColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    item.icon,
                                    color: item.iconColor,
                                    size: 19,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTheme.font(
                                              color: Colors.white,
                                              fontSize: 13.5,
                                              fontWeight: item.isRead
                                                  ? FontWeight.w600
                                                  : FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          item.timeAgo,
                                          style: AppTheme.font(
                                            color: AppTheme.textMuted,
                                            fontSize: 10.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.body,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.font(
                                        color: AppTheme.textMuted,
                                        fontSize: 12,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!item.isRead) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          if (_notifications.isNotEmpty) ...[
            const SizedBox(height: 10),
            Center(
              child: GestureDetector(
                onTap: _clearAll,
                child: Text(
                  'Clear all notifications',
                  style: AppTheme.font(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterChip(String id, String label) {
    final isSelected = _selectedFilter == id;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = id);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryAccent : const Color(0xFF161811),
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryAccent
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: AppTheme.font(
            color: isSelected ? Colors.black : AppTheme.textMuted,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
