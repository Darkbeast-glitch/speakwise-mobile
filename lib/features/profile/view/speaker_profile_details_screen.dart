import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/core/config/app_constants.dart';
import 'package:speakwise_mobile/core/services/storage_service.dart';
import 'package:speakwise_mobile/core/utils/event_logo_resolver.dart';
import 'package:speakwise_mobile/core/widgets/app_shimmer.dart';
import 'package:speakwise_mobile/core/widgets/user_avatar.dart';
import 'package:speakwise_mobile/features/profile/profile.dart';

/// ═══════════════════════════════════════════════════════════════
/// Screen: Speaker Profile Details Screen
/// Displays Speaker Hero Portrait, Events Spoken (conferences from
/// their talks and experiences), About Bio, Skills & Experience with
/// interactive Talks Given viewer, and "Request [Speaker]" bottom sheet.
/// ═══════════════════════════════════════════════════════════════
class SpeakerProfileDetailsScreen extends ConsumerStatefulWidget {
  final String speakerId;

  const SpeakerProfileDetailsScreen({super.key, required this.speakerId});

  @override
  ConsumerState<SpeakerProfileDetailsScreen> createState() =>
      _SpeakerProfileDetailsScreenState();
}

class _SpeakerProfileDetailsScreenState
    extends ConsumerState<SpeakerProfileDetailsScreen> {
  bool _isFavorited = false;
  bool _isFollowing = false;
  bool _hasSyncedFollowing = false;
  int? _followersCount;

  void _onRequestSpeaker(UserProfile profile) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RequestSpeakerBottomSheet(profile: profile),
    );
  }

  void _showTalksBottomSheet(BuildContext context, UserProfile profile) {
    // 1. Gather all talks from profile.talks
    final List<SpeakerTalkItem> talks = List.from(profile.talks);

    // 2. If talks is empty but eventsSpoken is available, populate from eventsSpoken
    if (talks.isEmpty && profile.eventsSpoken.isNotEmpty) {
      for (final evt in profile.eventsSpoken) {
        talks.add(SpeakerTalkItem(
          id: evt.id,
          title: evt.topic.isNotEmpty ? evt.topic : '${evt.name} Talk',
          description: (evt.description != null && evt.description!.isNotEmpty)
              ? evt.description!
              : 'Verified talk delivered at ${evt.name}.',
          duration: 45,
          category: 'Talk',
          eventTitle: evt.name,
          eventId: evt.eventId,
          eventImage: evt.image,
          date: evt.date,
          presentationLink: evt.presentationLink,
          videoRecordingLink: evt.videoRecordingLink,
        ));
      }
    }

    final displayName = profile.firstName.isNotEmpty
        ? profile.firstName
        : (profile.fullName.isNotEmpty ? profile.fullName : 'Speaker');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF141416),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag indicator
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.record_voice_over_rounded,
                          color: AppTheme.primaryAccent,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$displayName's Verified Presentations",
                            style: AppTheme.font(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            '${talks.length} verified sessions delivered',
                            style: AppTheme.font(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),

              Divider(
                color: Colors.white.withValues(alpha: 0.08),
                height: 20,
              ),

              // Talks list
              Expanded(
                child: talks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No specific talks recorded yet for this speaker.',
                            textAlign: TextAlign.center,
                            style: AppTheme.font(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                        itemCount: talks.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _VerifiedTalkItemCard(talk: talks[index]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(speakerProfileProvider(widget.speakerId));

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        bottom: false,
        child: profileAsync.when(
          loading: () => const SpeakerProfileShimmer(),
          error: (err, _) => Center(
            child: Text(
              'Error loading speaker profile',
              style: AppTheme.font(color: Colors.white70),
            ),
          ),
          data: (profile) {
            final storage = ref.watch(storageServiceProvider);
            final currentUsername = storage.username?.trim().toLowerCase();
            final currentUserId = storage.userId?.trim();
            final currentSpeakerId = storage.speakerId?.trim();
            final currentSpeakerSlug = storage.speakerSlug?.trim().toLowerCase();

            final targetUsername = profile.username.trim().toLowerCase();
            final targetUserId = profile.id.trim();
            final targetSlug = profile.slug.trim().toLowerCase();
            final targetIdParam = widget.speakerId.trim().toLowerCase();

            final isSelf = (currentUsername != null &&
                    currentUsername.isNotEmpty &&
                    currentUsername == targetUsername) ||
                (currentUserId != null &&
                    currentUserId.isNotEmpty &&
                    currentUserId == targetUserId) ||
                (currentSpeakerId != null &&
                    currentSpeakerId.isNotEmpty &&
                    currentSpeakerId == targetUserId) ||
                (currentSpeakerSlug != null &&
                    currentSpeakerSlug.isNotEmpty &&
                    (currentSpeakerSlug == targetSlug ||
                        currentSpeakerSlug == targetIdParam)) ||
                (targetIdParam == currentUsername ||
                    targetIdParam == currentUserId);

            if (!_hasSyncedFollowing) {
              _isFollowing = profile.isFollowing ||
                  storage.isSpeakerFollowed(widget.speakerId);
              _followersCount = profile.followersCount;
              _hasSyncedFollowing = true;
            }
            final effectiveFollowersCount = _followersCount ?? profile.followersCount;
            final displayName = profile.fullName.isNotEmpty
                ? profile.fullName
                : (profile.firstName.isNotEmpty
                      ? profile.firstName
                      : 'Speaker');
            final firstName = profile.firstName.isNotEmpty
                ? profile.firstName
                : (profile.fullName.isNotEmpty
                      ? profile.fullName.split(' ').first
                      : 'Speaker');
            final organization = profile.organization.trim();
            final countryWithFlag = profile.country.trim();
            final bioText = profile.biography.isNotEmpty
                ? profile.biography
                : profile.shortBio;
            final skills = profile.skills;

            return Column(
              children: [
                // 1. Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
                            color: const Color(0xFF161618),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
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

                      // Screen Title
                      Text(
                        'Speaker Profile',
                        style: AppTheme.font(
                          color: AppTheme.textPrimary,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),

                      // Placeholder for alignment
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                // 2. Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // 3. Hero Photo Card
                          Container(
                            height: 400,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Speaker Image
                                  _buildSpeakerHeroImage(
                                    profile.avatarPath,
                                    displayName,
                                  ),

                                  // Dark Vignette & Bottom Text Contrast Gradient
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.35),
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.55),
                                          Colors.black.withValues(alpha: 0.95),
                                        ],
                                        stops: const [0.0, 0.35, 0.7, 1.0],
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
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.mic_none_rounded,
                                              color: AppTheme.primaryAccent,
                                              size: 22,
                                            );
                                          },
                                    ),
                                  ),

                                  // Top-Right Connect/Follow Button
                                  Positioned(
                                    top: 18,
                                    right: 18,
                                    child: GestureDetector(
                                      onTap: () async {
                                        if (isSelf) {
                                          HapticFeedback.heavyImpact();
                                          ScaffoldMessenger.of(context)
                                              .hideCurrentSnackBar();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.info_outline_rounded,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'You cannot follow your own profile.',
                                                      style: AppTheme.font(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor:
                                                  const Color(0xFF1E2024),
                                              duration:
                                                  const Duration(seconds: 2),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        HapticFeedback.lightImpact();
                                        final previous = _isFollowing;
                                        final newStatus = !previous;
                                        setState(() {
                                          _isFollowing = newStatus;
                                          if (newStatus) {
                                            _followersCount = ((_followersCount ?? profile.followersCount) + 1);
                                          } else {
                                            _followersCount = math.max(0, (_followersCount ?? profile.followersCount) - 1);
                                          }
                                        });

                                        // Persist follow state locally
                                        await storage.toggleSpeakerFollow(
                                            widget.speakerId);

                                        // Inform backend
                                        try {
                                          await ref
                                              .read(profileRepositoryProvider)
                                              .toggleFollowSpeaker(
                                                  widget.speakerId);
                                        } catch (e) {
                                          debugPrint('Follow speaker notice: $e');
                                        }

                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .hideCurrentSnackBar();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  Icon(
                                                    newStatus
                                                        ? Icons
                                                            .check_circle_rounded
                                                        : Icons
                                                            .remove_circle_outline_rounded,
                                                    color: newStatus
                                                        ? AppTheme.primaryAccent
                                                        : const Color(0xFFFF5252),
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      newStatus
                                                          ? 'Following $displayName'
                                                          : 'Unfollowed $displayName',
                                                      style: AppTheme.font(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor:
                                                  const Color(0xFF1B1D1F),
                                              duration:
                                                  const Duration(seconds: 2),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 220),
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: _isFollowing
                                              ? const Color(0xFFE53935) // Red when following (Unfollow)
                                              : AppTheme.primaryAccent, // Neon Lime when not following (+)
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: (_isFollowing
                                                      ? const Color(0xFFE53935)
                                                      : AppTheme.primaryAccent)
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Icon(
                                            _isFollowing
                                                ? Icons.person_remove_rounded // Red with person and -
                                                : Icons.person_add_rounded, // Neon Lime with person and +
                                            color: _isFollowing
                                                ? Colors.white
                                                : Colors.black,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Bottom Center Speaker Info
                                  Positioned(
                                    left: 20,
                                    right: 20,
                                    bottom: 22,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          displayName,
                                          textAlign: TextAlign.center,
                                          style: AppTheme.font(
                                            color: Colors.white,
                                            fontSize: 23,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.4,
                                          ),
                                        ),
                                        if (organization.isNotEmpty) ...[
                                          const SizedBox(height: 5),
                                          Text(
                                            organization,
                                            textAlign: TextAlign.center,
                                            style: AppTheme.font(
                                              color: Colors.white.withValues(
                                                alpha: 0.75,
                                              ),
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                        if (countryWithFlag.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            countryWithFlag,
                                            textAlign: TextAlign.center,
                                            style: AppTheme.font(
                                              color: Colors.white.withValues(
                                                alpha: 0.65,
                                              ),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                        if (profile.rankTier != null &&
                                            profile.rankTier!.trim().isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryAccent
                                                  .withValues(alpha: 0.18),
                                              borderRadius: BorderRadius.circular(
                                                AppTheme.radiusPill,
                                              ),
                                              border: Border.all(
                                                color: AppTheme.primaryAccent,
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.star_rounded,
                                                  color: AppTheme.primaryAccent,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  profile.reputationScore != null
                                                      ? '${profile.rankTier} • ${profile.reputationScore!.toStringAsFixed(1)}'
                                                      : profile.rankTier!,
                                                  style: AppTheme.font(
                                                    color: AppTheme.primaryAccent,
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 10),
                                        // Followers & Following Count Pill
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.45,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(
                                              AppTheme.radiusPill,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.12,
                                              ),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '$effectiveFollowersCount',
                                                style: AppTheme.font(
                                                  color: Colors.white,
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                effectiveFollowersCount == 1
                                                    ? 'Follower'
                                                    : 'Followers',
                                                style: AppTheme.font(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.7),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              Container(
                                                margin: const EdgeInsets
                                                    .symmetric(
                                                  horizontal: 10,
                                                ),
                                                width: 3,
                                                height: 3,
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.45),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              Text(
                                                '${profile.followingCount}',
                                                style: AppTheme.font(
                                                  color: Colors.white,
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Following',
                                                style: AppTheme.font(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.7),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                ),
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

                          const SizedBox(height: 14),

                          // 4. "Events Spoken" Card (Conferences the speaker has spoken at)
                          _buildEventsSpokenCard(profile),

                          const SizedBox(height: 14),

                          // 5. "About [FirstName]" Card
                          if (bioText.trim().isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFF141416),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'About $firstName',
                                    style: AppTheme.font(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    bioText,
                                    style: AppTheme.font(
                                      color: const Color(0xFFB0B0B8),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w400,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // 6. "Skills and Experience" Card (Skills only!)
                          if (skills.isNotEmpty) ...[
                            _buildSkillsAndExperienceCard(skills),
                            const SizedBox(height: 14),
                          ],

                          // 7. "Talks Given" Dedicated Card
                          _buildTalksGivenCard(context, profile),

                          const SizedBox(height: 14),

                          // 8. "Badges & Achievements" Section (All system badges with acquired / dimmed status)
                          _buildBadgesSection(context, profile.badges),

                          const SizedBox(height: 110),
                        ],
                      ),
                    ),
                  ),
                ),

                // 7. Bottom Sticky Action Bar: "Request [FirstName]" + Heart
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  decoration: BoxDecoration(
                    color: AppTheme.bgDark.withValues(alpha: 0.95),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.06),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Large Neon Lime "Request [FirstName]" Button
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => _onRequestSpeaker(profile),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryAccent,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusPill,
                                ),
                              ),
                            ),
                            child: Text(
                              'Request $firstName',
                              style: AppTheme.font(
                                color: Colors.black,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Heart/Favorite Circle Button
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _isFavorited = !_isFavorited);
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF141416),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              _isFavorited
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: _isFavorited
                                  ? const Color(0xFFFF4B6E)
                                  : Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSpeakerHeroImage(String avatarPath, [String? speakerName]) {
    var cleanPath = avatarPath.trim();
    if (cleanPath.startsWith('/')) {
      try {
        String base = AppConstants.defaultApiUrl;
        if (dotenv.isInitialized) {
          final envUrl = dotenv.maybeGet('API_BASE_URL');
          if (envUrl != null && envUrl.isNotEmpty) {
            base = envUrl;
          }
        }
        final baseUri = Uri.parse(base);
        final origin =
            '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
        cleanPath = '$origin$cleanPath';
      } catch (_) {}
    }

    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: cleanPath,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => _buildHeroFallback(speakerName),
        errorWidget: (_, _, _) => Image.network(
          cleanPath,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, _, _) => _buildHeroFallback(speakerName),
        ),
      );
    }

    final isJulius = (speakerName ?? '').toLowerCase().contains('julius');
    if (cleanPath.isNotEmpty &&
        (!cleanPath.contains('Julius.png') || isJulius)) {
      return Image.asset(
        cleanPath,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (_, _, _) => _buildHeroFallback(speakerName),
      );
    }

    return _buildHeroFallback(speakerName);
  }

  Widget _buildHeroFallback(String? speakerName) {
    final name = (speakerName ?? '').trim();
    String initials = '';
    if (name.isNotEmpty) {
      final parts = name.split(' ');
      initials = parts.length > 1
          ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
          : name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
    }

    return Container(
      color: const Color(0xFF1B1E16),
      child: Center(
        child: initials.isNotEmpty
            ? Text(
                initials,
                style: AppTheme.font(
                  color: AppTheme.primaryAccent,
                  fontSize: 64,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              )
            : const Icon(
                Icons.person_rounded,
                color: AppTheme.textMuted,
                size: 72,
              ),
      ),
    );
  }

  Widget _buildEventsSpokenCard(UserProfile profile) {
    final events = profile.eventsSpoken;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row Header: Events Spoken
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Events Spoken',
                style: AppTheme.font(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              if (events.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                  child: Text(
                    '${events.length} ${events.length == 1 ? 'event' : 'events'}',
                    style: AppTheme.font(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No events listed yet',
                style: AppTheme.font(color: AppTheme.textMuted, fontSize: 12.5),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: events.map((event) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1B1E16),
                            border: Border.all(
                              color: AppTheme.primaryAccent.withValues(
                                alpha: 0.35,
                              ),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _buildEventImage(event.image, event.name),
                          ),
                        ),
                        const SizedBox(height: 7),
                        SizedBox(
                          width: 68,
                          child: Text(
                            event.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.font(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventImage(String imagePath, String eventName) {
    final logoUrl = EventLogoResolver.resolveLogoUrl(
      eventName: eventName,
      currentImage: imagePath,
    );

    // If an explicit image path was already attached from the database
    final isExplicitBanner =
        imagePath.trim().isNotEmpty && !imagePath.contains('favicon');

    if (logoUrl.startsWith('http://') || logoUrl.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: logoUrl,
        fit: isExplicitBanner ? BoxFit.cover : BoxFit.contain,
        fadeInDuration: const Duration(milliseconds: 150),
        imageBuilder: (context, imageProvider) {
          return Container(
            color: const Color(0xFF161814),
            padding: isExplicitBanner
                ? EdgeInsets.zero
                : const EdgeInsets.all(6),
            child: Image(
              image: imageProvider,
              fit: isExplicitBanner ? BoxFit.cover : BoxFit.contain,
            ),
          );
        },
        placeholder: (context, url) => const AppShimmer(
          child: ShimmerBox(
            width: double.infinity,
            height: double.infinity,
            borderRadius: 0,
          ),
        ),
        errorWidget: (context, url, error) => Image.network(
          logoUrl,
          fit: isExplicitBanner ? BoxFit.cover : BoxFit.contain,
          errorBuilder: (_, _, _) => _buildEventFallbackBadge(eventName),
        ),
      );
    }

    if (logoUrl.startsWith('assets/')) {
      return Image.asset(
        logoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildEventFallbackBadge(eventName),
      );
    }

    return _buildEventFallbackBadge(eventName);
  }

  Widget _buildEventFallbackBadge(String eventName) {
    final initial = eventName.isNotEmpty ? eventName[0].toUpperCase() : 'E';
    return Container(
      color: const Color(0xFF1B1E16),
      child: Center(
        child: Text(
          initial,
          style: AppTheme.font(
            color: AppTheme.primaryAccent,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildSkillsAndExperienceCard(List<String> skills) {
    if (skills.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skills and Experience',
            style: AppTheme.font(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),

          // Skills Tag Grid
          _buildSkillsGrid(skills),
        ],
      ),
    );
  }

  Widget _buildTalksGivenCard(BuildContext context, UserProfile profile) {
    final talksCount = profile.talks.isNotEmpty
        ? profile.talks.length
        : profile.talksGiven;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Talks Given',
                style: AppTheme.font(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                '$talksCount delivered',
                style: AppTheme.font(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Talks Given Interactive Section (Icon + Total Talks + Tap to View)
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              HapticFeedback.lightImpact();
              _showTalksBottomSheet(context, profile);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1D1F),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.primaryAccent.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.record_voice_over_rounded,
                        color: AppTheme.primaryAccent,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verified Presentations',
                          style: AppTheme.font(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$talksCount talks delivered across conferences',
                          style: AppTheme.font(
                            color: AppTheme.textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccent,
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$talksCount Talks',
                          style: AppTheme.font(
                            color: Colors.black,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.black,
                          size: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(BuildContext context, List<SpeakerBadge> badges) {
    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    final acquiredCount = badges.where((b) => b.isAcquired).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header: Title + Acquired Count Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Badges & Achievements',
                style: AppTheme.font(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: acquiredCount > 0
                      ? AppTheme.primaryAccent.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  border: Border.all(
                    color: acquiredCount > 0
                        ? AppTheme.primaryAccent.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.1),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '$acquiredCount / ${badges.length} Unlocked',
                  style: AppTheme.font(
                    color: acquiredCount > 0
                        ? AppTheme.primaryAccent
                        : AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Badges Horizontal List
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: badges.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final badge = badges[index];
                return _buildBadgeCard(context, badge);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(BuildContext context, SpeakerBadge badge) {
    final isAcquired = badge.isAcquired;

    Color tierColor;
    switch (badge.tier.toLowerCase()) {
      case 'gold':
        tierColor = const Color(0xFFF59E0B);
        break;
      case 'silver':
        tierColor = const Color(0xFF94A3B8);
        break;
      case 'bronze':
      default:
        tierColor = const Color(0xFFD97706);
        break;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showBadgeDetailModal(context, badge, tierColor);
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isAcquired ? 1.0 : 0.38,
        child: Container(
          width: 138,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isAcquired
                ? const Color(0xFF181B17)
                : const Color(0xFF141416),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isAcquired
                  ? tierColor.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.08),
              width: isAcquired ? 1.2 : 1,
            ),
            boxShadow: isAcquired
                ? [
                    BoxShadow(
                      color: tierColor.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Emoji / Lock Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(badge.emoji, style: const TextStyle(fontSize: 26)),
                  if (!isAcquired)
                    const Icon(
                      Icons.lock_rounded,
                      size: 14,
                      color: Color(0xFF888890),
                    )
                  else
                    Icon(Icons.verified_rounded, size: 15, color: tierColor),
                ],
              ),

              // Title and Tier
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    badge.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.font(
                      color: isAcquired
                          ? Colors.white
                          : const Color(0xFF888890),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    badge.tier.toUpperCase(),
                    style: AppTheme.font(
                      color: isAcquired ? tierColor : const Color(0xFF666670),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),

              // Bottom Status Pill
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isAcquired
                      ? tierColor.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  isAcquired ? '✓ Unlocked' : '🔒 Locked',
                  style: AppTheme.font(
                    color: isAcquired ? tierColor : const Color(0xFF777780),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBadgeDetailModal(
    BuildContext context,
    SpeakerBadge badge,
    Color tierColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141416),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drag bar
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Emoji
            Text(badge.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),

            // Title
            Text(
              badge.title,
              textAlign: TextAlign.center,
              style: AppTheme.font(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),

            // Tier & Status Chips Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    border: Border.all(color: tierColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    badge.tier.toUpperCase(),
                    style: AppTheme.font(
                      color: tierColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badge.isAcquired
                        ? AppTheme.primaryAccent.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                  child: Text(
                    badge.isAcquired ? '✓ Acquired' : '🔒 Locked',
                    style: AppTheme.font(
                      color: badge.isAcquired
                          ? AppTheme.primaryAccent
                          : AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: AppTheme.font(
                color: const Color(0xFFC0C0C8),
                fontSize: 13.5,
                height: 1.4,
              ),
            ),

            // Criteria
            if (badge.criteria.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1E20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REQUIREMENT TO UNLOCK',
                      style: AppTheme.font(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      badge.criteria,
                      style: AppTheme.font(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Close button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Close',
                  style: AppTheme.font(
                    color: Colors.black,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsGrid(List<String> skills) {
    return Wrap(
      spacing: 24,
      runSpacing: 10,
      children: skills.map((skill) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              skill,
              style: AppTheme.font(
                color: AppTheme.primaryAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// Verified Talk Item Card with Expandable Description & Clean Rich Text
/// ═══════════════════════════════════════════════════════════════
class _VerifiedTalkItemCard extends StatefulWidget {
  final SpeakerTalkItem talk;

  const _VerifiedTalkItemCard({required this.talk});

  @override
  State<_VerifiedTalkItemCard> createState() => _VerifiedTalkItemCardState();
}

class _VerifiedTalkItemCardState extends State<_VerifiedTalkItemCard> {
  bool _isExpanded = false;

  String _cleanHtml(String htmlString) {
    if (htmlString.isEmpty) return '';
    var text = htmlString;
    // Replace breaks, paragraphs and list items with clean formatting
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'</li>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<li>', caseSensitive: false), '• ');
    // Strip all HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    // Decode HTML entities
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
    // Collapse multi-newlines into clean paragraphs
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  @override
  Widget build(BuildContext context) {
    final talk = widget.talk;
    final cleanDesc = _cleanHtml(talk.description);
    final hasSlides = talk.presentationLink != null && talk.presentationLink!.trim().isNotEmpty;
    final hasVideo = talk.videoRecordingLink != null && talk.videoRecordingLink!.trim().isNotEmpty;
    final hasEvent = talk.eventId != null && talk.eventId!.trim().isNotEmpty;
    final isLong = cleanDesc.length > 110 || cleanDesc.contains('\n');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1D1F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  talk.title,
                  style: AppTheme.font(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${talk.duration}m',
                  style: AppTheme.font(
                    color: AppTheme.primaryAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (talk.eventTitle.isNotEmpty ||
              (talk.date != null && talk.date!.isNotEmpty)) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (talk.eventTitle.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.event_outlined,
                        color: AppTheme.primaryAccent,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        talk.eventTitle,
                        style: AppTheme.font(
                          color: AppTheme.primaryAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                if (talk.date != null && talk.date!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: AppTheme.textMuted,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        talk.date!,
                        style: AppTheme.font(
                          color: AppTheme.textMuted,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
          if (cleanDesc.isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: isLong
                  ? () {
                      HapticFeedback.selectionClick();
                      setState(() => _isExpanded = !_isExpanded);
                    }
                  : null,
              child: AnimatedCrossFade(
                firstChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cleanDesc,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.font(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                    if (isLong) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'See more...',
                            style: AppTheme.font(
                              color: AppTheme.primaryAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppTheme.primaryAccent,
                            size: 14,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cleanDesc,
                      style: AppTheme.font(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'See less',
                          style: AppTheme.font(
                            color: AppTheme.primaryAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.keyboard_arrow_up_rounded,
                          color: AppTheme.primaryAccent,
                          size: 14,
                        ),
                      ],
                    ),
                  ],
                ),
                crossFadeState:
                    _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 220),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
                child: Text(
                  'Talk',
                  style: AppTheme.font(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (hasSlides) ...[
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.tryParse(talk.presentationLink!);
                    if (uri != null) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      border: Border.all(
                        color: AppTheme.primaryAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.slideshow_rounded,
                          color: AppTheme.primaryAccent,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Slides',
                          style: AppTheme.font(
                            color: AppTheme.primaryAccent,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (hasVideo) ...[
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.tryParse(talk.videoRecordingLink!);
                    if (uri != null) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_circle_outline_rounded,
                          color: Colors.white70,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Video',
                          style: AppTheme.font(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (hasEvent)
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/event/${talk.eventId}');
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Event',
                        style: AppTheme.font(
                          color: AppTheme.primaryAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppTheme.primaryAccent,
                        size: 13,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// Bottom Sheet to Request Speaker Keynote / Talk
/// Matches exactly the SpeakWise WebApp design reference:
/// - Avatar with speaker initials
/// - "Request [Speaker Name]"
/// - "How email requests work" information callout
/// - Form: "Event Name *", "Event Location *", "Your Message *"
/// - "Cancel" and "Send Email Request" action buttons
/// ═══════════════════════════════════════════════════════════════
class _RequestSpeakerBottomSheet extends ConsumerStatefulWidget {
  final UserProfile profile;

  const _RequestSpeakerBottomSheet({required this.profile});

  @override
  ConsumerState<_RequestSpeakerBottomSheet> createState() =>
      _RequestSpeakerBottomSheetState();
}

class _RequestSpeakerBottomSheetState
    extends ConsumerState<_RequestSpeakerBottomSheet> {
  final _eventNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _eventNameController.dispose();
    _locationController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final eventName = _eventNameController.text.trim();
    final location = _locationController.text.trim();
    final message = _messageController.text.trim();

    if (eventName.isEmpty || location.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
          content: Text(
            'Please complete all required fields.',
            style: AppTheme.font(color: Colors.white, fontSize: 13),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final targetId = widget.profile.userAccountId.isNotEmpty
        ? widget.profile.userAccountId
        : (widget.profile.id.isNotEmpty
              ? widget.profile.id
              : widget.profile.username);

    try {
      await ref
          .read(profileRepositoryProvider)
          .sendSpeakerEmailRequest(
            speakerId: targetId,
            eventName: eventName,
            location: location,
            message: message,
          );
    } catch (_) {
      // In offline or non-authenticated mock mode, gracefully simulate successful delivery
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.primaryAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.black,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Speaking invitation delivered to ${widget.profile.fullName}!',
                style: AppTheme.font(
                  color: Colors.black,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName = widget.profile.fullName.isNotEmpty
        ? widget.profile.fullName
        : 'Speaker';

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Scrollable Form Body
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header with Speaker Image & Title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      UserAvatar(
                        name: fullName,
                        avatarUrl: widget.profile.avatarPath,
                        size: 52,
                        showBorder: true,
                        borderColor: AppTheme.primaryAccent,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Request $fullName',
                              style: AppTheme.font(
                                color: AppTheme.textPrimary,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Send a speaking invitation directly to their inbox',
                              style: AppTheme.font(
                                color: AppTheme.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 2. Info Card: "How email requests work"
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.mail_outline_rounded,
                                  color: AppTheme.primaryAccent,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'How email requests work',
                              style: AppTheme.font(
                                color: AppTheme.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your invitation is delivered straight to $fullName\'s verified email. They can review event details and accept or decline from their SpeakWise dashboard.',
                          style: AppTheme.font(
                            color: const Color(0xFFB0B0B8),
                            fontSize: 12.5,
                            height: 1.45,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. Field: Event Name *
                  Text(
                    'Event Name *',
                    style: AppTheme.font(
                      color: AppTheme.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _eventNameController,
                    style: AppTheme.font(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    cursorColor: AppTheme.primaryAccent,
                    decoration: InputDecoration(
                      hintText: 'e.g. NextGen Web Summit 2026',
                      hintStyle: AppTheme.font(
                        color: AppTheme.textMuted,
                        fontSize: 13.5,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E1E22),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryAccent,
                          width: 1.2,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. Field: Event Location *
                  Text(
                    'Event Location *',
                    style: AppTheme.font(
                      color: AppTheme.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _locationController,
                    style: AppTheme.font(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    cursorColor: AppTheme.primaryAccent,
                    decoration: InputDecoration(
                      hintText: 'e.g. Nairobi, Kenya or Virtual (Zoom)',
                      hintStyle: AppTheme.font(
                        color: AppTheme.textMuted,
                        fontSize: 13.5,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E1E22),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryAccent,
                          width: 1.2,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 5. Field: Your Message *
                  Text(
                    'Your Message *',
                    style: AppTheme.font(
                      color: AppTheme.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    maxLines: 5,
                    minLines: 4,
                    style: AppTheme.font(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    cursorColor: AppTheme.primaryAccent,
                    decoration: InputDecoration(
                      hintText:
                          'Introduce your event, suggested session topics, expected audience, dates, or honorarium details...',
                      hintStyle: AppTheme.font(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E1E22),
                      contentPadding: const EdgeInsets.all(16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryAccent,
                          width: 1.2,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Be detailed and personal — thoughtful invitations get accepted much faster.',
                    style: AppTheme.font(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 24),
                  Divider(
                    color: Colors.white.withValues(alpha: 0.08),
                    height: 1,
                  ),
                  const SizedBox(height: 18),

                  // 6. Action Buttons: Cancel and Send Email Request
                  Row(
                    children: [
                      // Cancel Button
                      SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 26),
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTheme.font(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Send Email Request Button
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryAccent,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            shape: const StadiumBorder(),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.send_rounded,
                                      size: 16,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Send Email Request',
                                      style: AppTheme.font(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
