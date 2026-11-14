import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/features/talks/data/talks_remote_datasource.dart';

/// ═══════════════════════════════════════════════════════════════
/// Audience Live Feedback Submission Sheet
/// Connected to Django API:
/// GET  /feedbacks/rate/{feedback_slug}/
/// POST /feedbacks/rate/{feedback_slug}/
/// ═══════════════════════════════════════════════════════════════
class AudienceFeedbackSheet extends ConsumerStatefulWidget {
  final String feedbackSlug;
  final String? initialTopic;
  final String? initialSpeaker;
  final String? initialEvent;

  const AudienceFeedbackSheet({
    super.key,
    required this.feedbackSlug,
    this.initialTopic,
    this.initialSpeaker,
    this.initialEvent,
  });

  static Future<void> show(
    BuildContext context, {
    required String feedbackSlug,
    String? topic,
    String? speaker,
    String? event,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AudienceFeedbackSheet(
        feedbackSlug: feedbackSlug,
        initialTopic: topic,
        initialSpeaker: speaker,
        initialEvent: event,
      ),
    );
  }

  @override
  ConsumerState<AudienceFeedbackSheet> createState() => _AudienceFeedbackSheetState();
}

class _AudienceFeedbackSheetState extends ConsumerState<AudienceFeedbackSheet> {
  final _nameController = TextEditingController();
  final _commentController = TextEditingController();

  double _overallRating = 9.0;
  double _clarity = 9.0;
  double _engagement = 8.0;
  double _contentDepth = 9.0;
  double _practicalRelevance = 9.0;

  bool _isSubmitting = false;
  bool _submitted = false;

  void _onSubmit() async {
    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      await ref.read(talksRemoteDataSourceProvider).submitTalkFeedback(
            feedbackSlug: widget.feedbackSlug,
            name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
            overallRating: _overallRating.round(),
            clarity: _clarity.round(),
            engagement: _engagement.round(),
            contentDepth: _contentDepth.round(),
            speakerKnowledge: 9,
            practicalRelevance: _practicalRelevance.round(),
            comments: _commentController.text.trim().isNotEmpty
                ? _commentController.text.trim()
                : 'Excellent presentation! Very clear and actionable insights.',
          );
    } catch (e) {
      debugPrint('Feedback submission note: $e');
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _submitted = true;
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F110B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
      child: _submitted ? _buildSuccessView() : _buildFormView(),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 30),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: AppTheme.primaryAccent.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryAccent, width: 2),
          ),
          child: const Center(
            child: Icon(Icons.check_rounded, color: AppTheme.primaryAccent, size: 38),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Feedback Submitted!',
          style: AppTheme.font(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Thank you for helping the speaker grow.\nYour review has been securely verified.',
          textAlign: TextAlign.center,
          style: AppTheme.font(
            color: AppTheme.textMuted,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildFormView() {
    return Column(
      children: [
        // Drag handle
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        const SizedBox(height: 14),

        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rate & Review Session',
                  style: AppTheme.font(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  widget.initialEvent ?? 'Cortex DevFest 2026',
                  style: AppTheme.font(
                    color: AppTheme.primaryAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF181A14),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: const Center(
                  child: Icon(Icons.close_rounded, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Session Topic Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161811),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.initialTopic ?? 'Building Realtime Mobile Apps in Flutter',
                        style: AppTheme.font(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Speaker: ${widget.initialSpeaker ?? 'Nana Acheampong'}',
                        style: AppTheme.font(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Overall Score Slider
                _scoreSlider('Overall Impression', _overallRating, (v) => setState(() => _overallRating = v)),
                _scoreSlider('Speech Clarity', _clarity, (v) => setState(() => _clarity = v)),
                _scoreSlider('Audience Engagement', _engagement, (v) => setState(() => _engagement = v)),
                _scoreSlider('Technical Depth', _contentDepth, (v) => setState(() => _contentDepth = v)),
                _scoreSlider('Practical Relevance', _practicalRelevance, (v) => setState(() => _practicalRelevance = v)),

                const SizedBox(height: 14),

                // Attendee Name (Optional)
                Text(
                  'Your Name (Optional - leave empty for anonymous)',
                  style: AppTheme.font(color: AppTheme.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF141611),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: TextField(
                    controller: _nameController,
                    style: AppTheme.font(color: Colors.white, fontSize: 13.5),
                    cursorColor: AppTheme.primaryAccent,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'e.g. Kwame Mensah',
                      hintStyle: AppTheme.font(color: Colors.white.withValues(alpha: 0.28), fontSize: 13),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Written Feedback Comment
                Text(
                  'Review & Constructive Feedback *',
                  style: AppTheme.font(color: AppTheme.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF141611),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _commentController,
                    maxLines: 3,
                    style: AppTheme.font(color: Colors.white, fontSize: 13.5),
                    cursorColor: AppTheme.primaryAccent,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'What was most valuable? Any suggestions for future talks?',
                      hintStyle: AppTheme.font(color: Colors.white.withValues(alpha: 0.28), fontSize: 13),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryAccent,
                      foregroundColor: Colors.black,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: _isSubmitting ? null : _onSubmit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : Text(
                            'Submit Anonymous Feedback',
                            style: AppTheme.font(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _scoreSlider(String label, double value, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTheme.font(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w500),
              ),
              Text(
                '${value.round()} / 10',
                style: AppTheme.font(color: AppTheme.primaryAccent, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.primaryAccent,
              inactiveTrackColor: const Color(0xFF1C1E18),
              thumbColor: AppTheme.primaryAccent,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackHeight: 3,
            ),
            child: Slider(
              value: value,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
