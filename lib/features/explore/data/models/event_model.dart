/// ═══════════════════════════════════════════════════════════════
/// SpeakWise Event, Category, Speaker & Talk Models
/// ═══════════════════════════════════════════════════════════════
class EventCategory {
  final String id;
  final String name;
  final String imagePath;

  const EventCategory({
    required this.id,
    required this.name,
    required this.imagePath,
  });
}

class EventItem {
  final String id;
  final String title;
  final String location;
  final String date;
  final String imagePath;
  final String? dateBadgeMonth;
  final String? dateBadgeDay;
  final bool isTicketed;
  final String description;
  final String bannerSubtitle;
  final String categoryId;
  final String ticketPrice;
  final List<EventSpeaker> speakers;
  final String time;
  final String attendeeCount;
  final String subtitle;
  final String? slug;
  final String? country;
  final bool? isFree;
  final bool isFeatured;
  final bool cfpOpen;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final String? website;

  const EventItem({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.imagePath,
    this.dateBadgeMonth,
    this.dateBadgeDay,
    this.isTicketed = false,
    this.description =
        "Join the vibrant community for an immersive gathering of engineers, innovators, and leaders. Experience hands-on technical sessions, keynote presentations from world-class architects, and network with creators from across Africa and beyond.",
    this.bannerSubtitle = "Planning your next tech event? Add this to your calendar.",
    this.categoryId = 'africa',
    this.ticketPrice = '\$20',
    this.speakers = const [],
    this.time = '08:00 AM',
    this.attendeeCount = '3k+',
    this.subtitle = '',
    this.slug,
    this.country,
    this.isFree,
    this.isFeatured = false,
    this.cfpOpen = false,
    this.startDateTime,
    this.endDateTime,
    this.website,
  });

  /// Location with country included (avoids duplicates if country is already in location)
  String get fullLocation {
    final loc = location.trim();
    final c = (country ?? '').trim();
    if (c.isEmpty) return loc;
    if (loc.isEmpty) return c;
    final locLower = loc.toLowerCase();
    final cLower = c.toLowerCase();
    if (locLower.contains(cLower) ||
        (cLower == 'uk' && (locLower.contains('united kingdom') || locLower.contains(', uk'))) ||
        (cLower == 'united kingdom' && (locLower.contains('uk') || locLower.contains('united kingdom'))) ||
        (cLower == 'usa' && (locLower.contains('united states') || locLower.contains(', usa') || locLower.contains(', us'))) ||
        (cLower == 'united states' && (locLower.contains('usa') || locLower.contains('united states')))) {
      return loc;
    }
    return '$loc, $c';
  }
}

class EventSpeaker {
  final String id;
  final String name;
  final String role;
  final String avatarPath;
  final double rating;
  final int talksGiven;
  final String badge;
  final String topic;
  final double? reputationScore;
  final int? totalReviews;
  final String? rankTier;
  final String? username;
  final String? slug;
  final int badgesCount;

  const EventSpeaker({
    required this.id,
    required this.name,
    required this.role,
    required this.avatarPath,
    this.rating = 4.9,
    this.talksGiven = 12,
    this.badge = 'Top Speaker',
    this.topic = '',
    this.reputationScore,
    this.totalReviews,
    this.rankTier,
    this.username,
    this.slug,
    this.badgesCount = 5,
  });
}

class TrendingSession {
  final String id;
  final String title;
  final String speakerName;
  final String speakerAvatar;
  final String time;
  final String eventTitle;
  final double rating;
  final List<String> tags;

  const TrendingSession({
    required this.id,
    required this.title,
    required this.speakerName,
    required this.speakerAvatar,
    required this.time,
    required this.eventTitle,
    this.rating = 4.95,
    this.tags = const [],
  });
}
