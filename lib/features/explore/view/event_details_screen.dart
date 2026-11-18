import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/core/services/storage_service.dart';
import 'package:speakwise_mobile/core/widgets/widgets.dart';
import 'package:speakwise_mobile/features/explore/explore.dart';

/// ═══════════════════════════════════════════════════════════════
/// Screen: Event Details Screen
/// Displays full details for an event loaded from backend or local catalog.
/// ═══════════════════════════════════════════════════════════════
class EventDetailsScreen extends ConsumerStatefulWidget {
  final String eventId;
  final EventItem? initialEvent;

  const EventDetailsScreen({
    super.key,
    required this.eventId,
    this.initialEvent,
  });

  @override
  ConsumerState<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends ConsumerState<EventDetailsScreen> {
  EventItem? _event;
  bool _isBookmarked = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _event = widget.initialEvent;
    final storage = ref.read(storageServiceProvider);
    _isBookmarked = storage.isEventBookmarked(widget.eventId);
    _loadEventDetails();
  }

  Future<void> _loadEventDetails() async {
    setState(() => _isLoading = true);
    try {
      final lookupKey = (_event?.slug != null && _event!.slug!.isNotEmpty)
          ? _event!.slug!
          : widget.eventId;
      final fresh = await ref.read(eventsRepositoryProvider).getEventDetail(lookupKey);
      if (fresh != null && mounted) {
        setState(() {
          _event = fresh;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSubmitTalk() {
    final event = _event;
    if (event == null) return;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surfaceDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          side: const BorderSide(color: AppTheme.surfaceBorder),
        ),
        content: Text(
          event.cfpOpen
              ? 'Call for Papers (CFP) is open for ${event.title}!'
              : 'Call for Papers (CFP) is currently closed for ${event.title}.',
          style: AppTheme.font(color: AppTheme.textPrimary, fontSize: 13.5),
        ),
      ),
    );
  }

  Future<void> _openEventWebsite(String rawUrl) async {
    String urlString = rawUrl.trim();
    if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
      urlString = 'https://$urlString';
    }
    final uri = Uri.tryParse(urlString);
    if (uri != null) {
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.surfaceDark,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                side: const BorderSide(color: AppTheme.surfaceBorder),
              ),
              content: Text(
                'Could not open website: $urlString',
                style: AppTheme.font(color: AppTheme.textPrimary, fontSize: 13.5),
              ),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.surfaceDark,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                side: const BorderSide(color: AppTheme.surfaceBorder),
              ),
              content: Text(
                'Could not open website: $urlString',
                style: AppTheme.font(color: AppTheme.textPrimary, fontSize: 13.5),
              ),
            ),
          );
        }
      }
    }
  }

  void _onBuyTicket() {
    final event = _event;
    if (event == null) return;
    HapticFeedback.lightImpact();

    // If event has an official website, route user to register there
    if (event.website != null && event.website!.trim().isNotEmpty) {
      _openEventWebsite(event.website!);
      return;
    }

    final isFree = event.isFree == true || !event.isTicketed;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.primaryAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
        content: Text(
          isFree
              ? 'RSVP registered for ${event.title}!'
              : 'Proceeding to checkout for ${event.title}...',
          style: AppTheme.font(
            color: Colors.black,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    if (event == null) {
      return Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: SafeArea(
          child: _isLoading
              ? const EventDetailsShimmer()
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event_busy_rounded, color: AppTheme.textMuted, size: 54),
                      const SizedBox(height: 12),
                      Text(
                        'Event not found',
                        style: AppTheme.font(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryAccent,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Back to Events'),
                      ),
                    ],
                  ),
                ),
        ),
      );
    }

    final isFree = event.isFree == true || !event.isTicketed;
    final hasWebsite = event.website != null && event.website!.trim().isNotEmpty;
    final exploreState = ref.watch(exploreViewModelProvider);
    var otherEvents = exploreState.featuredEvents
        .where((e) => e.id != event.id)
        .toList();
    if (otherEvents.isEmpty) {
      otherEvents = exploreState.allEvents
          .where((e) => e.id != event.id)
          .toList();
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Top Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.pop();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF161616),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),

                  // Center Screen Title
                  Text(
                    'Event Details',
                    style: AppTheme.font(
                      color: AppTheme.textPrimary,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),

                  // Share Button
                  GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      final box = context.findRenderObject() as RenderBox?;
                      final originRect = box != null
                          ? box.localToGlobal(Offset.zero) & box.size
                          : const Rect.fromLTWH(0, 0, 100, 100);

                      final shareUrl = event.website != null && event.website!.trim().isNotEmpty
                          ? event.website!
                          : 'https://speakwise.live/event/${event.slug ?? event.id}';

                      await Share.share(
                        'Check out ${event.title} happening on ${event.date} at ${event.location}!\n$shareUrl',
                        subject: event.title,
                        sharePositionOrigin: originRect,
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF161616),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.share_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
              ),

            // 2. Scrollable Body Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Event Hero Poster / Banner Container
                    Container(
                      height: 290,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Poster Photo
                            AppNetworkImage(
                              imageUrl: event.imagePath,
                              fit: BoxFit.cover,
                            ),

                            // Multi-stop Gradient for Poster readability
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    stops: const [0.0, 0.4, 0.8, 1.0],
                                    colors: [
                                      Colors.black.withValues(alpha: 0.6),
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.75),
                                      Colors.black.withValues(alpha: 0.95),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Top Left SpeakWise Logo
                            Positioned(
                              top: 16,
                              left: 18,
                              child: Image.asset(
                                'assets/images/logo-white.png',
                                height: 26,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.mic_none_rounded,
                                    color: AppTheme.primaryAccent,
                                    size: 22,
                                  );
                                },
                              ),
                            ),

                            // Top Right "More info on Speakwise.live"
                            Positioned(
                              top: 18,
                              right: 18,
                              child: Text(
                                'More info on Speakwise.live',
                                style: AppTheme.font(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),

                            // Center & Bottom Typography on Poster
                            Positioned(
                              left: 20,
                              right: 20,
                              bottom: 20,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    event.bannerSubtitle,
                                    textAlign: TextAlign.center,
                                    style: AppTheme.font(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    event.title,
                                    textAlign: TextAlign.center,
                                    style: AppTheme.font(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Event Meta Container (Matching Figma Frame)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Left Details: Title, Location, Date
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: AppTheme.font(
                                    color: AppTheme.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      color: AppTheme.textMuted,
                                      size: 15,
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        event.location,
                                        style: AppTheme.font(
                                          color: AppTheme.textMuted,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      color: AppTheme.textMuted,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      event.date,
                                      style: AppTheme.font(
                                        color: AppTheme.textMuted,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                                if (event.website != null &&
                                    event.website!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () => _openEventWebsite(event.website!),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.language_rounded,
                                          color: AppTheme.primaryAccent,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            event.website!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTheme.font(
                                              color: AppTheme.primaryAccent,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              decoration: TextDecoration.underline,
                                              decorationColor: AppTheme.primaryAccent
                                                  .withValues(alpha: 0.5),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.open_in_new_rounded,
                                          color: AppTheme.primaryAccent,
                                          size: 12,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Right Action: "Submit a talk" (when CFP is live) vs "CFP Closed"
                          if (event.cfpOpen)
                            GestureDetector(
                              onTap: _onSubmitTalk,
                              child: Container(
                                width: 84,
                                height: 68,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C1E18),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.primaryAccent.withValues(alpha: 0.35),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryAccent.withValues(alpha: 0.12),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.mic_external_on_rounded,
                                      color: AppTheme.primaryAccent,
                                      size: 19,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Submit\na talk',
                                      textAlign: TextAlign.center,
                                      style: AppTheme.font(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        height: 1.15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppTheme.surfaceDark,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                                      side: const BorderSide(color: AppTheme.surfaceBorder),
                                    ),
                                    content: Text(
                                      'Call for Papers (CFP) is currently closed for ${event.title}.',
                                      style: AppTheme.font(color: AppTheme.textMuted, fontSize: 13.5),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 84,
                                height: 68,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF141416),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.lock_outline_rounded,
                                      color: AppTheme.textMuted,
                                      size: 18,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'CFP\nClosed',
                                      textAlign: TextAlign.center,
                                      style: AppTheme.font(
                                        color: AppTheme.textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        height: 1.15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // "About Event" Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About Event',
                            style: AppTheme.font(
                              color: AppTheme.textPrimary,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            event.description,
                            style: AppTheme.font(
                              color: AppTheme.textMuted,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Other Featured Events Section
                    if (otherEvents.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Other Featured Events',
                            style: AppTheme.font(
                              color: AppTheme.textPrimary,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.push('/events/all');
                            },
                            child: Text(
                              'See all',
                              style: AppTheme.font(
                                color: AppTheme.primaryAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: otherEvents.take(4).length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final otherEvent = otherEvents[index];
                          final isOtherFree =
                              otherEvent.isFree == true || !otherEvent.isTicketed;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.push(
                                '/event/${otherEvent.id}',
                                extra: otherEvent,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF141414),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: 56,
                                      height: 56,
                                      child: AppNetworkImage(
                                        imageUrl: otherEvent.imagePath,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                otherEvent.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTheme.font(
                                                  color: AppTheme.textPrimary,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            if (otherEvent.isFeatured) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryAccent
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'Featured',
                                                  style: AppTheme.font(
                                                    color: AppTheme.primaryAccent,
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today_outlined,
                                              color: AppTheme.textMuted,
                                              size: 11,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                otherEvent.date,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTheme.font(
                                                  color: AppTheme.textMuted,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on_outlined,
                                              color: AppTheme.textMuted,
                                              size: 11,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                otherEvent.location,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTheme.font(
                                                  color: AppTheme.textMuted,
                                                  fontSize: 11.5,
                                                ),
                                              ),
                                            ),

                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: AppTheme.primaryAccent,
                                      size: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // 3. Bottom Sticky Action Bar: [ Buy Ticket / Free RSVP / Website ] + ( Heart / Bookmark )
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F100B),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Primary Action Button (Electric Neon Lime)
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: Material(
                        color: AppTheme.primaryAccent,
                        shape: const StadiumBorder(),
                        child: InkWell(
                          customBorder: const StadiumBorder(),
                          onTap: _onBuyTicket,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  hasWebsite
                                      ? (isFree
                                          ? 'Register on Website'
                                          : 'Buy Ticket on Website')
                                      : (isFree
                                          ? 'Register for Free'
                                          : 'Buy Ticket'),
                                  style: AppTheme.font(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                                if (hasWebsite) ...[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.open_in_new_rounded,
                                    color: Colors.black,
                                    size: 16,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Circular Heart / Bookmark Button
                  GestureDetector(
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      final storage = ref.read(storageServiceProvider);
                      final isNowBookmarked =
                          await storage.toggleEventBookmark(event.id);
                      if (mounted) {
                        setState(() => _isBookmarked = isNowBookmarked);
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  isNowBookmarked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: isNowBookmarked
                                      ? const Color(0xFFFF3366)
                                      : Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isNowBookmarked
                                        ? 'Saved to your bookmarked events'
                                        : 'Removed from bookmarks',
                                    style: AppTheme.font(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF1E2024),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _isBookmarked
                            ? const Color(0xFFFF3366).withValues(alpha: 0.15)
                            : const Color(0xFF181818),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isBookmarked
                              ? const Color(0xFFFF3366).withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.15),
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _isBookmarked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: _isBookmarked
                              ? const Color(0xFFFF3366)
                              : Colors.white,
                          size: 21,
                        ),
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
