import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/core/widgets/app_shimmer.dart';
import 'package:speakwise_mobile/core/widgets/user_avatar.dart';
import 'package:speakwise_mobile/features/talks/data/models/talk_model.dart';
import 'package:speakwise_mobile/features/talks/view/widgets/feedback_pie_chart.dart';
import 'package:speakwise_mobile/features/talks/viewmodel/talks_provider.dart';
import 'package:speakwise_mobile/features/talks/viewmodel/talks_state.dart';

/// ═══════════════════════════════════════════════════════════════
/// Feedback Tab View
/// Dimension Analysis Breakdown + Donut Pie Chart + Searchable Talk Filter + Attendee Reviews Stream
/// (Directly matching Webapp Dashboard in Image 2)
/// ═══════════════════════════════════════════════════════════════
class FeedbackTabView extends ConsumerStatefulWidget {
  const FeedbackTabView({super.key});

  @override
  ConsumerState<FeedbackTabView> createState() => _FeedbackTabViewState();
}

class _FeedbackTabViewState extends ConsumerState<FeedbackTabView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final talksState = ref.watch(talksViewModelProvider);
    final analysis = talksState.dimensionAnalysis;
    final reviews = talksState.filteredReviews;
    final talks = talksState.talks;
    final selectedFilterId = talksState.selectedTalkFilterId;

    // Filter talks list by search query
    final filteredTalks = talks.where((t) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      return t.title.toLowerCase().contains(q) ||
          t.eventName.toLowerCase().contains(q);
    }).toList();

    final selectedTalk = selectedFilterId != 'all'
        ? talks.cast<SpeakingTalk?>().firstWhere(
            (t) => t?.id == selectedFilterId,
            orElse: () => null,
          )
        : null;

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

          const SizedBox(height: 16),

          // 2. Feedback Metrics Pie / Donut Chart
          FeedbackMetricsPieChart(
            analysis: analysis,
            reviews: reviews,
          ),

          const SizedBox(height: 20),

          // 3. Filter by Talk Section with Search Input
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Filter by Talk',
                    style: AppTheme.font(
                      color: AppTheme.textPrimary,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                    child: Text(
                      '${talks.length} sessions',
                      style: AppTheme.font(
                        color: AppTheme.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
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

          // Search Field for Talk (instant typing filter for 100+ talks)
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0F110B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.09),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(
                  Icons.search_rounded,
                  color: AppTheme.textMuted,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: AppTheme.font(color: Colors.white, fontSize: 13),
                    cursorColor: AppTheme.primaryAccent,
                    decoration: InputDecoration(
                      hintText: 'Search talk by topic or event...',
                      hintStyle: AppTheme.font(color: AppTheme.textMuted, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 17,
                      ),
                    ),
                  ),
                // Full bottom sheet talk picker button
                GestureDetector(
                  onTap: () => _showTalkPickerBottomSheet(context, talks, selectedFilterId),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161811),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.format_list_bulleted_rounded,
                            color: AppTheme.primaryAccent, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Browse',
                          style: AppTheme.font(
                            color: AppTheme.primaryAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Active Selected Talk Callout Pill
          if (selectedTalk != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt_rounded, color: AppTheme.primaryAccent, size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filtered: ${selectedTalk.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.font(
                        color: AppTheme.primaryAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(talksViewModelProvider.notifier).setFilterTalkId('all');
                    },
                    child: const Icon(Icons.close_rounded, color: AppTheme.primaryAccent, size: 16),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Horizontal Filter Chips (dynamically filtered by search)
          SizedBox(
            height: 38,
            child: filteredTalks.isEmpty && _searchQuery.isNotEmpty
                ? Center(
                    child: Text(
                      'No talks matching "$_searchQuery"',
                      style: AppTheme.font(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      if (_searchQuery.isEmpty)
                        _filterChip(
                          ref: ref,
                          id: 'all',
                          label: 'All Talks (${talksState.allReviews.length})',
                          isSelected: selectedFilterId == 'all',
                        ),
                      ...filteredTalks.map((talk) {
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

          // 4. Recent Feedback Stream Header
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

  void _showTalkPickerBottomSheet(
    BuildContext context,
    List<SpeakingTalk> talks,
    String selectedFilterId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String sheetSearch = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = talks.where((t) {
              if (sheetSearch.trim().isEmpty) return true;
              final q = sheetSearch.trim().toLowerCase();
              return t.title.toLowerCase().contains(q) ||
                  t.eventName.toLowerCase().contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Color(0xFF0F110B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewPadding.bottom + 16,
              ),
              child: Column(
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Talk to Filter',
                        style: AppTheme.font(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search Input in Sheet
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF161811),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            style: AppTheme.font(color: Colors.white, fontSize: 13),
                            cursorColor: AppTheme.primaryAccent,
                            decoration: InputDecoration(
                              hintText: 'Search through all ${talks.length} talks...',
                              hintStyle: AppTheme.font(color: AppTheme.textMuted, fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (val) {
                              setSheetState(() => sheetSearch = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Option: All Talks
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    tileColor: selectedFilterId == 'all'
                        ? AppTheme.primaryAccent.withValues(alpha: 0.12)
                        : const Color(0xFF141610),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selectedFilterId == 'all'
                            ? AppTheme.primaryAccent
                            : Colors.white.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.all_inclusive_rounded,
                        color: selectedFilterId == 'all' ? Colors.black : Colors.white,
                        size: 16,
                      ),
                    ),
                    title: Text(
                      'All Talks & Reviews',
                      style: AppTheme.font(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Aggregated metrics across all presentations',
                      style: AppTheme.font(color: AppTheme.textMuted, fontSize: 11.5),
                    ),
                    trailing: selectedFilterId == 'all'
                        ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryAccent, size: 20)
                        : null,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(talksViewModelProvider.notifier).setFilterTalkId('all');
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: 10),
                  // List of Talks
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'No talks found',
                              style: AppTheme.font(color: AppTheme.textMuted),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final talk = filtered[index];
                              final isSelected = selectedFilterId == talk.id;
                              return ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppTheme.primaryAccent.withValues(alpha: 0.5)
                                        : Colors.white.withValues(alpha: 0.05),
                                  ),
                                ),
                                tileColor: isSelected
                                    ? AppTheme.primaryAccent.withValues(alpha: 0.1)
                                    : const Color(0xFF141610),
                                title: Text(
                                  talk.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.font(
                                    color: Colors.white,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    fontSize: 13.5,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Text(
                                        talk.eventName,
                                        style: AppTheme.font(
                                          color: AppTheme.primaryAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '• ${talk.eventDate}',
                                        style: AppTheme.font(
                                          color: AppTheme.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle_rounded,
                                        color: AppTheme.primaryAccent, size: 20)
                                    : const Icon(Icons.chevron_right_rounded,
                                        color: AppTheme.textMuted, size: 20),
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  ref.read(talksViewModelProvider.notifier).setFilterTalkId(talk.id);
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
