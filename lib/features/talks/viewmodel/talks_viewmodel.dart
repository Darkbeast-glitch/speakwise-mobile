import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speakwise_mobile/features/talks/data/models/talk_model.dart';
import 'package:speakwise_mobile/features/talks/data/talks_repository.dart';
import 'package:speakwise_mobile/features/talks/viewmodel/talks_state.dart';

class TalksViewModel extends StateNotifier<TalksState> {
  final TalksRepository _repository;

  TalksViewModel(this._repository)
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
            selectedTab: 0, // Feedback tab
          ),
        ) {
    loadTalksData();
  }

  Future<void> loadTalksData() async {
    state = state.copyWith(status: TalksStatus.loading);
    try {
      final talks = await _repository.getSpeakingTalks();
      final reviews = await _repository.getFeedbackReviews();
      final analysis = await _repository.getDimensionAnalysis();

      state = state.copyWith(
        status: TalksStatus.success,
        talks: talks,
        allReviews: reviews,
        dimensionAnalysis: analysis,
      );
    } catch (e) {
      state = state.copyWith(status: TalksStatus.error, errorMessage: e.toString());
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
    return saved;
  }
}
