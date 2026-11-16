import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speakwise_mobile/core/services/cache_manager.dart';
import 'package:speakwise_mobile/features/talks/data/models/talk_model.dart';
import 'package:speakwise_mobile/features/talks/data/talks_repository.dart';
import 'package:speakwise_mobile/features/talks/viewmodel/talks_state.dart';

class TalksViewModel extends StateNotifier<TalksState> {
  final TalksRepository _repository;
  final CacheManager _cacheManager;

  bool _isFetching = false;
  Future<void>? _inFlightFetch;

  static const String _cacheKey = 'talks_cache';

  TalksViewModel(this._repository, this._cacheManager)
      : super(
          const TalksState(
            status: TalksStatus.loading,
            talks: [],
            allReviews: [],
            dimensionAnalysis: DimensionAnalysis(
              overallScore: 0.0,
              engagementScore: 0.0,
              clarityScore: 0.0,
              technicalDepthScore: 0.0,
              practicalRelevanceScore: 0.0,
            ),
            selectedTab: 0,
          ),
        ) {
    // 1. Instant 0ms Screen Load from local cache
    _restoreFromCache();
    // 2. Revalidate in the background
    loadTalksData();
  }

  /// 0ms Instant Cache Restoration
  void _restoreFromCache() {
    try {
      final cached = _cacheManager.getJsonMap(_cacheKey);
      if (cached != null) {
        final talksRaw = (cached['talks'] as List?) ?? [];
        final reviewsRaw = (cached['allReviews'] as List?) ?? [];
        final analysisRaw = cached['dimensionAnalysis'] as Map<String, dynamic>?;

        final talks = talksRaw
            .map((t) => SpeakingTalk.fromJson(t as Map<String, dynamic>))
            .toList();
        final reviews = reviewsRaw
            .map((r) => FeedbackReview.fromJson(r as Map<String, dynamic>))
            .toList();
        final analysis = analysisRaw != null
            ? DimensionAnalysis.fromJson(analysisRaw)
            : state.dimensionAnalysis;

        if (talks.isNotEmpty || reviews.isNotEmpty) {
          state = state.copyWith(
            status: TalksStatus.success,
            talks: talks,
            allReviews: reviews,
            dimensionAnalysis: analysis,
          );
          debugPrint('⚡ Talks & Feedback restored instantly from disk (0ms)');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error restoring talks from cache: $e');
    }
  }

  /// Stale-While-Revalidate Loader with Debounce & Request Coalescing
  Future<void> loadTalksData({bool force = false}) async {
    // 1. Debounce: If a fetch is already in progress, join it
    if (_isFetching && _inFlightFetch != null) {
      debugPrint('🔄 Talks data fetch already running. Joining in-flight request.');
      return _inFlightFetch!;
    }

    // 2. Throttling: Do not hit server if fetched < 25s ago unless forced
    final hasData = state.talks.isNotEmpty || state.allReviews.isNotEmpty;
    if (!force && hasData && _cacheManager.isFresh(_cacheKey, maxAge: const Duration(seconds: 25))) {
      debugPrint('⚡ Talks data is fresh (< 25s). Skipping network hit.');
      return;
    }

    _isFetching = true;
    _inFlightFetch = _executeFetch(force: force);

    try {
      await _inFlightFetch;
    } finally {
      _isFetching = false;
      _inFlightFetch = null;
    }
  }

  Future<void> _executeFetch({bool force = false}) async {
    // Only show loading spinner/shimmer if we have NO cached data
    if (state.talks.isEmpty && state.allReviews.isEmpty) {
      state = state.copyWith(status: TalksStatus.loading);
    }

    try {
      // 3. Parallel Execution: Run independent network calls via Future.wait
      final results = await Future.wait([
        _repository.getSpeakingTalks(),
        _repository.getFeedbackReviews(),
        _repository.getDimensionAnalysis(),
      ]);

      final talks = results[0] as List<SpeakingTalk>;
      final reviews = results[1] as List<FeedbackReview>;
      final analysis = results[2] as DimensionAnalysis;

      state = state.copyWith(
        status: TalksStatus.success,
        talks: talks,
        allReviews: reviews,
        dimensionAnalysis: analysis,
      );

      // 4. Persist to cache
      await _cacheManager.put(_cacheKey, {
        'talks': talks.map((t) => t.toJson()).toList(),
        'allReviews': reviews.map((r) => r.toJson()).toList(),
        'dimensionAnalysis': analysis.toJson(),
      });
    } catch (e) {
      debugPrint('⚠️ Talks data fetch error: $e');
      // If we already have cached data, do NOT destroy the UI
      if (state.talks.isEmpty && state.allReviews.isEmpty) {
        state = state.copyWith(
          status: TalksStatus.error,
          errorMessage: e.toString(),
        );
      }
    }
  }

  void setSelectedTab(int index) {
    state = state.copyWith(selectedTab: index);
  }

  void setFilterTalkId(String talkId) async {
    state = state.copyWith(selectedTalkFilterId: talkId);
    try {
      final filteredAnalysis = await _repository.getDimensionAnalysis(
        talkId: talkId == 'all' ? null : talkId,
      );
      state = state.copyWith(dimensionAnalysis: filteredAnalysis);
    } catch (_) {}
  }

  Future<SpeakingTalk> addTalk({
    required String eventName,
    required String eventDate,
    required String title,
    required String description,
    String? presentationUrl,
    String? videoUrl,
  }) async {
    final slug = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-');
    final newTalk = SpeakingTalk(
      id: 'talk-$slug-${DateTime.now().millisecondsSinceEpoch}',
      eventName: eventName,
      eventDate: eventDate,
      title: title,
      description: description,
      presentationUrl: presentationUrl,
      videoUrl: videoUrl,
      qrCodeUrl: 'https://speakwise.live/talk/$slug/feedback',
      rating: 0.0,
      reviewsCount: 0,
      isLive: false,
      coverGradient: const [Color(0xFF2E1229), Color(0xFF13091B)],
      createdAt: DateTime.now(),
    );

    final saved = await _repository.addSpeakingTalk(newTalk);
    final updatedTalks = [saved, ...state.talks];

    state = state.copyWith(talks: updatedTalks);

    // Update cache
    _cacheManager.put(_cacheKey, {
      'talks': updatedTalks.map((t) => t.toJson()).toList(),
      'allReviews': state.allReviews.map((r) => r.toJson()).toList(),
      'dimensionAnalysis': state.dimensionAnalysis.toJson(),
    });

    return saved;
  }

  Future<bool> deleteTalk(String talkId) async {
    try {
      await _repository.deleteSpeakingTalk(talkId);
      final updatedTalks = state.talks.where((t) => t.id != talkId).toList();
      final updatedReviews = state.allReviews.where((r) => r.talkId != talkId).toList();

      final newFilterId = state.selectedTalkFilterId == talkId ? 'all' : state.selectedTalkFilterId;
      state = state.copyWith(
        talks: updatedTalks,
        allReviews: updatedReviews,
        selectedTalkFilterId: newFilterId,
      );

      final analysis = await _repository.getDimensionAnalysis(
        talkId: newFilterId == 'all' ? null : newFilterId,
      );
      state = state.copyWith(dimensionAnalysis: analysis);

      // Update cache
      await _cacheManager.put(_cacheKey, {
        'talks': updatedTalks.map((t) => t.toJson()).toList(),
        'allReviews': updatedReviews.map((r) => r.toJson()).toList(),
        'dimensionAnalysis': analysis.toJson(),
      });
      return true;
    } catch (e) {
      debugPrint('Error deleting talk: $e');
      return false;
    }
  }
}
