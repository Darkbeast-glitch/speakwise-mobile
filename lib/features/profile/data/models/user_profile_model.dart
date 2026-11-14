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
}

/// Model representing a conference or event where the speaker has spoken
class SpeakerEventSpoken {
  final String id;
  final String name;
  final String topic;
  final String date;
  final String image;
  final String? eventId;

  const SpeakerEventSpoken({
    required this.id,
    required this.name,
    this.topic = '',
    this.date = '',
    this.image = '',
    this.eventId,
  });
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

  const SpeakerTalkItem({
    required this.id,
    required this.title,
    this.description = '',
    this.duration = 30,
    this.category = 'Keynote',
    this.eventTitle = '',
    this.eventId,
    this.eventImage = '',
  });
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
  });

  String get fullName => '$firstName $lastName'.trim();

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
    );
  }
}
