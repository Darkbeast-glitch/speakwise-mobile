import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/core/services/storage_service.dart';
import 'package:speakwise_mobile/core/widgets/widgets.dart';
import 'package:speakwise_mobile/features/auth/auth.dart';
import 'package:speakwise_mobile/features/profile/profile.dart';

/// ═══════════════════════════════════════════════════════════════
/// Screen 5: Speaker Profile & Reputation Hub (Tab 4)
/// Reworked to match Webapp Settings & Badges (Images 0 & 1)
/// ═══════════════════════════════════════════════════════════════
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileViewModelProvider);
    final profile = profileState.profile;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: AmbientGlow(
        glowOpacity: 0.05,
        glowAlignment: const Alignment(0.0, -0.65),
        radius: 0.9,
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppTheme.primaryAccent,
            backgroundColor: AppTheme.surfaceDark,
            onRefresh: () async {
              await ref.read(profileViewModelProvider.notifier).loadProfile();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
              children: [
              // 1. Top Header Bar with Settings Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Speaker Profile',
                    style: AppTheme.font(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push('/profile/edit');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E211A),
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 15,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Settings',
                            style: AppTheme.font(
                              color: AppTheme.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 2. Main Profile Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F110C),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar with verified badge
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                          child: UserAvatar(
                            name: '${profile.firstName} ${profile.lastName}',
                            avatarUrl: profile.avatarPath,
                            size: 92,
                            showBorder: false,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.black,
                            size: 14,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Full Name
                    Text(
                      profile.fullName.isNotEmpty
                          ? profile.fullName
                          : (profile.username.isNotEmpty ? profile.username : 'Speaker Profile'),
                      style: AppTheme.font(
                        color: AppTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Username & Country Tag
                    if (profile.username.isNotEmpty || profile.country.isNotEmpty || profile.nationality.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (profile.username.isNotEmpty)
                            Text(
                              '@${profile.username}',
                              style: AppTheme.font(
                                color: const Color(0xFFCBD0C5),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (profile.country.isNotEmpty || profile.nationality.isNotEmpty) ...[
                            if (profile.username.isNotEmpty) const SizedBox(width: 8),
                            Text(
                              '• ${profile.country.isNotEmpty ? profile.country : profile.nationality}',
                              style: AppTheme.font(
                                color: AppTheme.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Organization Pill (only when user has set an organization)
                    if (profile.organization.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D201A),
                          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.business_center_outlined,
                              size: 14,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              profile.organization,
                              style: AppTheme.font(
                                color: AppTheme.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Short Bio
                    Text(
                      profile.shortBio.isNotEmpty
                          ? profile.shortBio
                          : 'No bio added yet. Tap Edit Profile to introduce yourself.',
                      textAlign: TextAlign.center,
                      style: AppTheme.font(
                        color: AppTheme.textMuted,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Edit Profile CTA Button (Calm Ash Pill)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/profile/edit');
                      },
                      child: Container(
                        width: double.infinity,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22261E),
                          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: AppTheme.textPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Edit Profile & Settings',
                              style: AppTheme.font(
                                color: AppTheme.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Speaker Performance Metrics
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F110C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metric('${profile.talksGiven}', 'Talks Given'),
                    Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.08)),
                    _metric(
                      profile.attendeesCount >= 1000
                          ? '${(profile.attendeesCount / 1000).toStringAsFixed(1)}k'
                          : '${profile.attendeesCount}',
                      'Attendees',
                    ),
                    Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.08)),
                    _metric(
                      profile.positivePercentage > 0
                          ? '${profile.positivePercentage.toStringAsFixed(0)}%'
                          : '—',
                      'Positive',
                    ),
                    Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.08)),
                    _metric(
                      profile.averageRating > 0
                          ? '${profile.averageRating.toStringAsFixed(1)} ★'
                          : '—',
                      'Avg Rating',
                      isGold: profile.averageRating > 0,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 4. Verifiable Webapp Badges Gained
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Earned Digital Badges',
                        style: AppTheme.font(
                          color: AppTheme.textPrimary,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (profile.badges.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E211A),
                            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Text(
                            '${profile.badges.length} Badges',
                            style: AppTheme.font(
                              color: const Color(0xFFCBD0C5),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    'Webapp Sync ✓',
                    style: AppTheme.font(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Horizontal Badges Carousel (or clean state if none yet)
              if (profile.badges.isNotEmpty)
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: profile.badges.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final badge = profile.badges[index];
                      return _badgeCard(context, badge);
                    },
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141710),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Center(
                    child: Text(
                      'No badges unlocked yet. Deliver talks at conferences to earn verified badges!',
                      textAlign: TextAlign.center,
                      style: AppTheme.font(
                        color: AppTheme.textMuted,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // 5. Speaker Biography Dropdown
              _ProfileDropdownSection(
                icon: Icons.menu_book_rounded,
                title: 'Speaker Biography',
                initiallyExpanded: false,
                trailingAction: GestureDetector(
                  onTap: () => context.push('/profile/edit'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E211A),
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      'Edit',
                      style: AppTheme.font(
                        color: const Color(0xFFCBD0C5),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                child: Text(
                  profile.biography.isNotEmpty
                      ? profile.biography
                      : 'No extended biography added yet. Tap Edit to add your speaking journey.',
                  style: AppTheme.font(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),

              // 6. Skills & Expertise Dropdown
              _ProfileDropdownSection(
                icon: Icons.psychology_outlined,
                title: 'Skills & Expertise',
                badge: profile.skills.isNotEmpty ? '${profile.skills.length}' : null,
                trailingAction: GestureDetector(
                  onTap: () => context.push('/profile/edit'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E211A),
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      'Edit',
                      style: AppTheme.font(
                        color: const Color(0xFFCBD0C5),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                child: profile.skills.isNotEmpty
                    ? Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profile.skills.map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E211A),
                              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Text(
                              skill,
                              style: AppTheme.font(
                                color: const Color(0xFFE2E5DC),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'No skills or topics listed yet. Tap Edit to showcase your expertise.',
                          style: AppTheme.font(color: AppTheme.textMuted, fontSize: 12.5),
                        ),
                      ),
              ),

              // 7. Contact & Public Links Dropdown
              _ProfileDropdownSection(
                icon: Icons.link_rounded,
                title: 'Contact & Public Links',
                badge: profile.socialLinks.isNotEmpty ? '${profile.socialLinks.length} links' : null,
                trailingAction: GestureDetector(
                  onTap: () => context.push('/profile/edit'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E211A),
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      'Edit',
                      style: AppTheme.font(
                        color: const Color(0xFFCBD0C5),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                child: profile.socialLinks.isNotEmpty
                    ? Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: profile.socialLinks.entries.map((entry) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E211A),
                              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.link_rounded,
                                  size: 13,
                                  color: AppTheme.primaryAccent,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  entry.key,
                                  style: AppTheme.font(
                                    color: const Color(0xFFE2E5DC),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'No public links added yet. Tap Edit to add your website and social handles.',
                          style: AppTheme.font(color: AppTheme.textMuted, fontSize: 12.5),
                        ),
                      ),
              ),

              // 8. Account Settings Dropdown
              _ProfileDropdownSection(
                icon: Icons.tune_rounded,
                title: 'Settings & Preferences',
                child: Column(
                  children: [
                    // Connected Account Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141710),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E221A),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: const Icon(
                              Icons.mail_outline_rounded,
                              color: Color(0xFFCBD0C5),
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.email.isNotEmpty
                                      ? profile.email
                                      : (ref.watch(storageServiceProvider).userEmail ?? 'Logged in Speaker'),
                                  style: AppTheme.font(
                                    color: AppTheme.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  ref.watch(storageServiceProvider).isGuest
                                      ? 'Guest Account (Fast Entry)'
                                      : 'Verified Account',
                                  style: AppTheme.font(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _settingsActionTile(
                      icon: Icons.edit_note_rounded,
                      title: 'Edit Profile & Details',
                      subtitle: 'Update name, organization, avatar & bio',
                      onTap: () => context.push('/profile/edit'),
                    ),
                    const SizedBox(height: 8),
                    _settingsActionTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Live Session Alerts',
                      subtitle: 'Audience reactions and poll notifications',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF1E211A),
                            content: Text(
                              'Live audience feedback alerts are enabled.',
                              style: AppTheme.font(color: Colors.white),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _settingsActionTile(
                      icon: Icons.policy_outlined,
                      title: 'Privacy Policy & Terms',
                      subtitle: 'SpeakWise security & data guidelines',
                      onTap: () => _showLegalDialog(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 9. Dedicated Log Out Action Pill
              GestureDetector(
                onTap: () => _confirmLogout(context, ref),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF221716), // Dark subtle ash-crimson
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    border: Border.all(
                      color: const Color(0xFFFF5252).withValues(alpha: 0.28),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFFF6B6B),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Log Out of SpeakWise',
                        style: AppTheme.font(
                          color: const Color(0xFFFF6B6B),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 10. App Build & Version Footer
              Center(
                child: Column(
                  children: [
                    Text(
                      'SpeakWise Mobile • v1.0.0 (Production Build)',
                      style: AppTheme.font(
                        color: AppTheme.textMuted.withValues(alpha: 0.65),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Turn talks into verified reputation.',
                      style: AppTheme.font(
                        color: AppTheme.textMuted.withValues(alpha: 0.4),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _metric(String value, String label, {bool isGold = false}) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.font(
            color: isGold ? AppTheme.starGold : AppTheme.textPrimary,
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: AppTheme.font(
            color: AppTheme.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _badgeCard(BuildContext context, SpeakerBadge badge) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF11130D),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(badge.emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  badge.title,
                  style: AppTheme.font(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  badge.tier,
                  style: AppTheme.font(
                    color: AppTheme.primaryAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  badge.description,
                  textAlign: TextAlign.center,
                  style: AppTheme.font(
                    color: AppTheme.textMuted,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryAccent,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Awesome',
                      style: AppTheme.font(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F110C),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(badge.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 6),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF20231C),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      badge.tier,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.font(
                        color: const Color(0xFFCBD0C5),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              badge.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.font(
                color: AppTheme.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              badge.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.font(
                color: AppTheme.textMuted,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF151811),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E211A),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Icon(icon, color: const Color(0xFFCBD0C5), size: 17),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.font(
                        color: AppTheme.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTheme.font(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppTheme.textMuted,
                size: 13,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141711),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252).withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFFF6B6B),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Log Out',
              style: AppTheme.font(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out of SpeakWise? You will need to sign in again to access your speaker talks and reputation.',
          style: AppTheme.font(
            color: AppTheme.textMuted,
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTheme.font(
                color: AppTheme.textMuted,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4D4D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authRemoteDataSourceProvider).logout();
              if (context.mounted) {
                context.go('/auth');
              }
            },
            child: Text(
              'Log Out',
              style: AppTheme.font(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLegalDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141711),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        title: Text(
          'Privacy & Security',
          style: AppTheme.font(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SpeakWise secures your speaker profile, talk telemetry, and audience reactions with end-to-end authentication and verifiable digital badge verification.',
                style: AppTheme.font(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '• No intrusive tracking\n• Real-time audience sentiment without selling personal data\n• Cloud-synchronized speaker portfolio',
                style: AppTheme.font(
                  color: const Color(0xFFCBD0C5),
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22261E),
              shape: const StadiumBorder(),
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: AppTheme.font(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// Smooth Collapsible / Dropdown Section Card for Profile
/// ═══════════════════════════════════════════════════════════════
class _ProfileDropdownSection extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? badge;
  final Widget child;
  final Widget? trailingAction;
  final bool initiallyExpanded;

  const _ProfileDropdownSection({
    required this.icon,
    required this.title,
    this.badge,
    required this.child,
    this.trailingAction,
    this.initiallyExpanded = false,
  });

  @override
  State<_ProfileDropdownSection> createState() => _ProfileDropdownSectionState();
}

class _ProfileDropdownSectionState extends State<_ProfileDropdownSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F110C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isExpanded
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _isExpanded
                              ? const Color(0xFF242820)
                              : const Color(0xFF1C1F18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Icon(
                          widget.icon,
                          color: _isExpanded ? Colors.white : AppTheme.textMuted,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              widget.title,
                              style: AppTheme.font(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (widget.badge != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                                ),
                                child: Text(
                                  widget.badge!,
                                  style: AppTheme.font(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (widget.trailingAction != null) ...[
                        widget.trailingAction!,
                        const SizedBox(width: 8),
                      ],
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.textMuted,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                    const SizedBox(height: 14),
                    widget.child,
                  ],
                ),
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
              sizeCurve: Curves.easeInOutCubic,
            ),
          ],
        ),
      ),
    );
  }
}
