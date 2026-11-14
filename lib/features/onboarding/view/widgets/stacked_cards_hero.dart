import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:speakwise_mobile/app/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// Stacked Cards Hero Component
/// 3-Card 3D Tilted Perspective matching the design reference
/// ═══════════════════════════════════════════════════════════════
class StackedCardsHero extends StatelessWidget {
  final String centerImagePath;
  final String leftImagePath;
  final String rightImagePath;

  const StackedCardsHero({
    super.key,
    required this.centerImagePath,
    required this.leftImagePath,
    required this.rightImagePath,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final cardHeight = (size.height * 0.28).clamp(160.0, 240.0);
    final cardWidth = cardHeight / 1.32;

    return SizedBox(
      height: cardHeight + 36,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. Left Tilted Card (Tilted Counter-Clockwise ~ -9°)
          Transform.translate(
            offset: Offset(-cardWidth * 0.28, 10),
            child: Transform.rotate(
              angle: -9.0 * math.pi / 180,
              child: _TiltedPhotoCard(
                imagePath: leftImagePath,
                width: cardWidth * 0.92,
                height: cardHeight * 0.92,
                opacity: 0.82,
                isForeground: false,
              ),
            ),
          ),

          // 2. Right Tilted Card (Tilted Clockwise ~ +9°)
          Transform.translate(
            offset: Offset(cardWidth * 0.28, 12),
            child: Transform.rotate(
              angle: 9.0 * math.pi / 180,
              child: _TiltedPhotoCard(
                imagePath: rightImagePath,
                width: cardWidth * 0.92,
                height: cardHeight * 0.92,
                opacity: 0.82,
                isForeground: false,
              ),
            ),
          ),

          // 3. Center Foreground Card (Straight, Elevated, Crisp)
          Transform.translate(
            offset: const Offset(0, 0),
            child: _TiltedPhotoCard(
              imagePath: centerImagePath,
              width: cardWidth,
              height: cardHeight,
              opacity: 1.0,
              isForeground: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _TiltedPhotoCard extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;
  final double opacity;
  final bool isForeground;

  const _TiltedPhotoCard({
    required this.imagePath,
    required this.width,
    required this.height,
    required this.opacity,
    required this.isForeground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(isForeground ? 22 : 18),
        border: Border.all(
          color: isForeground
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.08),
          width: isForeground ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isForeground ? 0.65 : 0.4),
            blurRadius: isForeground ? 28 : 16,
            offset: Offset(0, isForeground ? 16 : 8),
          ),
          if (isForeground)
            BoxShadow(
              color: AppTheme.primaryAccent.withValues(alpha: 0.06),
              blurRadius: 36,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isForeground ? 21 : 17),
        child: Opacity(
          opacity: opacity,
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Graceful dark fallback container with speaker icon
              return Container(
                color: const Color(0xFF161914),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mic_external_on_rounded,
                        color: AppTheme.primaryAccent.withValues(alpha: 0.6),
                        size: 36,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'SpeakWise',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
