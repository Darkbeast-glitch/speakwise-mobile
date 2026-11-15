import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speakwise_mobile/core/services/api_client.dart';
import 'package:speakwise_mobile/features/profile/data/models/user_profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<Map<String, dynamic>?> fetchCurrentUser();
  Future<UserProfile> fetchSpeakerProfile(String slugOrId);
  Future<List<SpeakerBadge>> fetchSpeakerBadges(String slugOrId);
  Future<List<SpeakerTalkItem>> fetchSpeakerTalks(String slugOrId);
  Future<List<SpeakerEventSpoken>> fetchSpeakerExperiences(String slugOrId);
  Future<void> sendSpeakerEmailRequest({
    required String speakerId,
    required String eventName,
    required String location,
    required String message,
  });
  Future<UserProfile> updateSpeakerProfile(UserProfile profile);
}

class DjangoProfileRemoteDataSource implements ProfileRemoteDataSource {
  final ApiClient apiClient;

  DjangoProfileRemoteDataSource({required this.apiClient});

  String _sanitizeUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return '';
    var url = rawUrl.trim();
    if (url.contains('127.0.0.1:8000') || url.contains('localhost:8000')) {
      final host = Uri.parse(apiClient.baseUrl).host;
      url = url.replaceAll('127.0.0.1', host).replaceAll('localhost', host);
    }
    return url;
  }

  @override
  Future<Map<String, dynamic>?> fetchCurrentUser() async {
    try {
      final response = await apiClient.get('/users/me/', authenticated: true);
      if (response is Map<String, dynamic>) {
        return response;
      }
    } catch (_) {
      // Endpoint may be unreachable or user not authenticated
    }
    return null;
  }

  @override
  Future<UserProfile> fetchSpeakerProfile(String slugOrId) async {
    final response = await apiClient.get(
      '/speakers/$slugOrId/',
      authenticated: false,
    );

    final json = response as Map<String, dynamic>;

    // 1. Fetch badges
    List<SpeakerBadge> badges = [];
    try {
      badges = await fetchSpeakerBadges(slugOrId);
    } catch (_) {
      // Fallback badges
    }

    // 2. Parse skills
    final skillsList = <String>[];
    if (json['skill_tags'] is List) {
      for (final tag in json['skill_tags'] as List) {
        if (tag is Map && tag['name'] != null) {
          skillsList.add(tag['name'].toString());
        }
      }
    }

    // 3. Parse social links
    final socialMap = <String, String>{};
    if (json['social_links'] is List) {
      for (final sl in json['social_links'] as List) {
        if (sl is Map && sl['name'] != null && sl['link'] != null) {
          socialMap[sl['name'].toString()] = sl['link'].toString();
        }
      }
    }

    // 4. Parse talks (from enriched payload or separate endpoint)
    final talksList = <SpeakerTalkItem>[];
    if (json['talks'] is List) {
      for (final item in json['talks'] as List) {
        if (item is Map) {
          talksList.add(SpeakerTalkItem(
            id: item['id']?.toString() ?? 'talk-${talksList.length}',
            title: item['title']?.toString() ?? 'Keynote Talk',
            description: item['description']?.toString() ?? '',
            duration: item['duration'] is int ? item['duration'] as int : 30,
            category: item['category']?.toString() ?? 'Keynote',
            eventTitle: item['event_title']?.toString() ?? '',
            eventId: item['event_id']?.toString(),
            eventImage: _sanitizeUrl(item['event_image']?.toString()),
            presentationLink: item['presentation_link']?.toString(),
            videoRecordingLink: item['video_recording_link']?.toString(),
            date: item['date']?.toString() ?? item['event_date']?.toString(),
          ));
        }
      }
    }

    if (talksList.isEmpty) {
      try {
        final fetchedTalks = await fetchSpeakerTalks(slugOrId);
        talksList.addAll(fetchedTalks);
      } catch (_) {}
    }

    // 5. Parse events spoken (from enriched payload, talks, or experiences)
    final eventsSpokenList = <SpeakerEventSpoken>[];
    final seenEvents = <String>{};

    if (json['events_spoken'] is List) {
      for (final item in json['events_spoken'] as List) {
        if (item is Map) {
          final name = item['name']?.toString() ?? item['event_name']?.toString() ?? '';
          if (name.isNotEmpty && !seenEvents.contains(name.toLowerCase())) {
            seenEvents.add(name.toLowerCase());
            eventsSpokenList.add(SpeakerEventSpoken(
              id: item['id']?.toString() ?? 'evt-${eventsSpokenList.length}',
              name: name,
              topic: item['topic']?.toString() ?? '',
              date: item['date']?.toString() ?? '',
              image: _sanitizeUrl(item['image']?.toString() ?? item['event_image']?.toString()),
              eventId: item['event_id']?.toString(),
              presentationLink: item['presentation_link']?.toString(),
              videoRecordingLink: item['video_recording_link']?.toString(),
              description: item['description']?.toString(),
            ));
          }
        }
      }
    }

    // Check experiences endpoint to enrich talks & spoken events
    try {
      final experiences = await fetchSpeakerExperiences(slugOrId);
      for (final exp in experiences) {
        if (!seenEvents.contains(exp.name.toLowerCase())) {
          seenEvents.add(exp.name.toLowerCase());
          eventsSpokenList.add(exp);
        }
        // If not already in talks, add experience as verified talk
        final alreadyHasTalk = talksList.any((t) =>
            t.id == exp.id ||
            (t.eventTitle.toLowerCase() == exp.name.toLowerCase() && t.title == exp.topic));
        if (!alreadyHasTalk) {
          talksList.add(SpeakerTalkItem(
            id: exp.id,
            title: exp.topic.isNotEmpty ? exp.topic : '${exp.name} Keynote',
            description: (exp.description != null && exp.description!.isNotEmpty)
                ? exp.description!
                : 'Verified keynote presentation delivered at ${exp.name}.',
            duration: 45,
            category: 'Keynote',
            eventTitle: exp.name,
            eventId: exp.eventId,
            eventImage: exp.image,
            date: exp.date,
            presentationLink: exp.presentationLink,
            videoRecordingLink: exp.videoRecordingLink,
          ));
        }
      }
    } catch (_) {}

    // Derive spoken events from talks if still empty
    if (eventsSpokenList.isEmpty) {
      for (final talk in talksList) {
        if (talk.eventTitle.isNotEmpty && !seenEvents.contains(talk.eventTitle.toLowerCase())) {
          seenEvents.add(talk.eventTitle.toLowerCase());
          eventsSpokenList.add(SpeakerEventSpoken(
            id: talk.eventId ?? 'evt-${eventsSpokenList.length}',
            name: talk.eventTitle,
            topic: talk.title,
            image: talk.eventImage,
            eventId: talk.eventId,
            presentationLink: talk.presentationLink,
            videoRecordingLink: talk.videoRecordingLink,
            description: talk.description,
            date: talk.date ?? '',
          ));
        }
      }
    }

    // If talks are still empty, derive talks from eventsSpokenList
    if (talksList.isEmpty && eventsSpokenList.isNotEmpty) {
      for (final evt in eventsSpokenList) {
        talksList.add(SpeakerTalkItem(
          id: evt.id,
          title: evt.topic.isNotEmpty ? evt.topic : '${evt.name} Keynote',
          description: (evt.description != null && evt.description!.isNotEmpty)
              ? evt.description!
              : 'Verified keynote presentation delivered at ${evt.name}.',
          duration: 45,
          category: 'Keynote',
          eventTitle: evt.name,
          eventId: evt.eventId,
          eventImage: evt.image,
          date: evt.date,
          presentationLink: evt.presentationLink,
          videoRecordingLink: evt.videoRecordingLink,
        ));
      }
    }

    final fullName = json['speaker_name']?.toString() ?? json['name']?.toString() ?? '';
    final nameParts = fullName.isNotEmpty ? fullName.split(' ') : <String>[];
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final avatar = _sanitizeUrl(json['avatar']?.toString());
    final feedbackSummary = json['feedback_summary'] as Map<String, dynamic>? ?? {};
    final overallAvg = (feedbackSummary['overall_rating'] as Map<String, dynamic>?)?['average'];
    final avgRating = overallAvg is num ? overallAvg.toDouble() : 0.0;
    final totalFeedback = feedbackSummary['total_count'] is int ? feedbackSummary['total_count'] as int : 0;
    final followers = json['followers_count'] is int ? json['followers_count'] as int : 0;

    final totalTalksCount = json['total_talks'] is num
        ? (json['total_talks'] as num).toInt()
        : (talksList.isNotEmpty
            ? talksList.length
            : (eventsSpokenList.isNotEmpty
                ? eventsSpokenList.length
                : (json['events_spoken'] is List ? (json['events_spoken'] as List).length : 0)));

    final reputationScore = json['reputation_score'] is num
        ? (json['reputation_score'] as num).toDouble()
        : null;
    final rankTier = json['rank_tier']?.toString();
    final totalReviews = json['total_reviews'] is num
        ? (json['total_reviews'] as num).toInt()
        : (totalFeedback > 0 ? totalFeedback : null);

    return UserProfile(
      id: json['id']?.toString() ?? slugOrId,
      slug: json['slug']?.toString() ?? slugOrId,
      userAccountId: json['user_account']?.toString() ?? json['id']?.toString() ?? slugOrId,
      firstName: firstName,
      lastName: lastName,
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? json['user_account']?.toString() ?? '',
      nationality: json['country']?.toString() ?? json['nationality']?.toString() ?? '',
      avatarPath: avatar,
      organization: json['organization']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      shortBio: json['short_bio']?.toString() ?? '',
      biography: json['long_bio']?.toString() ?? json['biography']?.toString() ?? '',
      socialLinks: socialMap,
      skills: skillsList,
      badges: badges,
      eventsSpoken: eventsSpokenList,
      talks: talksList,
      talksGiven: totalTalksCount,
      attendeesCount: totalFeedback > 0 ? totalFeedback : followers,
      positivePercentage: totalFeedback > 0 ? 100.0 : 0.0,
      averageRating: avgRating,
      reputationScore: reputationScore,
      rankTier: rankTier,
      totalReviews: totalReviews,
    );
  }

  @override
  Future<List<SpeakerTalkItem>> fetchSpeakerTalks(String slugOrId) async {
    final response = await apiClient.get(
      '/speakers/$slugOrId/talks/',
      authenticated: false,
    );

    final list = <SpeakerTalkItem>[];
    List items = [];
    if (response is Map && response['results'] is List) {
      items = response['results'] as List;
    } else if (response is List) {
      items = response;
    }

    for (final raw in items) {
      if (raw is Map) {
        list.add(SpeakerTalkItem(
          id: raw['id']?.toString() ?? 'talk-${list.length}',
          title: raw['title']?.toString() ?? 'Presentation',
          description: raw['description']?.toString() ?? '',
          duration: raw['duration'] is int ? raw['duration'] as int : 30,
          category: raw['category']?.toString() ?? 'Tech',
          eventTitle: raw['event_title']?.toString() ?? '',
          eventId: raw['event']?.toString() ?? raw['event_id']?.toString(),
          eventImage: _sanitizeUrl(raw['event_image']?.toString()),
        ));
      }
    }
    return list;
  }

  @override
  Future<List<SpeakerEventSpoken>> fetchSpeakerExperiences(String slugOrId) async {
    final response = await apiClient.get(
      '/speakers/$slugOrId/experiences/',
      authenticated: false,
    );

    final list = <SpeakerEventSpoken>[];
    List items = [];
    if (response is Map && response['results'] is List) {
      items = response['results'] as List;
    } else if (response is List) {
      items = response;
    }

    for (final raw in items) {
      if (raw is Map) {
        final name = raw['event_name']?.toString() ?? raw['event_title']?.toString() ?? '';
        if (name.isNotEmpty) {
          list.add(SpeakerEventSpoken(
            id: raw['id']?.toString() ?? 'exp-${list.length}',
            name: name,
            topic: raw['topic']?.toString() ?? '',
            date: raw['event_date']?.toString() ?? '',
            image: _sanitizeUrl(raw['event_image']?.toString()),
            eventId: raw['event']?.toString() ?? raw['event_id']?.toString(),
            presentationLink: raw['presentation_link']?.toString(),
            videoRecordingLink: raw['video_recording_link']?.toString(),
            description: raw['description']?.toString(),
          ));
        }
      }
    }
    return list;
  }

  @override
  Future<void> sendSpeakerEmailRequest({
    required String speakerId,
    required String eventName,
    required String location,
    required String message,
  }) async {
    await apiClient.post(
      '/speaker-requests/email-requests/',
      body: {
        'speaker_id': speakerId,
        'event': eventName,
        'location': location,
        'message': message,
      },
      authenticated: true,
    );
  }

  @override
  Future<List<SpeakerBadge>> fetchSpeakerBadges(String slugOrId) async {
    // 1. Fetch all system badge definitions
    final definitions = <Map<String, dynamic>>[];
    try {
      final defResponse = await apiClient.get(
        '/badges/definitions/',
        authenticated: false,
      );
      if (defResponse is List) {
        for (final item in defResponse) {
          if (item is Map<String, dynamic>) {
            definitions.add(item);
          } else if (item is Map) {
            definitions.add(Map<String, dynamic>.from(item));
          }
        }
      }
    } catch (_) {}

    // 2. Fetch the speaker's acquired/eligible badges
    final speakerBadgesMap = <String, Map<String, dynamic>>{};
    try {
      final spkResponse = await apiClient.get(
        '/speakers/$slugOrId/badges/',
        authenticated: false,
      );
      if (spkResponse is List) {
        for (final item in spkResponse) {
          if (item is Map) {
            final m = Map<String, dynamic>.from(item);
            final b = m['badge'] as Map?;
            final slug = b?['slug']?.toString() ?? '';
            if (slug.isNotEmpty) {
              speakerBadgesMap[slug] = m;
            }
          }
        }
      }
    } catch (_) {}

    // Fallback definitions if backend definitions endpoint is unreachable
    if (definitions.isEmpty) {
      definitions.addAll(const [
        {
          'token_id': 1,
          'name': 'Genesis Speaker',
          'slug': 'genesis-speaker',
          'description': 'Delivered their very first verified talk experience on SpeakWise.',
          'tier': 'bronze',
          'emoji': '🎤',
          'criteria': 'Add 1 verified speaking experience to your profile',
        },
        {
          'token_id': 2,
          'name': 'In Demand',
          'slug': 'in-demand',
          'description': 'Received and officially accepted their first direct event invitation.',
          'tier': 'silver',
          'emoji': '⭐',
          'criteria': 'Accept 1 direct speaking invitation from an organizer',
        },
        {
          'token_id': 3,
          'name': 'Crowd Catalyst',
          'slug': 'crowd-catalyst',
          'description': 'Gathered active audience engagement with 5+ community feedbacks.',
          'tier': 'bronze',
          'emoji': '🔥',
          'criteria': 'Collect 5 or more audience feedbacks across talks',
        },
        {
          'token_id': 4,
          'name': 'Road Warrior',
          'slug': 'road-warrior',
          'description': 'Demonstrated sustained impact with 3 or more speaking presentations.',
          'tier': 'silver',
          'emoji': '🌍',
          'criteria': 'Present talks at 3 or more distinct events',
        },
        {
          'token_id': 5,
          'name': 'Five-Star Orator',
          'slug': 'five-star-orator',
          'description': 'Maintained an exceptional average rating of 4.8+ across at least 3 rated talks.',
          'tier': 'gold',
          'emoji': '✨',
          'criteria': 'Achieve 4.8+ average audience rating (min 3 feedbacks)',
        },
        {
          'token_id': 6,
          'name': 'Keynote Pioneer',
          'slug': 'keynote-pioneer',
          'description': 'Reached a legendary milestone of 10 verified speaking appearances.',
          'tier': 'gold',
          'emoji': '🏆',
          'criteria': 'Deliver 10 verified speaking presentations on SpeakWise',
        },
      ]);
    }

    final results = <SpeakerBadge>[];
    for (final def in definitions) {
      final slug = def['slug']?.toString() ?? '';
      final spkEntry = speakerBadgesMap[slug];

      final status = spkEntry?['status']?.toString().toLowerCase() ?? 'locked';
      final isAcquired = status == 'claimed' || status == 'eligible';

      DateTime earnedAt = DateTime.now();
      if (spkEntry?['unlocked_at'] != null) {
        try {
          earnedAt = DateTime.parse(spkEntry!['unlocked_at'].toString());
        } catch (_) {}
      }

      results.add(SpeakerBadge(
        id: spkEntry?['id']?.toString() ?? 'badge-${def['token_id'] ?? slug}',
        slug: slug,
        emoji: def['emoji']?.toString() ?? '🥇',
        title: def['name']?.toString() ?? 'Badge',
        subtitle: (def['tier']?.toString() ?? 'tier').toUpperCase(),
        description: def['description']?.toString() ?? 'Verified speaker badge',
        tier: (def['tier']?.toString() ?? 'bronze').toLowerCase(),
        criteria: def['criteria']?.toString() ?? '',
        status: status,
        isAcquired: isAcquired,
        earnedAt: earnedAt,
      ));
    }

    return results;
  }

  @override
  Future<UserProfile> updateSpeakerProfile(UserProfile profile) async {
    return profile;
  }
}

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DjangoProfileRemoteDataSource(apiClient: apiClient);
});
