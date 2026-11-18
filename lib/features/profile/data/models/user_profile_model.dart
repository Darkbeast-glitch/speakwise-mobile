/// Model representing digital badges earned or defined on SpeakWise
class SpeakerBadge {
  final String id;
  final String emoji;
  final String title;
  final String subtitle;
  final String description;
  final String tier; // e.g. "bronze", "silver", "gold"
  final DateTime earnedAt;
  final bool isAcquired;
  final String status; // 'claimed', 'eligible', 'locked'
  final String criteria;
  final String slug;

  const SpeakerBadge({
    required this.id,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.tier,
    required this.earnedAt,
    this.isAcquired = true,
    this.status = 'claimed',
    this.criteria = '',
    this.slug = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'emoji': emoji,
        'title': title,
        'subtitle': subtitle,
        'description': description,
        'tier': tier,
        'earnedAt': earnedAt.toIso8601String(),
        'isAcquired': isAcquired,
        'status': status,
        'criteria': criteria,
        'slug': slug,
      };

  factory SpeakerBadge.fromJson(Map<String, dynamic> json) => SpeakerBadge(
        id: json['id']?.toString() ?? '',
        emoji: json['emoji']?.toString() ?? '🏆',
        title: json['title']?.toString() ?? '',
        subtitle: json['subtitle']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        tier: json['tier']?.toString() ?? 'bronze',
        earnedAt: json['earnedAt'] != null
            ? DateTime.tryParse(json['earnedAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        isAcquired: json['isAcquired'] != false,
        status: json['status']?.toString() ?? 'claimed',
        criteria: json['criteria']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
      );
}

/// Model representing a conference or event where the speaker has spoken
class SpeakerEventSpoken {
  final String id;
  final String name;
  final String topic;
  final String date;
  final String image;
  final String? eventId;
  final String? presentationLink;
  final String? videoRecordingLink;
  final String? description;

  const SpeakerEventSpoken({
    required this.id,
    required this.name,
    this.topic = '',
    this.date = '',
    this.image = '',
    this.eventId,
    this.presentationLink,
    this.videoRecordingLink,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'topic': topic,
        'date': date,
        'image': image,
        'eventId': eventId,
        'presentationLink': presentationLink,
        'videoRecordingLink': videoRecordingLink,
        'description': description,
      };

  factory SpeakerEventSpoken.fromJson(Map<String, dynamic> json) =>
      SpeakerEventSpoken(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        topic: json['topic']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        image: json['image']?.toString() ?? '',
        eventId: json['eventId']?.toString(),
        presentationLink: json['presentationLink']?.toString(),
        videoRecordingLink: json['videoRecordingLink']?.toString(),
        description: json['description']?.toString(),
      );
}

/// Model representing a talk or presentation given by the speaker
class SpeakerTalkItem {
  final String id;
  final String title;
  final String description;
  final int duration;
  final String category;
  final String eventTitle;
  final String? eventId;
  final String eventImage;
  final String? presentationLink;
  final String? videoRecordingLink;
  final String? date;

  const SpeakerTalkItem({
    required this.id,
    required this.title,
    this.description = '',
    this.duration = 30,
    this.category = 'Talk',
    this.eventTitle = '',
    this.eventId,
    this.eventImage = '',
    this.presentationLink,
    this.videoRecordingLink,
    this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'duration': duration,
        'category': category,
        'eventTitle': eventTitle,
        'eventId': eventId,
        'eventImage': eventImage,
        'presentationLink': presentationLink,
        'videoRecordingLink': videoRecordingLink,
        'date': date,
      };

  factory SpeakerTalkItem.fromJson(Map<String, dynamic> json) =>
      SpeakerTalkItem(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        duration: (json['duration'] as num?)?.toInt() ?? 30,
        category: json['category']?.toString() ?? 'Talk',
        eventTitle: json['eventTitle']?.toString() ?? '',
        eventId: json['eventId']?.toString(),
        eventImage: json['eventImage']?.toString() ?? '',
        presentationLink: json['presentationLink']?.toString(),
        videoRecordingLink: json['videoRecordingLink']?.toString(),
        date: json['date']?.toString(),
      );
}

/// Model representing complete speaker profile information
class UserProfile {
  final String id;
  final String slug;
  final String userAccountId;
  final String firstName;
  final String lastName;
  final String email;
  final String username;
  final String nationality;
  final String avatarPath;
  final String organization;
  final String country;
  final String shortBio;
  final String biography;
  final Map<String, String> socialLinks; // linkedin, twitter, github, instagram, youtube, website
  final List<String> skills;
  final List<SpeakerBadge> badges;
  final List<SpeakerEventSpoken> eventsSpoken;
  final List<SpeakerTalkItem> talks;
  final int talksGiven;
  final int attendeesCount;
  final double positivePercentage;
  final double averageRating;
  final double? reputationScore;
  final String? rankTier;
  final int? totalReviews;
  final bool isFollowing;

  const UserProfile({
    this.id = '',
    this.slug = '',
    this.userAccountId = '',
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    required this.nationality,
    required this.avatarPath,
    required this.organization,
    required this.country,
    required this.shortBio,
    required this.biography,
    required this.socialLinks,
    required this.skills,
    required this.badges,
    this.eventsSpoken = const [],
    this.talks = const [],
    required this.talksGiven,
    required this.attendeesCount,
    required this.positivePercentage,
    required this.averageRating,
    this.reputationScore,
    this.rankTier,
    this.totalReviews,
    this.isFollowing = false,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get speakerSlug => slug;

  UserProfile copyWith({
    String? id,
    String? slug,
    String? userAccountId,
    String? firstName,
    String? lastName,
    String? email,
    String? username,
    String? nationality,
    String? avatarPath,
    String? organization,
    String? country,
    String? shortBio,
    String? biography,
    Map<String, String>? socialLinks,
    List<String>? skills,
    List<SpeakerBadge>? badges,
    List<SpeakerEventSpoken>? eventsSpoken,
    List<SpeakerTalkItem>? talks,
    int? talksGiven,
    int? attendeesCount,
    double? positivePercentage,
    double? averageRating,
    double? reputationScore,
    String? rankTier,
    int? totalReviews,
    bool? isFollowing,
  }) {
    return UserProfile(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      userAccountId: userAccountId ?? this.userAccountId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      username: username ?? this.username,
      nationality: nationality ?? this.nationality,
      avatarPath: avatarPath ?? this.avatarPath,
      organization: organization ?? this.organization,
      country: country ?? this.country,
      shortBio: shortBio ?? this.shortBio,
      biography: biography ?? this.biography,
      socialLinks: socialLinks ?? this.socialLinks,
      skills: skills ?? this.skills,
      badges: badges ?? this.badges,
      eventsSpoken: eventsSpoken ?? this.eventsSpoken,
      talks: talks ?? this.talks,
      talksGiven: talksGiven ?? this.talksGiven,
      attendeesCount: attendeesCount ?? this.attendeesCount,
      positivePercentage: positivePercentage ?? this.positivePercentage,
      averageRating: averageRating ?? this.averageRating,
      reputationScore: reputationScore ?? this.reputationScore,
      rankTier: rankTier ?? this.rankTier,
      totalReviews: totalReviews ?? this.totalReviews,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'userAccountId': userAccountId,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'username': username,
        'nationality': nationality,
        'avatarPath': avatarPath,
        'organization': organization,
        'country': country,
        'shortBio': shortBio,
        'biography': biography,
        'socialLinks': socialLinks,
        'skills': skills,
        'badges': badges.map((b) => b.toJson()).toList(),
        'eventsSpoken': eventsSpoken.map((e) => e.toJson()).toList(),
        'talks': talks.map((t) => t.toJson()).toList(),
        'talksGiven': talksGiven,
        'attendeesCount': attendeesCount,
        'positivePercentage': positivePercentage,
        'averageRating': averageRating,
        'reputationScore': reputationScore,
        'rankTier': rankTier,
        'totalReviews': totalReviews,
        'isFollowing': isFollowing,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        userAccountId: json['userAccountId']?.toString() ?? '',
        firstName: json['firstName']?.toString() ?? '',
        lastName: json['lastName']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        username: json['username']?.toString() ?? '',
        nationality: json['nationality']?.toString() ?? '',
        avatarPath: json['avatarPath']?.toString() ?? '',
        organization: json['organization']?.toString() ?? '',
        country: json['country']?.toString() ?? '',
        shortBio: json['shortBio']?.toString() ?? '',
        biography: json['biography']?.toString() ?? '',
        socialLinks: (json['socialLinks'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            ) ??
            const {},
        skills: (json['skills'] as List?)
                ?.map((s) => s.toString())
                .toList() ??
            const [],
        badges: (json['badges'] as List?)
                ?.map((b) => SpeakerBadge.fromJson(b as Map<String, dynamic>))
                .toList() ??
            const [],
        eventsSpoken: (json['eventsSpoken'] as List?)
                ?.map((e) =>
                    SpeakerEventSpoken.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        talks: (json['talks'] as List?)
                ?.map((t) =>
                    SpeakerTalkItem.fromJson(t as Map<String, dynamic>))
                .toList() ??
            const [],
        talksGiven: (json['talksGiven'] as num?)?.toInt() ?? 0,
        attendeesCount: (json['attendeesCount'] as num?)?.toInt() ?? 0,
        positivePercentage:
            (json['positivePercentage'] as num?)?.toDouble() ?? 0.0,
        averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
        reputationScore: (json['reputationScore'] as num?)?.toDouble(),
        rankTier: json['rankTier']?.toString(),
        totalReviews: (json['totalReviews'] as num?)?.toInt(),
        isFollowing: json['isFollowing'] == true,
      );
}
