import 'package:flutter/material.dart';

/// Model representing a speaker's conference talk or presentation
class SpeakingTalk {
  final String id;
  final String eventName;
  final String eventDate;
  final String title;
  final String description;
  final String? presentationUrl;
  final String? videoUrl;
  final String qrCodeUrl;
  final double rating;
  final int reviewsCount;
  final bool isLive;
  final List<Color> coverGradient;
  final DateTime createdAt;

  const SpeakingTalk({
    required this.id,
    required this.eventName,
    required this.eventDate,
    required this.title,
    required this.description,
    this.presentationUrl,
    this.videoUrl,
    required this.qrCodeUrl,
    required this.rating,
    required this.reviewsCount,
    this.isLive = false,
    this.coverGradient = const [Color(0xFF2E1229), Color(0xFF13091B)],
    required this.createdAt,
  });

  SpeakingTalk copyWith({
    String? id,
    String? eventName,
    String? eventDate,
    String? title,
    String? description,
    String? presentationUrl,
    String? videoUrl,
    String? qrCodeUrl,
    double? rating,
    int? reviewsCount,
    bool? isLive,
    List<Color>? coverGradient,
    DateTime? createdAt,
  }) {
    return SpeakingTalk(
      id: id ?? this.id,
      eventName: eventName ?? this.eventName,
      eventDate: eventDate ?? this.eventDate,
      title: title ?? this.title,
      description: description ?? this.description,
      presentationUrl: presentationUrl ?? this.presentationUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      isLive: isLive ?? this.isLive,
      coverGradient: coverGradient ?? this.coverGradient,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventName': eventName,
        'eventDate': eventDate,
        'title': title,
        'description': description,
        'presentationUrl': presentationUrl,
        'videoUrl': videoUrl,
        'qrCodeUrl': qrCodeUrl,
        'rating': rating,
        'reviewsCount': reviewsCount,
        'isLive': isLive,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SpeakingTalk.fromJson(Map<String, dynamic> json) => SpeakingTalk(
        id: json['id']?.toString() ?? '',
        eventName: json['eventName']?.toString() ?? '',
        eventDate: json['eventDate']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        presentationUrl: json['presentationUrl']?.toString(),
        videoUrl: json['videoUrl']?.toString(),
        qrCodeUrl: json['qrCodeUrl']?.toString() ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
        isLive: json['isLive'] == true,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}

/// Model representing feedback submitted by an attendee
class FeedbackReview {
  final String id;
  final String talkId;
  final String talkTitle;
  final String eventName;
  final String attendeeName;
  final String attendeeAvatar;
  final double score; // e.g. 9.3 out of 10
  final String timeAgo;
  final String comment;
  final List<String> sentimentTags;
  final Map<String, double> dimensionBreakdown;

  const FeedbackReview({
    required this.id,
    required this.talkId,
    required this.talkTitle,
    required this.eventName,
    required this.attendeeName,
    required this.attendeeAvatar,
    required this.score,
    required this.timeAgo,
    required this.comment,
    required this.sentimentTags,
    required this.dimensionBreakdown,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'talkId': talkId,
        'talkTitle': talkTitle,
        'eventName': eventName,
        'attendeeName': attendeeName,
        'attendeeAvatar': attendeeAvatar,
        'score': score,
        'timeAgo': timeAgo,
        'comment': comment,
        'sentimentTags': sentimentTags,
        'dimensionBreakdown': dimensionBreakdown,
      };

  factory FeedbackReview.fromJson(Map<String, dynamic> json) => FeedbackReview(
        id: json['id']?.toString() ?? '',
        talkId: json['talkId']?.toString() ?? '',
        talkTitle: json['talkTitle']?.toString() ?? '',
        eventName: json['eventName']?.toString() ?? '',
        attendeeName: json['attendeeName']?.toString() ?? 'Attendee',
        attendeeAvatar: json['attendeeAvatar']?.toString() ?? '',
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
        timeAgo: json['timeAgo']?.toString() ?? 'Recently',
        comment: json['comment']?.toString() ?? '',
        sentimentTags: (json['sentimentTags'] as List?)
                ?.map((t) => t.toString())
                .toList() ??
            const [],
        dimensionBreakdown: (json['dimensionBreakdown'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
            ) ??
            const {},
      );
}

/// Dimension Analysis Model (Audience Engagement, Speech Clarity, etc.)
class DimensionAnalysis {
  final double overallScore;
  final double engagementScore;
  final double clarityScore;
  final double technicalDepthScore;
  final double practicalRelevanceScore;

  const DimensionAnalysis({
    required this.overallScore,
    required this.engagementScore,
    required this.clarityScore,
    required this.technicalDepthScore,
    required this.practicalRelevanceScore,
  });

  Map<String, dynamic> toJson() => {
        'overallScore': overallScore,
        'engagementScore': engagementScore,
        'clarityScore': clarityScore,
        'technicalDepthScore': technicalDepthScore,
        'practicalRelevanceScore': practicalRelevanceScore,
      };

  factory DimensionAnalysis.fromJson(Map<String, dynamic> json) =>
      DimensionAnalysis(
        overallScore: (json['overallScore'] as num?)?.toDouble() ?? 0.0,
        engagementScore: (json['engagementScore'] as num?)?.toDouble() ?? 0.0,
        clarityScore: (json['clarityScore'] as num?)?.toDouble() ?? 0.0,
        technicalDepthScore:
            (json['technicalDepthScore'] as num?)?.toDouble() ?? 0.0,
        practicalRelevanceScore:
            (json['practicalRelevanceScore'] as num?)?.toDouble() ?? 0.0,
      );
}
