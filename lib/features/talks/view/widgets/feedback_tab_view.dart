import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/core/widgets/app_shimmer.dart';
import 'package:speakwise_mobile/core/widgets/user_avatar.dart';
import 'package:speakwise_mobile/features/talks/data/models/talk_model.dart';
import 'package:speakwise_mobile/features/talks/viewmodel/talks_provider.dart';
import 'package:speakwise_mobile/features/talks/viewmodel/talks_state.dart';

/// ═══════════════════════════════════════════════════════════════
/// Feedback Tab View
/// Dimension Analysis Breakdown + Talk Filter + Attendee Reviews Stream
/// (Directly matching Webapp Dashboard in Image 2)
/// ═══════════════════════════════════════════════════════════════
class FeedbackTabView extends ConsumerWidget {
  const FeedbackTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final talksState = ref.watch(talksViewModelProvider);
    final analysis = talksState.dimensionAnalysis;
    final reviews = talksState.filteredReviews;
    final talks = talksState.talks;
    final selectedFilterId = talksState.selectedTalkFilterId;

    double prog(double score) => (score / 10.0).clamp(0.0, 1.0);
    String pct(double score) {
      if (score <= 0.0) return '0% (0.0/10)';
      return '${(prog(score) * 100).toStringAsFixed(0)}% (${score.toStringAsFixed(1)}/10)';
    }

    return RefreshIndicator(
      color: AppTheme.primaryAccent,
      backgroundColor: const Color(0xFF141611),
      onRefresh: () => ref.read(talksViewModelProvider.notifier).loadTalksData(force: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        children: [
          // 1. Dimension Analysis Breakdown (from Web Dashboard)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF0F110B),
              borderRadius: BorderRadius.circular(22),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dimension Analysis',
                          style: AppTheme.font(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedFilterId == 'all'
                              ? 'Feedback metrics breakdown • All Time'
                              : 'Filtered presentation metrics',
                          style: AppTheme.font(
                            color: AppTheme.textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: analysis.overallScore > 0
                            ? AppTheme.primaryAccent.withValues(alpha: 0.16)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      ),
                      child: Text(
                        analysis.overallScore > 0
                            ? '${(analysis.overallScore * 10).toStringAsFixed(0)}% Average'
                            : 'No Reviews',
                        style: AppTheme.font(
                          color: analysis.overallScore > 0
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

                // Overall Score Callout
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      analysis.overallScore.toStringAsFixed(1),
                      style: AppTheme.font(
                        color: AppTheme.textPrimary,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5, left: 4),
                      child: Text(
                        '/ 10 Overall Score',
                        style: AppTheme.font(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 4 Progress Bars matching live dimension breakdown
                _dimensionBar(
                  'Audience Engagement',
                  analysis.engagementScore,
                  prog(analysis.engagementScore),
                  pct(analysis.engagementScore),
                ),
                const SizedBox(height: 10),
                _dimensionBar(
                  'Speech Clarity',
                  analysis.clarityScore,
                  prog(analysis.clarityScore),
                  pct(analysis.clarityScore),
                ),
                const SizedBox(height: 10),
                _dimensionBar(
                  'Technical Depth',
                  analysis.technicalDepthScore,
                  prog(analysis.technicalDepthScore),
                  pct(analysis.technicalDepthScore),
                ),
                const SizedBox(height: 10),
                _dimensionBar(
                  'Practical Relevance',
                  analysis.practicalRelevanceScore,
                  prog(analysis.practicalRelevanceScore),
                  pct(analysis.practicalRelevanceScore),
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),

        // 2. Filter by Talk Horizontal Pills
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Filter by Talk',
              style: AppTheme.font(
                color: AppTheme.textPrimary,
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (selectedFilterId != 'all')
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(talksViewModelProvider.notifier).setFilterTalkId('all');
                },
                child: Text(
                  'Reset filter',
                  style: AppTheme.font(
                    color: AppTheme.primaryAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 10),

        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _filterChip(
                ref: ref,
                id: 'all',
                label: 'All Talks (${talksState.allReviews.length})',
                isSelected: selectedFilterId == 'all',
              ),
              ...talks.map((talk) {
                final shortTitle = talk.title.length > 28
                    ? '${talk.title.substring(0, 26)}...'
                    : talk.title;
                return _filterChip(
                  ref: ref,
                  id: talk.id,
                  label: shortTitle,
                  isSelected: selectedFilterId == talk.id,
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 3. Recent Feedback Stream Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Attendee Reviews & Ratings',
              style: AppTheme.font(
                color: AppTheme.textPrimary,
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              '${reviews.length} reviews',
              style: AppTheme.font(
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Feedback Review Cards List
        if (talksState.status == TalksStatus.loading && reviews.isEmpty)
          const FeedbackListShimmer()
        else if (talksState.status == TalksStatus.error && reviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F110B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.errorRed.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppTheme.errorRed, size: 36),
                const SizedBox(height: 12),
                Text(
                  'Could not load feedback reviews',
                  style: AppTheme.font(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  talksState.errorMessage ?? 'Please check your connection.',
                  textAlign: TextAlign.center,
                  style: AppTheme.font(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () => ref
                      .read(talksViewModelProvider.notifier)
                      .loadTalksData(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAccent,
                    foregroundColor: Colors.black,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          )
        else if (reviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF0F110B),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              'No feedback reviews found for this talk yet.',
              style: AppTheme.font(color: AppTheme.textMuted, fontSize: 13),
            ),
          )
        else
          ...reviews.map((rev) => _buildReviewCard(rev)),
      ],
    ),
  );
}

  Widget _filterChip({
    required WidgetRef ref,
    required String id,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(talksViewModelProvider.notifier).setFilterTalkId(id);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryAccent : const Color(0xFF141611),
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryAccent
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTheme.font(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _dimensionBar(String label, double score, double progress, String percentLabel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTheme.font(
                color: AppTheme.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              percentLabel,
              style: AppTheme.font(
                color: AppTheme.primaryAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: const Color(0xFF1C1E18),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(FeedbackReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F110B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attendee Header Row
          Row(
            children: [
              UserAvatar(
                name: review.attendeeName,
                avatarUrl: review.attendeeAvatar,
                size: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.attendeeName,
                      style: AppTheme.font(
                        color: AppTheme.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${review.talkTitle} • ${review.timeAgo}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.font(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Score Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  border: Border.all(
                    color: AppTheme.primaryAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppTheme.starGold, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${review.score}/10',
                      style: AppTheme.font(
                        color: AppTheme.primaryAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Written Comment
          Text(
            review.comment,
            style: AppTheme.font(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 13,
              height: 1.42,
            ),
          ),

          const SizedBox(height: 10),

          // Sentiment Tags
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: review.sentimentTags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF161812),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Text(
                  '# $tag',
                  style: AppTheme.font(
                    color: AppTheme.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
