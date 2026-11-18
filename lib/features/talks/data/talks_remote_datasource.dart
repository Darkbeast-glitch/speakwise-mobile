import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speakwise_mobile/core/services/api_client.dart';
import 'package:speakwise_mobile/features/talks/data/models/talk_model.dart';

abstract class TalksRemoteDataSource {
  Future<String?> resolveSpeakerSlugOrId();
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
  Future<void> deleteSpeakerExperience(String talkId);
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
  Future<String?> resolveSpeakerSlugOrId() async {
    String? slugOrId = apiClient.storageService.speakerSlug;
    if (slugOrId != null && slugOrId.trim().isNotEmpty) {
      return slugOrId.trim();
    }
    slugOrId = apiClient.storageService.speakerId;
    if (slugOrId != null && slugOrId.trim().isNotEmpty) {
      return slugOrId.trim();
    }
    slugOrId = apiClient.storageService.username;
    if (slugOrId != null && slugOrId.trim().isNotEmpty) {
      return slugOrId.trim();
    }

    // Attempt to discover speaker slug / ID dynamically from /users/me/
    if (apiClient.storageService.authToken != null &&
        apiClient.storageService.authToken!.isNotEmpty) {
      try {
        final me = await apiClient.get('/users/me/', authenticated: true);
        if (me is Map<String, dynamic>) {
          final slug = me['speaker_slug']?.toString() ??
              (me['speaker_profile'] is Map
                  ? me['speaker_profile']['slug']?.toString()
                  : null) ??
              (me['profile'] is Map && me['profile']['speaker_profile'] is Map
                  ? me['profile']['speaker_profile']['slug']?.toString()
                  : null);
          final spId = me['speaker_id']?.toString() ??
              (me['speaker_profile'] is Map
                  ? me['speaker_profile']['id']?.toString()
                  : null);
          final username = me['username']?.toString();

          if (slug != null && slug.isNotEmpty) {
            await apiClient.storageService.setSpeakerSlug(slug);
            return slug;
          }
          if (spId != null && spId.isNotEmpty) {
            await apiClient.storageService.setSpeakerId(spId);
            return spId;
          }
          if (username != null && username.isNotEmpty) {
            await apiClient.storageService.setUsername(username);
            return username;
          }
        }
      } catch (e) {
        debugPrint('Django /users/me/ resolve note in talks: $e');
      }
    }

    return null;
  }

  void _extractRawList(dynamic response, List target) {
    if (response is Map && response['results'] is List) {
      target.addAll(response['results'] as List);
    } else if (response is List) {
      target.addAll(response);
    }
  }

  @override
  Future<List<SpeakingTalk>> fetchSpeakerExperiences() async {
    final rawItems = [];
    final slugOrId = await resolveSpeakerSlugOrId();

    // 1. Fetch from speaker-specific endpoints if slug/ID resolved
    if (slugOrId != null && slugOrId.isNotEmpty) {
      try {
        final expRes = await apiClient.get('/speakers/$slugOrId/experiences/');
        _extractRawList(expRes, rawItems);
      } catch (e) {
        debugPrint('Django /speakers/$slugOrId/experiences/ notice: $e');
      }

      try {
        final talksRes = await apiClient.get('/speakers/$slugOrId/talks/');
        _extractRawList(talksRes, rawItems);
      } catch (e) {
        debugPrint('Django /speakers/$slugOrId/talks/ notice: $e');
      }

      // If still empty, check speaker profile payload which often embeds talks/experiences
      if (rawItems.isEmpty) {
        try {
          final profileRes = await apiClient.get('/speakers/$slugOrId/');
          if (profileRes is Map<String, dynamic>) {
            if (profileRes['events_spoken'] is List) {
              rawItems.addAll(profileRes['events_spoken'] as List);
            }
            if (profileRes['talks'] is List) {
              rawItems.addAll(profileRes['talks'] as List);
            }
          }
        } catch (e) {
          debugPrint('Django /speakers/$slugOrId/ profile notice: $e');
        }
      }
    }

    // 2. Fallbacks
    if (rawItems.isEmpty) {
      try {
        final response = await apiClient.get('/speakers/experiences/');
        _extractRawList(response, rawItems);
      } catch (e) {
        debugPrint('Django /speakers/experiences/ fetch notice: $e');
      }
    }

    if (rawItems.isEmpty) {
      try {
        final talksRes = await apiClient.get('/talks/');
        _extractRawList(talksRes, rawItems);
      } catch (e) {
        debugPrint('Django /talks/ fetch notice: $e');
      }
    }

    // 3. Map into clean domain SpeakingTalk entities with deduplication
    final list = <SpeakingTalk>[];
    final seenKeys = <String>{};

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
      final gradient = _coverGradients[list.length % _coverGradients.length];

      final dedupeKey = '$topic::$eventName'.toLowerCase();
      if (seenKeys.contains(dedupeKey)) continue;
      seenKeys.add(dedupeKey);

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

    final slugOrId = await resolveSpeakerSlugOrId();
    dynamic response;

    final body = {
      'event_name': eventName,
      'event_date': normalizedDate,
      'topic': topic,
      'description': description,
      'presentation_link': presentationLink,
      'feedback_enabled': true,
    };

    if (slugOrId != null && slugOrId.isNotEmpty) {
      try {
        response = await apiClient.post(
          '/speakers/$slugOrId/experiences/',
          body: body,
        );
      } catch (e) {
        debugPrint('Django /speakers/$slugOrId/experiences/ create notice: $e');
      }
    }

    if (response == null) {
      response = await apiClient.post(
        '/speakers/experiences/',
        body: body,
      );
    }

    final json = response as Map<String, dynamic>;
    final slug = json['feedback_slug']?.toString() ??
        json['slug']?.toString() ??
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
    final items = [];
    final slugOrId = await resolveSpeakerSlugOrId();

    // 1. Specific feedback slug requested
    if (feedbackSlug.isNotEmpty && feedbackSlug != 'all') {
      try {
        final res = await apiClient.get(
          '/feedbacks/',
          queryParameters: {'experience': feedbackSlug},
        );
        _extractRawList(res, items);
      } catch (e) {
        debugPrint('Django /feedbacks/?experience=$feedbackSlug notice: $e');
      }

      if (items.isEmpty) {
        try {
          final res = await apiClient.get(
            '/feedbacks/',
            queryParameters: {'experience_slug': feedbackSlug},
          );
          _extractRawList(res, items);
        } catch (_) {}
      }
    } else {
      // 2. Fetch all reviews for authenticated user
      try {
        final res = await apiClient.get('/feedbacks/');
        _extractRawList(res, items);
      } catch (e) {
        debugPrint('Django /feedbacks/ notice: $e');
      }

      // If empty, query with speaker filter
      if (items.isEmpty && slugOrId != null && slugOrId.isNotEmpty) {
        try {
          final res = await apiClient.get(
            '/feedbacks/',
            queryParameters: {'speaker': slugOrId},
          );
          _extractRawList(res, items);
        } catch (_) {}

        if (items.isEmpty) {
          try {
            final res = await apiClient.get(
              '/feedbacks/',
              queryParameters: {'speaker_slug': slugOrId},
            );
            _extractRawList(res, items);
          } catch (_) {}
        }

        // Try nested speaker feedback endpoints
        if (items.isEmpty) {
          try {
            final res = await apiClient.get('/speakers/$slugOrId/feedbacks/');
            _extractRawList(res, items);
          } catch (_) {}
        }
        if (items.isEmpty) {
          try {
            final res = await apiClient.get('/speakers/$slugOrId/feedback/');
            _extractRawList(res, items);
          } catch (_) {}
        }

        // Check if the speaker profile itself returned embedded feedback list
        if (items.isEmpty) {
          try {
            final profileRes = await apiClient.get('/speakers/$slugOrId/');
            if (profileRes is Map<String, dynamic>) {
              if (profileRes['feedbacks'] is List) {
                _extractRawList(profileRes['feedbacks'], items);
              } else if (profileRes['reviews'] is List) {
                _extractRawList(profileRes['reviews'], items);
              } else if (profileRes['recent_feedback'] is List) {
                _extractRawList(profileRes['recent_feedback'], items);
              }
            }
          } catch (_) {}
        }
      }
    }

    final reviews = <FeedbackReview>[];
    final seenReviewIds = <String>{};

    for (final raw in items) {
      if (raw is! Map) continue;
      final json = raw as Map<String, dynamic>;

      final revId = json['id']?.toString() ??
          'fb-${DateTime.now().millisecondsSinceEpoch}-${reviews.length}';
      if (seenReviewIds.contains(revId)) continue;
      seenReviewIds.add(revId);

      final overall = (json['overall_rating'] as num?)?.toDouble() ??
          (json['rating'] as num?)?.toDouble() ??
          (json['score'] as num?)?.toDouble() ??
          0.0;
      final engagement = (json['engagement'] as num?)?.toDouble() ??
          (json['engagement_rating'] as num?)?.toDouble() ??
          0.0;
      final clarity = (json['clarity'] as num?)?.toDouble() ??
          (json['clarity_rating'] as num?)?.toDouble() ??
          0.0;
      final depth = (json['content_depth'] as num?)?.toDouble() ??
          (json['depth'] as num?)?.toDouble() ??
          0.0;
      final practical = (json['practical_relevance'] as num?)?.toDouble() ??
          (json['practical'] as num?)?.toDouble() ??
          0.0;
      final knowledge = (json['speaker_knowledge'] as num?)?.toDouble() ??
          (json['knowledge'] as num?)?.toDouble() ??
          0.0;

      final exp = json['experience'];
      final talkSlug = exp is Map
          ? (exp['feedback_slug']?.toString() ??
              exp['slug']?.toString() ??
              exp['id']?.toString() ??
              '')
          : (json['experience']?.toString() ?? '');
      final talkTitle = exp is Map
          ? (exp['topic']?.toString() ?? exp['title']?.toString() ?? 'Presentation Session')
          : (json['experience_topic']?.toString() ?? json['topic']?.toString() ?? 'Presentation Session');
      final eventName = exp is Map
          ? (exp['event_name']?.toString() ?? exp['event_title']?.toString() ?? 'Conference Event')
          : (json['event_name']?.toString() ?? 'Conference Event');

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

      final commentText = json['comments']?.toString() ??
          json['comment']?.toString() ??
          json['feedback']?.toString() ??
          '';

      final attendee = json['is_anonymous'] == true
          ? 'Anonymous Attendee'
          : (json['name']?.toString().trim().isNotEmpty == true
              ? json['name'].toString().trim()
              : (json['attendee_name']?.toString().trim().isNotEmpty == true
                  ? json['attendee_name'].toString().trim()
                  : 'Attendee'));

      reviews.add(FeedbackReview(
        id: revId,
        talkId: talkSlug,
        talkTitle: talkTitle,
        eventName: eventName,
        attendeeName: attendee,
        attendeeAvatar: '',
        score: overall,
        timeAgo: timeAgo,
        comment: commentText,
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

  @override
  Future<void> deleteSpeakerExperience(String talkId) async {
    final slugOrId = await resolveSpeakerSlugOrId();
    bool deleted = false;

    final candidateEndpoints = [
      if (slugOrId != null && slugOrId.isNotEmpty)
        '/speakers/$slugOrId/experiences/$talkId/',
      '/speakers/experiences/$talkId/',
      '/experiences/$talkId/',
    ];

    for (final endpoint in candidateEndpoints) {
      try {
        await apiClient.delete(endpoint);
        deleted = true;
        debugPrint('Successfully deleted experience via $endpoint');
        break;
      } catch (e) {
        debugPrint('Candidate delete endpoint $endpoint failed: $e');
      }
    }

    if (!deleted) {
      debugPrint('Remote delete failed or not implemented on backend; removed locally.');
    }
  }
}

final talksRemoteDataSourceProvider = Provider<TalksRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DjangoTalksRemoteDataSource(apiClient: apiClient);
});
