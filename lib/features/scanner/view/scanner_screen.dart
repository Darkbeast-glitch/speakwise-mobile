import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/features/scanner/view/widgets/audience_feedback_sheet.dart';

/// ═══════════════════════════════════════════════════════════════
/// Screen 3: Live QR Scanner with Camera Viewfinder
/// Scans talk QR codes or web feedback URLs to open AudienceFeedbackSheet
/// ═══════════════════════════════════════════════════════════════
class ScannerScreen extends StatefulWidget {
  final bool isActive;

  const ScannerScreen({
    super.key,
    this.isActive = true,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _scannerController;
  late final AnimationController _animController;
  bool _isProcessingScan = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    if (widget.isActive) {
      _animController.repeat(reverse: true);
    }

    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      formats: const [BarcodeFormat.qrCode],
      autoStart: widget.isActive,
    );
  }

  @override
  void didUpdateWidget(ScannerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _scannerController.start();
        _animController.repeat(reverse: true);
      } else {
        _scannerController.stop();
        _animController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessingScan) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue?.trim();
    if (rawValue == null || rawValue.isEmpty) return;

    _isProcessingScan = true;
    HapticFeedback.heavyImpact();

    // Extract feedback slug from QR URL or plain string
    // e.g. "https://speak-wise.live/rate/stellar-talk-2026"
    // or "https://speakwise.live/talk/flutter-cicd/feedback"
    // or plain "stellar-talk-2026"
    String slug = rawValue;
    try {
      final uri = Uri.tryParse(rawValue);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        if (uri.pathSegments.contains('rate')) {
          final idx = uri.pathSegments.indexOf('rate');
          if (idx + 1 < uri.pathSegments.length) {
            slug = uri.pathSegments[idx + 1];
          } else {
            slug = uri.pathSegments.last;
          }
        } else if (uri.pathSegments.contains('talk')) {
          final idx = uri.pathSegments.indexOf('talk');
          if (idx + 1 < uri.pathSegments.length) {
            slug = uri.pathSegments[idx + 1];
          } else {
            slug = uri.pathSegments.last;
          }
        } else {
          slug = uri.pathSegments.last;
        }
      }
    } catch (_) {}

    AudienceFeedbackSheet.show(
      context,
      feedbackSlug: slug,
    ).then((_) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() => _isProcessingScan = false);
        }
      });
    });
  }

  void _showManualCodeDialog() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF141414),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: AppTheme.surfaceBorder, width: 1),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 18),
                Text(
                  'Enter Session Code',
                  style: AppTheme.font(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Type the speaker or session code shown on the presentation slide.',
                  style: AppTheme.font(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: AppTheme.font(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. flutter-cicd or stellar-2026',
                    hintStyle: AppTheme.font(
                      color: AppTheme.textMuted.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1C1D18),
                    prefixIcon: const Icon(
                      Icons.tag_rounded,
                      color: AppTheme.primaryAccent,
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.primaryAccent, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final code = controller.text.trim();
                      if (code.isEmpty) return;
                      Navigator.pop(ctx);
                      AudienceFeedbackSheet.show(
                        context,
                        feedbackSlug: code,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryAccent,
                      foregroundColor: AppTheme.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Open Session Feedback',
                      style: AppTheme.font(
                        fontSize: 14,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final frameSize = (MediaQuery.sizeOf(context).width * 0.72).clamp(240.0, 300.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Live Camera Hardware Scanner
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerController,
              fit: BoxFit.cover,
              errorBuilder: (context, error) {
                return Container(
                  color: const Color(0xFF070908),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 56,
                          color: AppTheme.textMuted.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Camera Access Needed',
                          style: AppTheme.font(
                            color: AppTheme.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please allow camera access in device settings to scan presentation QR codes.',
                          textAlign: TextAlign.center,
                          style: AppTheme.font(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              onDetect: _onDetect,
            ),
          ),

          // 2. Darkened Semi-transparent Vignette Overlay
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.45),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: frameSize,
                      height: frameSize,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Viewfinder Target Frame & Animated Neon Laser
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
                                color: AppTheme.primaryAccent.withValues(alpha: 0.8),
                                blurRadius: 10,
                                spreadRadius: 1.5,
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

          // 4. Top Floating Controls
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
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: AppTheme.primaryAccent,
                        size: 16,
                      ),
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

                // Action buttons: Torch & Camera flip
                Row(
                  children: [
                    // Flashlight Toggle
                    ValueListenableBuilder<MobileScannerState>(
                      valueListenable: _scannerController,
                      builder: (context, state, child) {
                        final isTorchOn = state.torchState == TorchState.on;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _scannerController.toggleTorch();
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isTorchOn
                                  ? AppTheme.primaryAccent
                                  : Colors.black.withValues(alpha: 0.65),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.surfaceBorder),
                            ),
                            child: Icon(
                              isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                              color: isTorchOn ? AppTheme.textOnPrimary : AppTheme.textPrimary,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    // Flip Camera
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _scannerController.switchCamera();
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.surfaceBorder),
                        ),
                        child: const Icon(
                          Icons.flip_camera_ios_rounded,
                          color: AppTheme.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 5. Instructions & Manual Fallback Button
          Positioned(
            bottom: 110, // above floating nav bar
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
                const SizedBox(height: 18),
                // Manual Code Entry
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showManualCodeDialog();
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
