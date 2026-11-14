import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speakwise_mobile/core/services/api_client.dart';
import 'package:speakwise_mobile/features/talks/data/models/talk_model.dart';

abstract class TalksRemoteDataSource {
  Future<List<SpeakingTalk>> fetchSpeakerExperiences();
  Future<SpeakingTalk> createSpeakerExperience({
    required String eventName,
    required String eventDate,
    required String topic,
    required String description,
    String? presentationLink,
  });
  Future<List<FeedbackReview>> fetchFeedbackForExperience(String feedbackSlug);
  Future<Map<String, dynamic>> fetchTalkBySlug(String feedbackSlug);
  Future<void> submitTalkFeedback({
    required String feedbackSlug,
    String? name,
    required int overallRating,
    required int clarity,
    required int engagement,
    required int contentDepth,
    required int speakerKnowledge,
    required int practicalRelevance,
    required String comments,
  });
}

class DjangoTalksRemoteDataSource implements TalksRemoteDataSource {
  final ApiClient apiClient;

  DjangoTalksRemoteDataSource({required this.apiClient});

  @override
  Future<List<SpeakingTalk>> fetchSpeakerExperiences() async {
    final response = await apiClient.get('/speakers/experiences/');

    if (response is List) {
      return response.map((item) {
        final json = item as Map<String, dynamic>;
        final slug = json['feedback_slug']?.toString() ?? 'talk';
        return SpeakingTalk(
          id: json['id']?.toString() ?? slug,
          eventName: json['event_name']?.toString() ?? 'Tech Conference',
          eventDate: json['event_date']?.toString() ?? '2026-11-15',
          title: json['topic']?.toString() ?? 'Keynote Presentation',
          description: json['description']?.toString() ?? '',
          presentationUrl: json['presentation_link']?.toString(),
          qrCodeUrl: 'https://speakwise.to/rate/$slug',
          rating: 9.2,
          reviewsCount: 42,
          isLive: json['feedback_enabled'] == true,
          coverGradient: const [Color(0xFF2E1229), Color(0xFF13091B)],
          createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
        );
      }).toList();
    }
    return [];
  }

  @override
  Future<SpeakingTalk> createSpeakerExperience({
    required String eventName,
    required String eventDate,
    required String topic,
    required String description,
    String? presentationLink,
  }) async {
    final response = await apiClient.post(
      '/speakers/experiences/',
      body: {
        'event_name': eventName,
        'event_date': eventDate,
        'topic': topic,
        'description': description,
        'presentation_link': presentationLink,
        'feedback_enabled': true,
      },
    );

    final json = response as Map<String, dynamic>;
    final slug = json['feedback_slug']?.toString() ?? 'talk-${DateTime.now().millisecondsSinceEpoch}';

    return SpeakingTalk(
      id: json['id']?.toString() ?? slug,
      eventName: json['event_name']?.toString() ?? eventName,
      eventDate: json['event_date']?.toString() ?? eventDate,
      title: json['topic']?.toString() ?? topic,
      description: json['description']?.toString() ?? description,
      presentationUrl: json['presentation_link']?.toString() ?? presentationLink,
      qrCodeUrl: 'https://speakwise.to/rate/$slug',
      rating: 0.0,
      reviewsCount: 0,
      isLive: true,
      coverGradient: const [Color(0xFF2E1229), Color(0xFF13091B)],
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<List<FeedbackReview>> fetchFeedbackForExperience(String feedbackSlug) async {
    final response = await apiClient.get(
      '/feedbacks/',
      queryParameters: {'experience': feedbackSlug},
    );

    if (response is List) {
      return response.map((item) {
        final json = item as Map<String, dynamic>;
        final overall = (json['overall_rating'] as num?)?.toDouble() ?? 9.0;
        return FeedbackReview(
          id: json['id']?.toString() ?? 'fb-${DateTime.now().millisecondsSinceEpoch}',
          talkId: feedbackSlug,
          talkTitle: 'Presentation Session',
          eventName: 'Conference Event',
          attendeeName: json['is_anonymous'] == true ? 'Anonymous Attendee' : (json['name']?.toString() ?? 'Attendee'),
          attendeeAvatar: '',
          score: overall,
          timeAgo: 'Just now',
          comment: json['comments']?.toString() ?? '',
          sentimentTags: const ['Audience Favorite', 'High Impact'],
          dimensionBreakdown: {
            'Engagement': (json['engagement'] as num?)?.toDouble() ?? 8.0,
            'Clarity': (json['clarity'] as num?)?.toDouble() ?? 9.0,
            'Technical': (json['content_depth'] as num?)?.toDouble() ?? 8.5,
            'Practical': (json['practical_relevance'] as num?)?.toDouble() ?? 9.0,
          },
        );
      }).toList();
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>> fetchTalkBySlug(String feedbackSlug) async {
    final response = await apiClient.get(
      '/feedbacks/rate/$feedbackSlug/',
      authenticated: false,
    );
    return response as Map<String, dynamic>;
  }

  @override
  Future<void> submitTalkFeedback({
    required String feedbackSlug,
    String? name,
    required int overallRating,
    required int clarity,
    required int engagement,
    required int contentDepth,
    required int speakerKnowledge,
    required int practicalRelevance,
    required String comments,
  }) async {
    await apiClient.post(
      '/feedbacks/rate/$feedbackSlug/',
      authenticated: false,
      body: {
        'name': name ?? 'Anonymous Attendee',
        'overall_rating': overallRating,
        'clarity': clarity,
        'engagement': engagement,
        'content_depth': contentDepth,
        'speaker_knowledge': speakerKnowledge,
        'practical_relevance': practicalRelevance,
        'comments': comments,
      },
    );
  }
}

final talksRemoteDataSourceProvider = Provider<TalksRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DjangoTalksRemoteDataSource(apiClient: apiClient);
});
