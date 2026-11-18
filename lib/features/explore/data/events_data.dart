import 'package:speakwise_mobile/features/explore/data/models/event_model.dart';

/// ═══════════════════════════════════════════════════════════════
/// Centralized Mock Events, Speakers & Sessions Repository
/// ═══════════════════════════════════════════════════════════════
class EventsData {
  static const List<EventCategory> categories = [
    EventCategory(
      id: 'all',
      name: 'All',
      imagePath: 'assets/images/cat_africa.jpg',
    ),
    EventCategory(
      id: 'africa',
      name: 'Africa',
      imagePath: 'assets/images/cat_africa.jpg',
    ),
    EventCategory(
      id: 'europe',
      name: 'Europe',
      imagePath: 'assets/images/cat_europe.jpg',
    ),
    EventCategory(
      id: 'america',
      name: 'America',
      imagePath: 'assets/images/cat_america.jpg',
    ),
    EventCategory(
      id: 'asia',
      name: 'Asia',
      imagePath: 'assets/images/cat_asia.jpg',
    ),
  ];

  static const List<EventSpeaker> topSpeakers = [
    EventSpeaker(
      id: 'spk-1',
      name: 'Julius Boakye',
      role: 'Staff Systems Architect',
      avatarPath: 'assets/images/Julius.png',
      rating: 4.96,
      talksGiven: 24,
      badge: 'Master Storyteller 🥇',
      topic: 'Distributed Web3 on Stellar',
    ),
    EventSpeaker(
      id: 'spk-2',
      name: 'Juliana Lawson',
      role: 'Principal Design Technologist',
      avatarPath: 'assets/images/Juliana.jpg',
      rating: 4.92,
      talksGiven: 18,
      badge: 'High Engagement ⚡',
      topic: 'Design Systems That Scale',
    ),
    EventSpeaker(
      id: 'spk-3',
      name: 'Ezra Yendau',
      role: 'CTO & Core Maintainer',
      avatarPath: 'assets/images/ezra.jpg',
      rating: 4.88,
      talksGiven: 15,
      badge: 'Top Rated 2026 🌟',
      topic: 'Flutter & Edge AI Inference',
    ),
  ];

  static const List<TrendingSession> trendingSessions = [
    TrendingSession(
      id: 'ses-1',
      title: 'Architecting Scalable Web3 Backends on Stellar',
      speakerName: 'Julius Boakye',
      speakerAvatar: 'assets/images/Julius.png',
      time: 'Today • 14:00 GMT',
      eventTitle: 'Cortex Dev Summit 2026',
      rating: 4.96,
      tags: ['#Stellar', '#DistributedSystems', '#Rust'],
    ),
    TrendingSession(
      id: 'ses-2',
      title: 'Design Systems That Scale Across Millions of Users',
      speakerName: 'Juliana Lawson',
      speakerAvatar: 'assets/images/Juliana.jpg',
      time: 'Today • 15:30 GMT',
      eventTitle: 'PyCon Ghana 2027',
      rating: 4.92,
      tags: ['#UIUX', '#DesignTokens', '#Flutter'],
    ),
    TrendingSession(
      id: 'ses-3',
      title: 'Real-time Edge Inference with On-Device AI Models',
      speakerName: 'Ezra Yendau',
      speakerAvatar: 'assets/images/ezra.jpg',
      time: 'Tomorrow • 11:00 GMT',
      eventTitle: 'Google I/O Extended Accra',
      rating: 4.88,
      tags: ['#OnDeviceAI', '#MobilePerformance', '#Edge'],
    ),
  ];

  static final List<EventItem> allEvents = [
    EventItem(
      id: 'pycon-gh-2027',
      title: 'PyCon Ghana 2027',
      isFeatured: true,
      cfpOpen: true,
      location: 'ALX Tech Hub. Accra, Ghana',
      date: 'May 20 - 24, 2027',
      dateBadgeMonth: 'May',
      dateBadgeDay: '20',
      startDateTime: DateTime(2027, 5, 20),
      endDateTime: DateTime(2027, 5, 24),
      imagePath: 'assets/images/pycon_ghana.jpg',
      isTicketed: true,
      ticketPrice: '',
      bannerSubtitle: "West Africa's largest Python, Cloud & Data Gathering. Add this to your calendar.",
      description:
          "PyCon Ghana 2027 brings together over 1,200 developers, students, researchers, and tech founders to Accra. Explore emerging patterns in AI, Cloud infrastructure, and decentralization across 3 specialized tracks.",
      speakers: const [
        EventSpeaker(
          id: 'spk-1',
          name: 'Julius Boakye',
          role: 'Staff Systems Architect',
          avatarPath: 'assets/images/Julius.png',
          rating: 4.96,
          talksGiven: 24,
          badge: 'Keynote Speaker',
          topic: 'Decentralized Microservices at Scale',
        ),
        EventSpeaker(
          id: 'spk-2',
          name: 'Juliana Lawson',
          role: 'Staff Designer',
          avatarPath: 'assets/images/Juliana.jpg',
          rating: 4.92,
          talksGiven: 18,
          badge: 'Track Lead',
          topic: 'Accessible Mobile UI Systems',
        ),
      ],
    ),
    EventItem(
      id: 'pycon-namibia-27',
      title: 'PyCon Namibia 27',
      location: 'Windhoek, Namibia',
      date: '25 February - 31 March',
      dateBadgeMonth: 'Feb',
      dateBadgeDay: '25',
      startDateTime: DateTime(2027, 2, 25),
      endDateTime: DateTime(2027, 3, 31),
      imagePath: 'assets/images/pycon_namibia.jpg',
      isTicketed: true,
      ticketPrice: '',
      bannerSubtitle: 'Planning your next PyCon event in 2027? Add this to your calendar',
      description:
          "Join the vibrant Python community in Namibia for 3 days of talks, hands-on workshops, keynotes from world-class engineers, and networking sessions. Whether you're building Web3 backends, AI applications, or distributed systems, PyCon Namibia brings together developers, open-source contributors, and industry leaders from across Africa and beyond.",
      speakers: const [
        EventSpeaker(
          id: 'spk-2',
          name: 'Juliana Lawson',
          role: 'Principal Design Technologist',
          avatarPath: 'assets/images/Juliana.jpg',
          rating: 4.92,
          talksGiven: 18,
          badge: 'Keynote Speaker',
          topic: 'Designing Developer Ecosystems',
        ),
        EventSpeaker(
          id: 'spk-3',
          name: 'Ezra Yendau',
          role: 'CTO & Core Maintainer',
          avatarPath: 'assets/images/ezra.jpg',
          rating: 4.88,
          talksGiven: 15,
          badge: 'Featured Speaker',
          topic: 'High-Throughput Python on ARM',
        ),
      ],
    ),
    EventItem(
      id: 'pycon-angola',
      title: 'PyCon Angola 2027',
      location: 'Luanda, Angola',
      date: 'Feb 27 - 21 March',
      dateBadgeMonth: 'Feb',
      dateBadgeDay: '27',
      startDateTime: DateTime(2027, 2, 27),
      endDateTime: DateTime(2027, 3, 21),
      imagePath: 'assets/images/pycon_angola.jpg',
      isTicketed: true,
      ticketPrice: '',
      bannerSubtitle: 'Connecting Portuguese-speaking developers across Southern Africa.',
      description:
          "The premier software conference in Luanda uniting open-source builders, fintech founders, and engineers to collaborate on resilient backend systems and digital infrastructure.",
    ),
    EventItem(
      id: 'cortex-summit-2026',
      title: 'Cortex Dev Summit 2026',
      isFeatured: true,
      location: 'Main Auditorium, National Theatre, Accra',
      date: 'Nov 15 - 17, 2026',
      dateBadgeMonth: 'Nov',
      dateBadgeDay: '15',
      startDateTime: DateTime(2026, 11, 15),
      endDateTime: DateTime(2026, 11, 17),
      imagePath: 'assets/images/cortex_summit.jpg',
      isTicketed: true,
      ticketPrice: '',
      bannerSubtitle: 'Architecting Scalable Systems & Next-Gen Mobile Infrastructure.',
      description:
          "West Africa's flagship engineering conference focusing on high-throughput backend architecture, mobile apps in Flutter, and non-custodial Stellar smart contracts.",
    ),
    EventItem(
      id: 'redsketch-academy',
      title: 'Redsketch Academy',
      subtitle: 'Video Editing',
      location: 'Valencia, otra calle',
      date: 'Tomorrow • 08:00 AM',
      dateBadgeMonth: 'Nov',
      dateBadgeDay: '14',
      time: '08:00 AM',
      attendeeCount: '3k+',
      startDateTime: DateTime(2026, 11, 14, 8),
      imagePath: 'assets/images/cortex_summit.jpg',
      isTicketed: true,
      ticketPrice: '',
      bannerSubtitle: 'Creative visual storytelling & modern digital post-production.',
      description:
          'Hands-on masterclass covering real-time non-linear editing, high-framerate motion graphics, and audio synthesis for creators.',
    ),
    EventItem(
      id: 'drawing-academy',
      title: 'The Drawing Academy',
      subtitle: 'Painting Focus',
      location: 'Valencia, otra calle',
      date: 'Saturday • 10:00 AM',
      dateBadgeMonth: 'Nov',
      dateBadgeDay: '16',
      time: '10:00 AM',
      attendeeCount: '3k+',
      startDateTime: DateTime(2026, 11, 16, 10),
      imagePath: 'assets/images/google_io_accra.jpg',
      isTicketed: true,
      ticketPrice: '',
      bannerSubtitle: 'Color theory, digital brushwork and anatomy fundamentals.',
      description:
          'An intensive workshop designed for conceptual artists and UI designers looking to master visual rendering and lighting.',
    ),
    EventItem(
      id: 'sundance-festival',
      title: 'Sundance Film Festival (Park City, Utah)',
      subtitle: 'Creative Showcase',
      location: 'Park City, Utah',
      date: 'Next Week • 02:00 PM',
      dateBadgeMonth: 'Nov',
      dateBadgeDay: '22',
      time: '02:00 PM',
      attendeeCount: '3k+',
      startDateTime: DateTime(2026, 11, 22, 14),
      imagePath: 'assets/images/pycon_namibia.jpg',
      isTicketed: true,
      ticketPrice: '',
      bannerSubtitle: 'Premier independent cinema and creative technology.',
      description:
          'World premiere screenings, director panels, and interactive technology demonstrations bridging cinema and generative digital media.',
    ),
  ];

  static List<EventItem> get upcomingEvents => [
        allEvents.firstWhere((e) => e.id == 'redsketch-academy'),
        allEvents.firstWhere((e) => e.id == 'drawing-academy'),
        allEvents.firstWhere((e) => e.id == 'sundance-festival'),
        allEvents.firstWhere((e) => e.id == 'cortex-summit-2026'),
      ];

  static EventItem getEventById(String id) {
    return allEvents.firstWhere(
      (e) => e.id == id,
      orElse: () => allEvents.first,
    );
  }
}
