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
}
