import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/core/services/api_client.dart';
import 'package:speakwise_mobile/core/services/storage_service.dart';
import 'package:speakwise_mobile/core/widgets/app_shimmer.dart';
import 'package:speakwise_mobile/features/explore/data/events_repository.dart';

/// ═══════════════════════════════════════════════════════════════
/// Notifications Bottom Sheet
/// Real notifications stream for user alerts, live events, and CFP announcements
/// ═══════════════════════════════════════════════════════════════
class NotificationsSheet extends ConsumerStatefulWidget {
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
  ConsumerState<NotificationsSheet> createState() => _NotificationsSheetState();
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
  final bool isBackend;
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
    this.isBackend = false,
    this.isRead = false,
  });
}

class _NotificationsSheetState extends ConsumerState<NotificationsSheet> {
  String _selectedFilter = 'all';
  bool _isLoading = true;
  List<_NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  _NotificationItem _fromBackendJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? UniqueKey().toString();
    final message = json['message']?.toString() ?? 'New notification';
    final link = json['link']?.toString();
    final isRead = json['is_read'] == true;
    final createdAtStr = json['created_at']?.toString();

    String timeAgo = 'Just now';
    if (createdAtStr != null) {
      final dt = DateTime.tryParse(createdAtStr);
      if (dt != null) {
        timeAgo = _formatTimeAgo(dt);
      }
    }

    String title = 'Notification';
    String type = 'general';
    IconData icon = Icons.notifications_rounded;
    Color iconColor = AppTheme.primaryAccent;

    final lower = message.toLowerCase();
    if (lower.contains('follow')) {
      title = 'New Follower';
      type = 'speakers';
      icon = Icons.person_add_rounded;
      iconColor = const Color(0xFFFFD600);
    } else if (lower.contains('cfp') ||
        lower.contains('proposal') ||
        lower.contains('paper')) {
      title = 'CFP Update';
      type = 'cfp';
      icon = Icons.mic_external_on_rounded;
      iconColor = AppTheme.primaryAccent;
    } else if (lower.contains('feedback') ||
        lower.contains('rating') ||
        lower.contains('review')) {
      title = 'Audience Feedback';
      type = 'talks';
      icon = Icons.star_rounded;
      iconColor = const Color(0xFF00E5FF);
    } else if (lower.contains('event') || lower.contains('session')) {
      title = 'Event Update';
      type = 'events';
      icon = Icons.event_available_rounded;
      iconColor = const Color(0xFF00E676);
    } else if (lower.contains('badge') || lower.contains('achievement')) {
      title = 'Badge Unlocked';
      type = 'speakers';
      icon = Icons.emoji_events_rounded;
      iconColor = const Color(0xFFFFB300);
    }

    return _NotificationItem(
      id: id,
      title: title,
      body: message,
      timeAgo: timeAgo,
      icon: icon,
      iconColor: iconColor,
      type: type,
      route: link,
      isBackend: true,
      isRead: isRead,
    );
  }

  Future<void> _loadNotifications() async {
    final items = <_NotificationItem>[];
    final storage = ref.read(storageServiceProvider);
    final isAuthenticated = storage.isAuthenticated;

    // 1. Fetch user notifications from backend if authenticated
    if (isAuthenticated) {
      try {
        final res = await ref
            .read(apiClientProvider)
            .get('/notifications/', authenticated: true);
        List rawList = [];
        if (res is Map && res['results'] is List) {
          rawList = res['results'] as List;
        } else if (res is List) {
          rawList = res;
        }
        for (final raw in rawList) {
          if (raw is Map) {
            items.add(_fromBackendJson(Map<String, dynamic>.from(raw)));
          }
        }
      } catch (e) {
        debugPrint('Could not load user notifications from backend: $e');
      }
    }

    // 2. Fetch live events for real CFP and platform updates
    try {
      final events = await ref.read(eventsRepositoryProvider).getEvents();
      // Add real events with CFP open
      final cfpEvents = events.where((e) => e.cfpOpen).take(3);
      for (final ev in cfpEvents) {
        final cfpRoute = (ev.cfpLink != null && ev.cfpLink!.trim().isNotEmpty)
            ? ev.cfpLink!
            : '/event/${ev.id}';
        items.add(
          _NotificationItem(
            id: 'cfp-${ev.id}',
            title: 'CFP Open • ${ev.title}',
            body:
                'Call for Proposals is open for ${ev.location}! Tap to submit your talk proposal.',
            timeAgo: 'Open now',
            icon: Icons.mic_external_on_rounded,
            iconColor: AppTheme.primaryAccent,
            type: 'cfp',
            route: cfpRoute,
            isRead: false,
          ),
        );
      }

      // Add upcoming flagship events
      final upcoming = events.where((e) => !e.cfpOpen).take(2);
      for (final ev in upcoming) {
        items.add(
          _NotificationItem(
            id: 'event-${ev.id}',
            title: 'Upcoming • ${ev.title}',
            body:
                '${ev.location} • ${ev.date}. Register to attend and connect with top speakers.',
            timeAgo: ev.dateBadgeMonth != null
                ? '${ev.dateBadgeMonth} ${ev.dateBadgeDay ?? ""}'.trim()
                : 'Upcoming',
            icon: Icons.event_available_rounded,
            iconColor: const Color(0xFF00E676),
            type: 'events',
            route: '/event/${ev.id}',
            isRead: true,
          ),
        );
      }
    } catch (e) {
      debugPrint('Could not load live event notifications: $e');
    }

    if (mounted) {
      setState(() {
        _notifications = items;
        _isLoading = false;
      });
    }
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _markAllAsRead() async {
    HapticFeedback.mediumImpact();
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });

    for (final n in _notifications) {
      if (n.isBackend) {
        try {
          await ref
              .read(apiClientProvider)
              .post('/notifications/${n.id}/read/', authenticated: true);
        } catch (_) {}
      }
    }
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    setState(() {
      _notifications.clear();
    });
  }

  void _onNotificationTapped(_NotificationItem item) async {
    HapticFeedback.lightImpact();
    setState(() => item.isRead = true);

    if (item.isBackend) {
      try {
        await ref
            .read(apiClientProvider)
            .post('/notifications/${item.id}/read/', authenticated: true);
      } catch (_) {}
    }

    if (item.route != null && item.route!.isNotEmpty) {
      String route = item.route!.trim();
      if (!mounted) return;
      Navigator.pop(context);
      if (route.startsWith('http://') || route.startsWith('https://')) {
        final uri = Uri.tryParse(route);
        if (uri != null) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        if (!route.startsWith('/')) {
          route = '/$route';
        }
        try {
          context.push(route);
        } catch (e) {
          debugPrint('Notification navigation error for $route: $e');
        }
      }
    }
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAccent,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusPill,
                        ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
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
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
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
            child: _isLoading
                ? ListView.separated(
                    itemCount: 4,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, _) => AppShimmer(
                      child: Container(
                        width: double.infinity,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFF141416),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  )
                : filtered.isEmpty
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
                    separatorBuilder: (_, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return GestureDetector(
                        onTap: () => _onNotificationTapped(item),
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
                                  : AppTheme.primaryAccent.withValues(
                                      alpha: 0.35,
                                    ),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
