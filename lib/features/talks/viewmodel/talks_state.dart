import 'package:speakwise_mobile/features/talks/data/models/talk_model.dart';

enum TalksStatus { initial, loading, success, error }

class TalksState {
  final TalksStatus status;
  final List<SpeakingTalk> talks;
  final List<FeedbackReview> allReviews;
  final DimensionAnalysis dimensionAnalysis;
  final String selectedTalkFilterId; // 'all' or specific talkId
  final int selectedTab; // 0: Feedback, 1: My Speaking Sessions
  final String? errorMessage;

  const TalksState({
    required this.status,
    required this.talks,
    required this.allReviews,
    required this.dimensionAnalysis,
    this.selectedTalkFilterId = 'all',
    this.selectedTab = 0, // Defaults to Feedback tab as requested by user
    this.errorMessage,
  });

  List<FeedbackReview> get filteredReviews {
    if (selectedTalkFilterId == 'all') {
      return allReviews;
    }
    return allReviews.where((r) {
      if (r.talkId == selectedTalkFilterId) return true;
      final matchingTalk = talks.cast<SpeakingTalk?>().firstWhere(
        (t) => t?.id == selectedTalkFilterId,
        orElse: () => null,
      );
      if (matchingTalk != null) {
        if (r.talkId.isNotEmpty && matchingTalk.qrCodeUrl.contains(r.talkId)) {
          return true;
        }
        if (r.talkTitle.trim().isNotEmpty &&
            r.talkTitle.trim().toLowerCase() ==
                matchingTalk.title.trim().toLowerCase()) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  TalksState copyWith({
    TalksStatus? status,
    List<SpeakingTalk>? talks,
    List<FeedbackReview>? allReviews,
    DimensionAnalysis? dimensionAnalysis,
    String? selectedTalkFilterId,
    int? selectedTab,
    String? errorMessage,
  }) {
    return TalksState(
      status: status ?? this.status,
      talks: talks ?? this.talks,
      allReviews: allReviews ?? this.allReviews,
      dimensionAnalysis: dimensionAnalysis ?? this.dimensionAnalysis,
      selectedTalkFilterId: selectedTalkFilterId ?? this.selectedTalkFilterId,
      selectedTab: selectedTab ?? this.selectedTab,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
