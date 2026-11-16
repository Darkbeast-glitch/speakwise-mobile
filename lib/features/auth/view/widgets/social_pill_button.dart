import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speakwise_mobile/app/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// Light Gray Social Pill Button (Apple / Google)
/// ═══════════════════════════════════════════════════════════════
class SocialPillButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final bool enabled;

  const SocialPillButton({
    super.key,
    required this.icon,
    this.onTap,
    this.enabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 48,
        child: Material(
          color: enabled
              ? const Color(0xFFDCDCDC)
              : const Color(0xFFDCDCDC).withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            onTap: () {
              HapticFeedback.lightImpact();
              if (onTap != null) {
                onTap!();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Social sign-in is currently disabled. Please sign in with email.',
                      style: AppTheme.font(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: const Color(0xFF1E1F24),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            child: Opacity(
              opacity: enabled ? 1.0 : 0.45,
              child: Center(
                child: icon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// Vector GitHub Mark
/// ═══════════════════════════════════════════════════════════════
class GithubLogo extends StatelessWidget {
  final double size;
  final Color color;

  const GithubLogo({
    super.key,
    this.size = 22,
    this.color = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GithubLogoPainter(color: color),
      ),
    );
  }
}

class _GithubLogoPainter extends CustomPainter {
  final Color color;

  _GithubLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final scale = size.width / 24.0;
    canvas.scale(scale, scale);

    final path = Path();
    path.moveTo(12, 0);
    path.cubicTo(5.37, 0, 0, 5.37, 0, 12);
    path.cubicTo(0, 17.31, 3.435, 21.795, 8.205, 23.385);
    path.cubicTo(8.805, 23.49, 9.03, 23.13, 9.03, 22.815);
    path.cubicTo(9.03, 22.53, 9.015, 21.585, 9.015, 20.58);
    path.cubicTo(6, 21.135, 5.22, 19.845, 4.98, 19.17);
    path.cubicTo(4.845, 18.825, 4.26, 17.76, 3.75, 17.475);
    path.cubicTo(3.33, 17.25, 2.73, 16.695, 3.735, 16.68);
    path.cubicTo(4.68, 16.665, 5.355, 17.55, 5.58, 17.91);
    path.cubicTo(6.66, 19.725, 8.385, 19.215, 9.075, 18.9);
    path.cubicTo(9.18, 18.12, 9.495, 17.595, 9.84, 17.295);
    path.cubicTo(7.17, 16.995, 4.38, 15.96, 4.38, 11.37);
    path.cubicTo(4.38, 10.065, 4.845, 8.985, 5.61, 8.145);
    path.cubicTo(5.49, 7.845, 5.07, 6.615, 5.73, 4.965);
    path.cubicTo(5.73, 4.965, 6.735, 4.65, 9.03, 6.195);
    path.cubicTo(9.99, 5.925, 11.01, 5.79, 12.03, 5.79);
    path.cubicTo(13.05, 5.79, 14.07, 5.925, 15.03, 6.195);
    path.cubicTo(17.325, 4.635, 18.33, 4.965, 18.33, 4.965);
    path.cubicTo(18.99, 6.615, 18.57, 7.845, 18.45, 8.145);
    path.cubicTo(19.215, 8.985, 19.68, 10.05, 19.68, 11.37);
    path.cubicTo(19.68, 15.975, 16.875, 16.995, 14.205, 17.295);
    path.cubicTo(14.64, 17.67, 15.015, 18.39, 15.015, 19.515);
    path.cubicTo(15.015, 21.12, 15.0, 22.41, 15.0, 22.815);
    path.cubicTo(15.0, 23.13, 15.225, 23.505, 15.825, 23.385);
    path.cubicTo(20.595, 21.795, 24.03, 17.31, 24.03, 12);
    path.cubicTo(24.03, 5.37, 18.66, 0, 12, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GithubLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}
