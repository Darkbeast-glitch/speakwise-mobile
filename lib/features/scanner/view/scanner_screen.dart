import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/features/scanner/view/widgets/audience_feedback_sheet.dart';

/// ═══════════════════════════════════════════════════════════════
/// Screen 3: Instant QR Scanner (Hero Center Tab 2)
/// ═══════════════════════════════════════════════════════════════
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _isFlashOn = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frameSize = (MediaQuery.sizeOf(context).width * 0.72).clamp(240.0, 300.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Simulated Camera Viewfinder Layer
          Container(
            color: const Color(0xFF070908),
            child: Center(
              child: Opacity(
                opacity: 0.08,
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: 160,
                  color: AppTheme.primaryAccent,
                ),
              ),
            ),
          ),

          // 2. Viewfinder Target Frame
          Center(
            child: SizedBox(
              width: frameSize,
              height: frameSize,
              child: Stack(
                children: [
                  // Corner brackets
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ScannerBracketPainter(
                        bracketColor: AppTheme.primaryAccent,
                        bracketLength: 32,
                        strokeWidth: 3.5,
                      ),
                    ),
                  ),

                  // Animated Neon Laser Scan Line
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      return Positioned(
                        top: _animController.value * (frameSize - 4),
                        left: 12,
                        right: 12,
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppTheme.primaryAccent,
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryAccent.withValues(alpha: 0.7),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 3. Top Floating Controls
          Positioned(
            top: 56,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_2_rounded, color: AppTheme.primaryAccent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Talk QR Scanner',
                        style: AppTheme.font(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Flashlight Toggle
                GestureDetector(
                  onTap: () => setState(() => _isFlashOn = !_isFlashOn),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _isFlashOn ? AppTheme.primaryAccent : Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Icon(
                      _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      color: _isFlashOn ? AppTheme.textOnPrimary : AppTheme.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Instructions & Manual Fallback Button
          Positioned(
            bottom: 120, // above floating nav bar
            left: 24,
            right: 24,
            child: Column(
              children: [
                Text(
                  'Point camera at the slide QR code',
                  textAlign: TextAlign.center,
                  style: AppTheme.font(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Instant feedback in under 60 seconds',
                  style: AppTheme.font(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                // Manual Code Entry
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    AudienceFeedbackSheet.show(
                      context,
                      feedbackSlug: 'stellar-web3-cortex-2026',
                      topic: 'Architecting Scalable Web3 Backends on Stellar',
                      speaker: 'Julius Boakye',
                      event: 'Cortex DevFest 2026',
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pin_rounded, color: AppTheme.primaryAccent, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "Can't scan? Enter session code",
                          style: AppTheme.font(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
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
        ],
      ),
    );
  }
}

class _ScannerBracketPainter extends CustomPainter {
  final Color bracketColor;
  final double bracketLength;
  final double strokeWidth;

  const _ScannerBracketPainter({
    required this.bracketColor,
    required this.bracketLength,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = bracketColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const r = 16.0;

    // Top-Left Corner
    final tlPath = Path()
      ..moveTo(0, bracketLength)
      ..lineTo(0, r)
      ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
      ..lineTo(bracketLength, 0);
    canvas.drawPath(tlPath, paint);

    // Top-Right Corner
    final trPath = Path()
      ..moveTo(size.width - bracketLength, 0)
      ..lineTo(size.width - r, 0)
      ..arcToPoint(Offset(size.width, r), radius: const Radius.circular(r))
      ..lineTo(size.width, bracketLength);
    canvas.drawPath(trPath, paint);

    // Bottom-Left Corner
    final blPath = Path()
      ..moveTo(0, size.height - bracketLength)
      ..lineTo(0, size.height - r)
      ..arcToPoint(Offset(r, size.height), radius: const Radius.circular(r))
      ..lineTo(bracketLength, size.height);
    canvas.drawPath(blPath, paint);

    // Bottom-Right Corner
    final brPath = Path()
      ..moveTo(size.width - bracketLength, size.height)
      ..lineTo(size.width - r, size.height)
      ..arcToPoint(Offset(size.width, size.height - r), radius: const Radius.circular(r))
      ..lineTo(size.width, size.height - bracketLength);
    canvas.drawPath(brPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
