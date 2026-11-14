import 'package:flutter/material.dart';
import 'package:speakwise_mobile/app/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// Ambient Top Glow (Radial Neon Bloom Backdrop)
/// ═══════════════════════════════════════════════════════════════
class AmbientGlow extends StatelessWidget {
  final Widget? child;
  final double glowOpacity;
  final Alignment glowAlignment;
  final double radius;

  const AmbientGlow({
    super.key,
    this.child,
    this.glowOpacity = 0.22,
    this.glowAlignment = const Alignment(0.0, -0.55),
    this.radius = 0.85,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: glowAlignment,
                radius: radius,
                colors: [
                  AppTheme.primaryAccent.withValues(alpha: glowOpacity),
                  AppTheme.primaryAccent.withValues(alpha: glowOpacity * 0.4),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),
        ?child,
      ],
    );
  }
}
