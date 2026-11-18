import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/core/widgets/user_avatar.dart';

/// ═══════════════════════════════════════════════════════════════
/// Explore Header Component
/// Left Avatar • Center "Welcome Back / User Name" • Right Bell
/// ═══════════════════════════════════════════════════════════════
class ExploreHeader extends StatelessWidget {
  final String userName;
  final String? avatarPath;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;

  const ExploreHeader({
    super.key,
    this.userName = 'Nana Acheampong',
    this.avatarPath,
    this.onNotificationTap,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. User Avatar with White Border
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onAvatarTap?.call();
            },
            child: UserAvatar(
              name: userName,
              avatarUrl: avatarPath,
              size: 46,
              showBorder: true,
              borderColor: Colors.white.withValues(alpha: 0.25),
            ),
          ),

          // 2. Centered "Welcome Back / User Name"
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Welcome Back',
                style: AppTheme.font(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                userName,
                style: AppTheme.font(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),

          // 3. Notification Bell Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onNotificationTap?.call();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: AppTheme.primaryAccent,
                    size: 22,
                  ),
                  Positioned(
                    top: 10,
                    right: 11,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF161616), width: 1.2),
                      ),
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
}
