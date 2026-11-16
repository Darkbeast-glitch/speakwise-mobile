import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/features/talks/data/models/talk_model.dart';

/// ═══════════════════════════════════════════════════════════════
/// Feedback Metrics Donut / Pie Chart
/// Visualizes Rating Distribution & Dimension Balance
/// ═══════════════════════════════════════════════════════════════
class FeedbackMetricsPieChart extends StatefulWidget {
  final DimensionAnalysis analysis;
  final List<FeedbackReview> reviews;

  const FeedbackMetricsPieChart({
    super.key,
    required this.analysis,
    required this.reviews,
  });

  @override
  State<FeedbackMetricsPieChart> createState() => _FeedbackMetricsPieChartState();
}

class _FeedbackMetricsPieChartState extends State<FeedbackMetricsPieChart> {
  // 0 = Dimension Balance, 1 = Score Distribution
  int _chartMode = 0;

  @override
  Widget build(BuildContext context) {
    final hasReviews = widget.reviews.isNotEmpty;
    final hasMetrics = widget.analysis.overallScore > 0 || hasReviews;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F110B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pie_chart_rounded,
                      color: AppTheme.primaryAccent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Feedback Breakdown',
                        style: AppTheme.font(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        _chartMode == 0 ? 'Dimension balance' : 'Rating tiers',
                        style: AppTheme.font(
                          color: AppTheme.textMuted,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Segmented Toggle Pill
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161811),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _modeButton(label: 'Dimensions', modeIndex: 0),
                    _modeButton(label: 'Ratings', modeIndex: 1),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (!hasMetrics) ...[
            // Empty State
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: CustomPaint(
                        painter: _EmptyDonutPainter(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No reviews collected yet',
                      style: AppTheme.font(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Present your feedback QR code during sessions to populate chart metrics.',
                      textAlign: TextAlign.center,
                      style: AppTheme.font(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Chart Visualization + Legend
            _buildChartContent(),
          ],
        ],
      ),
    );
  }

  Widget _modeButton({required String label, required int modeIndex}) {
    final isSelected = _chartMode == modeIndex;
    return GestureDetector(
      onTap: () {
        if (_chartMode != modeIndex) {
          HapticFeedback.selectionClick();
          setState(() => _chartMode = modeIndex);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
        child: Text(
          label,
          style: AppTheme.font(
            color: isSelected ? Colors.black : AppTheme.textMuted,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildChartContent() {
    final List<_ChartSegment> segments = _chartMode == 0
        ? _buildDimensionSegments()
        : _buildRatingSegments();

    final centerValue = _chartMode == 0
        ? widget.analysis.overallScore.toStringAsFixed(1)
        : '${widget.reviews.length}';
    final centerLabel = _chartMode == 0 ? '/ 10 Avg' : 'Reviews';

    return Column(
      children: [
        // Donut Chart with Center Callout
        Center(
          child: SizedBox(
            width: 190,
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(190, 190),
                  painter: _DonutChartPainter(segments: segments),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      centerValue,
                      style: AppTheme.font(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      centerLabel,
                      style: AppTheme.font(
                        color: AppTheme.textMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Legend Breakdown Chips
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: segments.map((seg) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF141610),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: seg.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    seg.label,
                    style: AppTheme.font(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    seg.sublabel,
                    style: AppTheme.font(
                      color: AppTheme.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<_ChartSegment> _buildDimensionSegments() {
    final a = widget.analysis;
    final total = (a.engagementScore +
            a.clarityScore +
            a.technicalDepthScore +
            a.practicalRelevanceScore)
        .clamp(0.1, 1000.0);

    return [
      _ChartSegment(
        label: 'Engagement',
        sublabel: '${((a.engagementScore / total) * 100).toStringAsFixed(0)}% (${a.engagementScore.toStringAsFixed(1)})',
        value: a.engagementScore > 0 ? a.engagementScore : 0.1,
        color: const Color(0xFFC6FF00), // Neon Lime
      ),
      _ChartSegment(
        label: 'Clarity',
        sublabel: '${((a.clarityScore / total) * 100).toStringAsFixed(0)}% (${a.clarityScore.toStringAsFixed(1)})',
        value: a.clarityScore > 0 ? a.clarityScore : 0.1,
        color: const Color(0xFF00E5FF), // Electric Cyan
      ),
      _ChartSegment(
        label: 'Tech Depth',
        sublabel: '${((a.technicalDepthScore / total) * 100).toStringAsFixed(0)}% (${a.technicalDepthScore.toStringAsFixed(1)})',
        value: a.technicalDepthScore > 0 ? a.technicalDepthScore : 0.1,
        color: const Color(0xFF9D4EDD), // Electric Purple
      ),
      _ChartSegment(
        label: 'Practical',
        sublabel: '${((a.practicalRelevanceScore / total) * 100).toStringAsFixed(0)}% (${a.practicalRelevanceScore.toStringAsFixed(1)})',
        value: a.practicalRelevanceScore > 0 ? a.practicalRelevanceScore : 0.1,
        color: const Color(0xFFFFAB00), // Amber Gold
      ),
    ];
  }

  List<_ChartSegment> _buildRatingSegments() {
    int outstanding = 0; // 9.0 - 10
    int veryGood = 0; // 7.0 - 8.9
    int average = 0; // 5.0 - 6.9
    int needsWork = 0; // < 5.0

    for (final r in widget.reviews) {
      if (r.score >= 9.0) {
        outstanding++;
      } else if (r.score >= 7.0) {
        veryGood++;
      } else if (r.score >= 5.0) {
        average++;
      } else {
        needsWork++;
      }
    }

    final totalReviews = widget.reviews.length;
    if (totalReviews == 0) {
      return [
        _ChartSegment(
          label: 'No reviews',
          sublabel: '0%',
          value: 1.0,
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ];
    }

    String pct(int count) =>
        '${((count / totalReviews) * 100).toStringAsFixed(0)}% ($count)';

    return [
      if (outstanding > 0 || totalReviews > 0)
        _ChartSegment(
          label: '9–10 ★',
          sublabel: pct(outstanding),
          value: outstanding.toDouble() > 0 ? outstanding.toDouble() : 0.05,
          color: const Color(0xFFC6FF00), // Neon Lime
        ),
      if (veryGood > 0 || totalReviews > 0)
        _ChartSegment(
          label: '7–8.9 ★',
          sublabel: pct(veryGood),
          value: veryGood.toDouble() > 0 ? veryGood.toDouble() : 0.05,
          color: const Color(0xFF00E676), // Emerald Green
        ),
      if (average > 0 || totalReviews > 0)
        _ChartSegment(
          label: '5–6.9 ★',
          sublabel: pct(average),
          value: average.toDouble() > 0 ? average.toDouble() : 0.05,
          color: const Color(0xFFFFD600), // Yellow Gold
        ),
      if (needsWork > 0)
        _ChartSegment(
          label: '< 5 ★',
          sublabel: pct(needsWork),
          value: needsWork.toDouble(),
          color: const Color(0xFFFF5252), // Coral Red
        ),
    ];
  }
}

class _ChartSegment {
  final String label;
  final String sublabel;
  final double value;
  final Color color;

  const _ChartSegment({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.color,
  });
}

class _DonutChartPainter extends CustomPainter {
  final List<_ChartSegment> segments;

  _DonutChartPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 24.0;
    final arcRadius = radius - strokeWidth / 2;

    final total = segments.fold<double>(0.0, (acc, s) => acc + s.value);
    if (total <= 0) return;

    double startAngle = -math.pi / 2;
    const gapAngle = 0.06; // subtle gap between segments

    final totalGap = gapAngle * segments.length;
    final availableAngle = (2 * math.pi) - totalGap;

    for (final seg in segments) {
      final sweepAngle = (seg.value / total) * availableAngle;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      if (sweepAngle > 0.01) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: arcRadius),
          startAngle,
          sweepAngle,
          false,
          paint,
        );
      }
      startAngle += sweepAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.segments != segments;
  }
}

class _EmptyDonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

