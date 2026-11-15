import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/core/widgets/app_network_image.dart';
import 'package:speakwise_mobile/features/explore/data/events_repository.dart';
import 'package:speakwise_mobile/features/explore/data/models/event_model.dart';

/// ═══════════════════════════════════════════════════════════════
/// Screen: All Keynote Speakers Directory Screen
/// Features:
/// - Real-time keyword search (name, role, topic)
/// - Flexible Bayesian ordering filters (Top Rated, Most Talks, Reputation, Rating, Followers)
/// - Infinite scroll pagination
/// - Premium card spotlight layout matching the SpeakWise design
/// ═══════════════════════════════════════════════════════════════
class AllSpeakersScreen extends ConsumerStatefulWidget {
  final String? initialFilter;

  const AllSpeakersScreen({super.key, this.initialFilter});

  @override
  ConsumerState<AllSpeakersScreen> createState() => _AllSpeakersScreenState();
}

class _AllSpeakersScreenState extends ConsumerState<AllSpeakersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  List<EventSpeaker> _speakers = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 20;

  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<Map<String, String>> _filterOptions = const [
    {'label': 'All', 'ordering': '', 'top': 'false'},
    {'label': 'Top Rated', 'ordering': '', 'top': 'true'},
    {'label': 'Most Talks', 'ordering': '-talks_count', 'top': 'false'},
    {'label': 'Reputation', 'ordering': '-reputation', 'top': 'false'},
    {'label': 'Highest Rating', 'ordering': '-rating', 'top': 'false'},
    {'label': 'Most Followers', 'ordering': '-followers', 'top': 'false'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null && widget.initialFilter!.isNotEmpty) {
      _selectedFilter = widget.initialFilter!;
    }
    _scrollController.addListener(_onScroll);
    _loadSpeakers(reset: true);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _loadMoreSpeakers();
      }
    }
  }

  Map<String, String> get _currentFilterConfig {
    return _filterOptions.firstWhere(
      (opt) => opt['label'] == _selectedFilter,
      orElse: () => _filterOptions.first,
    );
  }

  Future<void> _loadSpeakers({bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _isLoading = true;
      });
    }

    try {
      final repo = ref.read(eventsRepositoryProvider);
      final cfg = _currentFilterConfig;
      final isTop = cfg['top'] == 'true';
      final ordering = cfg['ordering']?.isNotEmpty == true
          ? cfg['ordering']
          : null;

      final results = await repo.getSpeakers(
        top: isTop ? true : null,
        ordering: ordering,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        page: 1,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          _speakers = results;
          _hasMore = results.length >= _pageSize;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _speakers = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreSpeakers() async {
    setState(() => _isLoadingMore = true);
    final nextPage = _currentPage + 1;

    try {
      final repo = ref.read(eventsRepositoryProvider);
      final cfg = _currentFilterConfig;
      final isTop = cfg['top'] == 'true';
      final ordering = cfg['ordering']?.isNotEmpty == true
          ? cfg['ordering']
          : null;

      final results = await repo.getSpeakers(
        top: isTop ? true : null,
        ordering: ordering,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        page: nextPage,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          _currentPage = nextPage;
          _speakers.addAll(results);
          _hasMore = results.length >= _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onSearchChanged(String val) {
    setState(() => _searchQuery = val.trim());
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _loadSpeakers(reset: true);
    });
  }

  void _onSelectFilter(String label) {
    if (_selectedFilter == label) return;
    HapticFeedback.lightImpact();
    setState(() => _selectedFilter = label);
    _loadSpeakers(reset: true);
  }

  List<EventSpeaker> get _filteredSpeakers {
    if (_searchQuery.isEmpty) return _speakers;
    final q = _searchQuery.toLowerCase();
    return _speakers.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.role.toLowerCase().contains(q) ||
          s.topic.toLowerCase().contains(q) ||
          (s.rankTier?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _filteredSpeakers;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. App Bar Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.pop();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF161618),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Speakers',
                          style: AppTheme.font(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          '${displayList.length} verified speakers',
                          style: AppTheme.font(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF141416),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: AppTheme.font(color: Colors.white, fontSize: 13.5),
                  cursorColor: AppTheme.primaryAccent,
                  decoration: InputDecoration(
                    hintText: 'Search by speaker name, role, or topic...',
                    hintStyle: AppTheme.font(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                            child: const Icon(
                              Icons.close_rounded,
                              color: AppTheme.textMuted,
                              size: 18,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 3. Filter / Ordering Chips Carousel
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filterOptions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final opt = _filterOptions[index];
                  final label = opt['label']!;
                  final isSelected = _selectedFilter == label;

                  return GestureDetector(
                    onTap: () => _onSelectFilter(label),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryAccent
                            : const Color(0xFF18181A),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusPill,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryAccent
                              : Colors.white.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: AppTheme.font(
                            color: isSelected ? Colors.black : Colors.white70,
                            fontSize: 11.5,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // 4. Speakers Grid Body
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryAccent,
                        strokeWidth: 2,
                      ),
                    )
                  : displayList.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: AppTheme.primaryAccent,
                      backgroundColor: const Color(0xFF1E1E22),
                      onRefresh: () => _loadSpeakers(reset: true),
                      child: GridView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.74,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 14,
                            ),
                        itemCount:
                            displayList.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == displayList.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                  color: AppTheme.primaryAccent,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }

                          final speaker = displayList[index];
                          return _buildSpeakerCard(speaker);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakerCard(EventSpeaker speaker) {
    final scoreText = speaker.reputationScore != null
        ? speaker.reputationScore!.toStringAsFixed(1)
        : speaker.rating.toStringAsFixed(1);
    final rankText =
        (speaker.rankTier != null && speaker.rankTier!.trim().isNotEmpty)
        ? speaker.rankTier!
        : 'Top Rated';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/speaker/${speaker.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo Background
              _buildSpeakerPhoto(speaker),

              // Dark Vignette & Bottom Text Contrast Gradient
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.2, 0.55, 0.85, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.75),
                        Colors.black.withValues(alpha: 0.95),
                      ],
                    ),
                  ),
                ),
              ),

              // Top-Right Pill Badge
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    rankText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.font(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Bottom Content
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      speaker.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.font(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Metrics Row
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppTheme.starGold,
                          size: 13,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          scoreText,
                          style: AppTheme.font(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${speaker.talksGiven} Talks',
                          style: AppTheme.font(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${speaker.badgesCount} Badges',
                          style: AppTheme.font(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Spoke at X events
                    Text(
                      'Spoke at ${speaker.talksGiven} events',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.font(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Neon Lime "View" Button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAccent,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusPill,
                        ),
                      ),
                      child: Text(
                        'View',
                        style: AppTheme.font(
                          color: Colors.black,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeakerPhoto(EventSpeaker speaker) {
    final avatar = speaker.avatarPath.trim();
    if (avatar.startsWith('assets/')) {
      return Image.asset(
        avatar,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallback(speaker.name),
      );
    }
    if (avatar.isNotEmpty) {
      return AppNetworkImage(
        imageUrl: avatar,
        fit: BoxFit.cover,
        placeholder: _buildFallback(speaker.name),
        errorWidget: _buildFallback(speaker.name),
      );
    }
    return _buildFallback(speaker.name);
  }

  Widget _buildFallback(String name) {
    String initials = '';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      initials = parts[0]
          .substring(0, parts[0].length >= 2 ? 2 : 1)
          .toUpperCase();
    }

    return Container(
      color: const Color(0xFF1E1E22),
      child: Center(
        child: Text(
          initials,
          style: AppTheme.font(
            color: AppTheme.primaryAccent,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.record_voice_over_rounded,
              color: AppTheme.textMuted,
              size: 52,
            ),
            const SizedBox(height: 14),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No speakers found for "$_searchQuery"'
                  : 'No speakers currently available',
              textAlign: TextAlign.center,
              style: AppTheme.font(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try checking spelling or choosing a different filter.'
                  : 'Check back soon as new keynote speakers are verified.',
              textAlign: TextAlign.center,
              style: AppTheme.font(color: AppTheme.textMuted, fontSize: 12.5),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
                child: Text(
                  'Clear Search',
                  style: AppTheme.font(
                    color: AppTheme.primaryAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
