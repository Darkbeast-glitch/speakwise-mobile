import 'package:flutter/material.dart';
import 'package:speakwise_mobile/features/talks/data/models/talk_model.dart';
import 'package:speakwise_mobile/features/talks/data/talks_remote_datasource.dart';

abstract class TalksRepository {
  Future<List<SpeakingTalk>> getSpeakingTalks();
  Future<List<FeedbackReview>> getFeedbackReviews({String? talkId});
  Future<DimensionAnalysis> getDimensionAnalysis({String? talkId});
  Future<SpeakingTalk> addSpeakingTalk(SpeakingTalk talk);
}

class MockTalksRepository implements TalksRepository {
  final List<SpeakingTalk> _talks = [
    SpeakingTalk(
      id: 'talk-flutter-cicd',
      eventName: 'DevFest Accra 2026',
      eventDate: '06/11/2026',
      title: 'From Code to Tester: Flutter CI/CD with Codemagic and GitHub Actions',
      description:
          'Deep dive into automating Flutter releases, running integration tests on headless runners, and setting up instant distribution to testers across iOS and Android.',
      presentationUrl: 'https://slides.com/julius/flutter-cicd',
      videoUrl: 'https://youtube.com/watch?v=flutter-cicd',
      qrCodeUrl: 'https://speakwise.live/talk/flutter-cicd/feedback',
      rating: 9.3,
      reviewsCount: 142,
      isLive: false,
      coverGradient: const [Color(0xFF2E1229), Color(0xFF13091B)],
      createdAt: DateTime(2026, 11, 6),
    ),
    SpeakingTalk(
      id: 'talk-observability',
      eventName: 'PyCon Togo 2026',
      eventDate: '28/08/2026',
      title: 'Shipping Was Easy. Monitoring Was Not: Observability in Production',
      description:
          'Architecting distributed tracing, OpenTelemetry collectors, and error tracking in Python microservices to handle high-traffic spikes without silent failures.',
      presentationUrl: 'https://slides.com/julius/observability',
      videoUrl: null,
      qrCodeUrl: 'https://speakwise.live/talk/observability/feedback',
      rating: 7.8,
      reviewsCount: 13,
      isLive: false,
      coverGradient: const [Color(0xFF13222B), Color(0xFF09141B)],
      createdAt: DateTime(2026, 8, 28),
    ),
    SpeakingTalk(
      id: 'talk-scalable-apis',
      eventName: 'PyCon Ghana 2025',
      eventDate: '15/07/2025',
      title: 'Building Scalable APIs with Python & AsyncIO',
      description:
          'Constructing enterprise-grade REST and WebSocket APIs using FastAPI, async database drivers, and Redis caching for ultra low-latency response times.',
      presentationUrl: 'https://slides.com/julius/scalable-apis',
      videoUrl: 'https://youtube.com/watch?v=python-scalable-apis',
      qrCodeUrl: 'https://speakwise.live/talk/scalable-apis/feedback',
      rating: 8.8,
      reviewsCount: 89,
      isLive: false,
      coverGradient: const [Color(0xFF2B2113), Color(0xFF171209)],
      createdAt: DateTime(2025, 7, 15),
    ),
    SpeakingTalk(
      id: 'talk-realtime-flutter',
      eventName: 'Cortex Dev Summit 2026',
      eventDate: '13/11/2026',
      title: 'Building Realtime Mobile Apps in Flutter',
      description:
          'Live coding high performance WebSockets and state machines in Flutter with offline synchronization and optimistic local caching.',
      presentationUrl: 'https://slides.com/julius/realtime-flutter',
      videoUrl: null,
      qrCodeUrl: 'https://speakwise.live/talk/realtime-flutter/feedback',
      rating: 9.6,
      reviewsCount: 54,
      isLive: true,
      coverGradient: const [Color(0xFF1F2B13), Color(0xFF0E1709)],
      createdAt: DateTime.now(),
    ),
  ];

  final List<FeedbackReview> _reviews = [
    const FeedbackReview(
      id: 'rev-1',
      talkId: 'talk-flutter-cicd',
      talkTitle: 'From Code to Tester: Flutter CI/CD',
      eventName: 'DevFest Accra 2026',
      attendeeName: 'Kwame Mensah',
      attendeeAvatar: 'assets/images/ezra.jpg',
      score: 9.8,
      timeAgo: '12m ago',
      comment:
          'The practical live pipeline demonstration was exceptional! Easily the most applicable talk of DevFest. The Codemagic setup will save our team weeks.',
      sentimentTags: ['High Clarity', 'Practical Demo', 'Actionable'],
      dimensionBreakdown: {
        'Engagement': 9.2,
        'Clarity': 9.8,
        'Technical': 9.5,
        'Practical': 10.0,
      },
    ),
    const FeedbackReview(
      id: 'rev-2',
      talkId: 'talk-realtime-flutter',
      talkTitle: 'Building Realtime Mobile Apps',
      eventName: 'Cortex Dev Summit 2026',
      attendeeName: 'Juliana Lawson',
      attendeeAvatar: 'assets/images/Juliana.jpg',
      score: 9.6,
      timeAgo: '35m ago',
      comment:
          'Loved the real-time WebSocket architecture tips and how optimistic UI updates prevent screen flicker. Incredible speaker presence!',
      sentimentTags: ['Energetic Delivery', 'Deep Tech', 'Well Structured'],
      dimensionBreakdown: {
        'Engagement': 9.8,
        'Clarity': 9.4,
        'Technical': 9.6,
        'Practical': 9.5,
      },
    ),
    const FeedbackReview(
      id: 'rev-3',
      talkId: 'talk-flutter-cicd',
      talkTitle: 'From Code to Tester: Flutter CI/CD',
      eventName: 'DevFest Accra 2026',
      attendeeName: 'Sarah Boateng',
      attendeeAvatar: 'assets/images/cat_africa.jpg',
      score: 9.0,
      timeAgo: '2h ago',
      comment:
          'Clear, engaging, and well-paced. The QR code feedback system during the session was such a great touch!',
      sentimentTags: ['Great Pacing', 'Interactive', 'Insightful'],
      dimensionBreakdown: {
        'Engagement': 9.0,
        'Clarity': 9.2,
        'Technical': 8.8,
        'Practical': 9.1,
      },
    ),
    const FeedbackReview(
      id: 'rev-4',
      talkId: 'talk-observability',
      talkTitle: 'Shipping Was Easy. Monitoring Was Not',
      eventName: 'PyCon Togo 2026',
      attendeeName: 'Anonymous Attendee',
      attendeeAvatar: '',
      score: 7.8,
      timeAgo: '2d ago',
      comment:
          'Very solid coverage of distributed tracing in Python. Would have appreciated 5 more minutes on cost optimization with third-party APMs.',
      sentimentTags: ['Technical Depth', 'Good Case Studies'],
      dimensionBreakdown: {
        'Engagement': 7.5,
        'Clarity': 8.0,
        'Technical': 8.2,
        'Practical': 7.6,
      },
    ),
    const FeedbackReview(
      id: 'rev-5',
      talkId: 'talk-scalable-apis',
      talkTitle: 'Building Scalable APIs with Python',
      eventName: 'PyCon Ghana 2025',
      attendeeName: 'Emmanuel K.',
      attendeeAvatar: '',
      score: 8.9,
      timeAgo: '5d ago',
      comment:
          'Hands down one of the clearest explanations of AsyncIO event loops and Redis caching strategies in production.',
      sentimentTags: ['Clear Concepts', 'High Energy', 'Top Speaker'],
      dimensionBreakdown: {
        'Engagement': 8.7,
        'Clarity': 9.1,
        'Technical': 9.0,
        'Practical': 8.8,
      },
    ),
  ];

  @override
  Future<List<SpeakingTalk>> getSpeakingTalks() async {
    return List.from(_talks);
  }

  @override
  Future<List<FeedbackReview>> getFeedbackReviews({String? talkId}) async {
    if (talkId == null || talkId == 'all') {
      return List.from(_reviews);
    }
    return _reviews.where((r) => r.talkId == talkId).toList();
  }

  @override
  Future<DimensionAnalysis> getDimensionAnalysis({String? talkId}) async {
    // Matching exact metrics from user webapp image 2
    return const DimensionAnalysis(
      overallScore: 8.1,
      engagementScore: 7.8,
      clarityScore: 8.4,
      technicalDepthScore: 7.9,
      practicalRelevanceScore: 8.2,
    );
  }

  @override
  Future<SpeakingTalk> addSpeakingTalk(SpeakingTalk talk) async {
    _talks.insert(0, talk);
    return talk;
  }
}

class DjangoTalksRepositoryImpl implements TalksRepository {
  final TalksRemoteDataSource remoteDataSource;

  DjangoTalksRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<SpeakingTalk>> getSpeakingTalks() async {
    try {
      final talks = await remoteDataSource.fetchSpeakerExperiences();

      // Enrich talks with real reviews count and average rating if reviews exist
      try {
        final allReviews = await remoteDataSource.fetchFeedbackForExperience('');
        if (allReviews.isNotEmpty) {
          final enriched = <SpeakingTalk>[];
          for (final talk in talks) {
            final matching = allReviews.where(
              (r) => r.talkId == talk.id || talk.qrCodeUrl.endsWith(r.talkId),
            );
            if (matching.isNotEmpty) {
              final avg = matching.map((r) => r.score).reduce((a, b) => a + b) /
                  matching.length;
              enriched.add(talk.copyWith(
                rating: double.parse(avg.toStringAsFixed(1)),
                reviewsCount: matching.length,
              ));
            } else {
              enriched.add(talk);
            }
          }
          return enriched;
        }
      } catch (_) {}

      return talks;
    } catch (e) {
      debugPrint('Django fetchSpeakerExperiences error: $e');
      return [];
    }
  }

  @override
  Future<List<FeedbackReview>> getFeedbackReviews({String? talkId}) async {
    try {
      final slug = (talkId == null || talkId == 'all') ? '' : talkId;
      return await remoteDataSource.fetchFeedbackForExperience(slug);
    } catch (e) {
      debugPrint('Django fetchFeedbackForExperience error: $e');
      return [];
    }
  }

  @override
  Future<DimensionAnalysis> getDimensionAnalysis({String? talkId}) async {
    final reviews = await getFeedbackReviews(talkId: talkId);
    if (reviews.isNotEmpty) {
      double totalOverall = 0;
      double totalEngagement = 0;
      double totalClarity = 0;
      double totalDepth = 0;
      double totalPractical = 0;

      for (final r in reviews) {
        totalOverall += r.score;
        totalEngagement += r.dimensionBreakdown['Engagement'] ?? r.score;
        totalClarity += r.dimensionBreakdown['Clarity'] ?? r.score;
        totalDepth += r.dimensionBreakdown['Technical'] ?? r.score;
        totalPractical += r.dimensionBreakdown['Practical'] ?? r.score;
      }

      final count = reviews.length;
      return DimensionAnalysis(
        overallScore: double.parse((totalOverall / count).toStringAsFixed(1)),
        engagementScore:
            double.parse((totalEngagement / count).toStringAsFixed(1)),
        clarityScore: double.parse((totalClarity / count).toStringAsFixed(1)),
        technicalDepthScore:
            double.parse((totalDepth / count).toStringAsFixed(1)),
        practicalRelevanceScore:
            double.parse((totalPractical / count).toStringAsFixed(1)),
      );
    }

    // Clean zero-activity baseline when no reviews have been submitted yet
    return const DimensionAnalysis(
      overallScore: 0.0,
      engagementScore: 0.0,
      clarityScore: 0.0,
      technicalDepthScore: 0.0,
      practicalRelevanceScore: 0.0,
    );
  }

  @override
  Future<SpeakingTalk> addSpeakingTalk(SpeakingTalk talk) async {
    return await remoteDataSource.createSpeakerExperience(
      eventName: talk.eventName,
      eventDate: talk.eventDate,
      topic: talk.title,
      description: talk.description,
      presentationLink: talk.presentationUrl,
    );
  }
}
