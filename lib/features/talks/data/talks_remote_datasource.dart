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

  static const List<List<Color>> _coverGradients = [
    [Color(0xFF2E1229), Color(0xFF13091B)],
    [Color(0xFF13222B), Color(0xFF09141B)],
    [Color(0xFF2B2113), Color(0xFF171209)],
    [Color(0xFF1F2B13), Color(0xFF0E1709)],
    [Color(0xFF1A132B), Color(0xFF0C0917)],
  ];

  @override
  Future<List<SpeakingTalk>> fetchSpeakerExperiences() async {
    List rawItems = [];

    // 1. Fetch from /speakers/experiences/ (authenticated speaker experiences)
    try {
      final response = await apiClient.get('/speakers/experiences/');
      if (response is Map && response['results'] is List) {
        rawItems = response['results'] as List;
      } else if (response is List) {
        rawItems = response;
      }
    } catch (e) {
      debugPrint('Django /speakers/experiences/ fetch notice: $e');
    }

    // 2. Fallback to /talks/ if experiences endpoint returned no records
    if (rawItems.isEmpty) {
      try {
        final talksRes = await apiClient.get('/talks/');
        if (talksRes is Map && talksRes['results'] is List) {
          rawItems = talksRes['results'] as List;
        } else if (talksRes is List) {
          rawItems = talksRes;
        }
      } catch (e) {
        debugPrint('Django /talks/ fetch notice: $e');
      }
    }

    // 3. Map into clean domain SpeakingTalk entities
    final list = <SpeakingTalk>[];
    for (int i = 0; i < rawItems.length; i++) {
      final item = rawItems[i];
      if (item is! Map) continue;
      final json = item as Map<String, dynamic>;

      final slug = json['feedback_slug']?.toString() ??
          json['slug']?.toString() ??
          'talk-${json['id'] ?? i}';
      final id = json['id']?.toString() ?? slug;
      final eventName = json['event_name']?.toString() ??
          json['event_title']?.toString() ??
          (json['event'] is Map ? json['event']['title']?.toString() : null) ??
          'Conference Presentation';
      final eventDate = json['event_date']?.toString() ??
          json['date']?.toString() ??
          '';
      final topic = json['topic']?.toString() ??
          json['title']?.toString() ??
          'Keynote Presentation';
      final description = json['description']?.toString() ?? '';
      final presentationLink = json['presentation_link']?.toString() ??
          json['presentation_url']?.toString();
      final videoLink = json['video_recording_link']?.toString() ??
          json['video_url']?.toString();
      final rating = (json['average_rating'] as num?)?.toDouble() ??
          (json['rating'] as num?)?.toDouble() ??
          0.0;
      final reviewsCount = (json['reviews_count'] as num?)?.toInt() ??
          (json['review_count'] as num?)?.toInt() ??
          (json['total_feedback'] as num?)?.toInt() ??
          0;
      final isLive = json['feedback_enabled'] != false;
      final gradient = _coverGradients[i % _coverGradients.length];

      DateTime createdAt = DateTime.now();
      if (json['created_at'] != null) {
        try {
          createdAt = DateTime.parse(json['created_at'].toString());
        } catch (_) {}
      }

      list.add(SpeakingTalk(
        id: id,
        eventName: eventName,
        eventDate: eventDate,
        title: topic,
        description: description,
        presentationUrl: presentationLink,
        videoUrl: videoLink,
        qrCodeUrl: 'https://speak-wise.live/rate/$slug',
        rating: rating,
        reviewsCount: reviewsCount,
        isLive: isLive,
        coverGradient: gradient,
        createdAt: createdAt,
      ));
    }

    return list;
  }

  @override
  Future<SpeakingTalk> createSpeakerExperience({
    required String eventName,
    required String eventDate,
    required String topic,
    required String description,
    String? presentationLink,
  }) async {
    // Normalize date to YYYY-MM-DD for Django DateField
    String normalizedDate = eventDate.trim();
    if (normalizedDate.contains('/')) {
      final parts = normalizedDate.split('/');
      if (parts.length == 3 && parts[2].length == 4) {
        normalizedDate =
            '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      }
    }

    final response = await apiClient.post(
      '/speakers/experiences/',
      body: {
        'event_name': eventName,
        'event_date': normalizedDate,
        'topic': topic,
        'description': description,
        'presentation_link': presentationLink,
        'feedback_enabled': true,
      },
    );

    final json = response as Map<String, dynamic>;
    final slug = json['feedback_slug']?.toString() ??
        'talk-${DateTime.now().millisecondsSinceEpoch}';

    return SpeakingTalk(
      id: json['id']?.toString() ?? slug,
      eventName: json['event_name']?.toString() ?? eventName,
      eventDate: json['event_date']?.toString() ?? normalizedDate,
      title: json['topic']?.toString() ?? topic,
      description: json['description']?.toString() ?? description,
      presentationUrl:
          json['presentation_link']?.toString() ?? presentationLink,
      qrCodeUrl: 'https://speak-wise.live/rate/$slug',
      rating: 0.0,
      reviewsCount: 0,
      isLive: true,
      coverGradient: _coverGradients[0],
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<List<FeedbackReview>> fetchFeedbackForExperience(
      String feedbackSlug) async {
    Map<String, String>? queryParams;
    if (feedbackSlug.isNotEmpty && feedbackSlug != 'all') {
      queryParams = {'experience': feedbackSlug};
    }

    final response = await apiClient.get(
      '/feedbacks/',
      queryParameters: queryParams,
    );

    List items = [];
    if (response is Map && response['results'] is List) {
      items = response['results'] as List;
    } else if (response is List) {
      items = response;
    }

    final reviews = <FeedbackReview>[];
    for (final raw in items) {
      if (raw is! Map) continue;
      final json = raw as Map<String, dynamic>;

      final overall = (json['overall_rating'] as num?)?.toDouble() ?? 0.0;
      final engagement = (json['engagement'] as num?)?.toDouble() ?? 0.0;
      final clarity = (json['clarity'] as num?)?.toDouble() ?? 0.0;
      final depth = (json['content_depth'] as num?)?.toDouble() ?? 0.0;
      final practical = (json['practical_relevance'] as num?)?.toDouble() ?? 0.0;
      final knowledge = (json['speaker_knowledge'] as num?)?.toDouble() ?? 0.0;

      final exp = json['experience'];
      final talkSlug = exp is Map
          ? (exp['feedback_slug']?.toString() ?? '')
          : (json['experience']?.toString() ?? '');
      final talkTitle = exp is Map
          ? (exp['topic']?.toString() ?? 'Keynote Presentation')
          : 'Presentation Session';
      final eventName = exp is Map
          ? (exp['event_name']?.toString() ?? 'Conference Event')
          : 'Conference Event';

      // Human-readable relative time
      String timeAgo = 'Recently';
      if (json['created_at'] != null) {
        try {
          final dt = DateTime.parse(json['created_at'].toString());
          final diff = DateTime.now().difference(dt);
          if (diff.inMinutes < 60) {
            timeAgo = '${diff.inMinutes.clamp(1, 60)}m ago';
          } else if (diff.inHours < 24) {
            timeAgo = '${diff.inHours}h ago';
          } else if (diff.inDays < 30) {
            timeAgo = '${diff.inDays}d ago';
          } else {
            timeAgo = '${(diff.inDays / 30).floor()}mo ago';
          }
        } catch (_) {}
      }

      // Dynamic sentiment tags based on ratings
      final tags = <String>[];
      if (overall >= 9.0) tags.add('Top Rated');
      if (clarity >= 8.5) tags.add('High Clarity');
      if (engagement >= 8.5) tags.add('Audience Favorite');
      if (depth >= 8.5) tags.add('Deep Technical');
      if (practical >= 8.5) tags.add('Practical Insights');
      if (knowledge >= 8.5) tags.add('Domain Expert');
      if (tags.isEmpty) tags.addAll(['Constructive', 'Verified Feedback']);

      reviews.add(FeedbackReview(
        id: json['id']?.toString() ??
            'fb-${DateTime.now().millisecondsSinceEpoch}',
        talkId: talkSlug,
        talkTitle: talkTitle,
        eventName: eventName,
        attendeeName: json['is_anonymous'] == true
            ? 'Anonymous Attendee'
            : (json['name']?.toString().trim().isNotEmpty == true
                ? json['name'].toString().trim()
                : 'Attendee'),
        attendeeAvatar: '',
        score: overall,
        timeAgo: timeAgo,
        comment: json['comments']?.toString() ?? '',
        sentimentTags: tags,
        dimensionBreakdown: {
          'Engagement': engagement,
          'Clarity': clarity,
          'Technical': depth,
          'Practical': practical,
          'Knowledge': knowledge,
        },
      ));
    }

    return reviews;
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
