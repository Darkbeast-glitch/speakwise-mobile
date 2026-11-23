import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakwise_mobile/app/app.dart';
import 'package:speakwise_mobile/core/config/app_constants.dart';
import 'package:speakwise_mobile/core/services/storage_service.dart';
import 'package:speakwise_mobile/features/auth/data/auth_remote_datasource.dart';
import 'package:speakwise_mobile/features/explore/data/events_data.dart';
import 'package:speakwise_mobile/features/explore/data/events_repository.dart';
import 'package:speakwise_mobile/features/explore/data/models/event_model.dart';
import 'package:speakwise_mobile/features/profile/data/models/user_profile_model.dart';
import 'package:speakwise_mobile/features/profile/data/profile_repository.dart';
import 'package:speakwise_mobile/features/profile/viewmodel/profile_provider.dart';

class _TestAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  Future<AuthResponse> login({required String email, required String password}) async {
    return const AuthResponse(
      id: 'usr_1',
      email: 'speaker@example.com',
      firstName: 'Julius',
      lastName: 'Boakye',
      username: 'juliusb',
      accessToken: 'test_jwt_access',
      refreshToken: 'test_jwt_refresh',
      speakerId: 'spk_123',
    );
  }

  @override
  Future<RegisterResponse> register({
    required String firstName,
    required String lastName,
    required String nationality,
    required String username,
    required String email,
    required String password,
  }) async {
    return const RegisterResponse(
      id: 'usr_1',
      email: 'speaker@example.com',
      firstName: 'Julius',
      lastName: 'Boakye',
      username: 'juliusb',
      message: 'Verification code sent.',
    );
  }

  @override
  Future<String> verifyOtp({required String email, required String otp}) async {
    return 'Email verified successfully.';
  }

  @override
  Future<String> resendOtp({required String email}) async {
    return 'Code resent.';
  }

  @override
  Future<String> requestPasswordReset({required String email}) async {
    return 'Password reset email sent successfully.';
  }

  @override
  Future<String> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    return 'Password reset successfully.';
  }

  @override
  Future<void> logout() async {}

  @override
  Future<bool> validateSession() async => true;

  @override
  Future<AuthResponse> exchangeOAuthCode(String code) async {
    return login(email: 'speaker@example.com', password: 'password');
  }
}

class _TestEventsRepository implements EventsRepository {
  @override
  Future<List<EventItem>> getEvents({
    String? search,
    String? country,
    String? region,
    String? timePeriod,
    bool? isFree,
    bool? cfpOpen,
    bool? isFeatured,
    int? page,
    int? limit,
  }) async {
    var list = EventsData.allEvents;
    if (search != null && search.isNotEmpty) {
      list = list.where((e) =>
        e.title.toLowerCase().contains(search.toLowerCase()) ||
        e.location.toLowerCase().contains(search.toLowerCase()) ||
        (e.country?.toLowerCase().contains(search.toLowerCase()) ?? false)
      ).toList();
    }
    if (isFeatured == true) {
      return list.where((e) => e.isFeatured).toList();
    }
    return list;
  }

  @override
  Future<List<EventItem>> getFeaturedEvents() async {
    return EventsData.allEvents.where((e) => e.isFeatured).toList();
  }

  @override
  Future<EventItem?> getEventDetail(String idOrSlug) async {
    return EventsData.getEventById(idOrSlug);
  }

  @override
  Future<List<EventSpeaker>> getTopSpeakers({
    bool top = true,
    String? ordering,
  }) async {
    return EventsData.topSpeakers;
  }

  @override
  Future<List<EventSpeaker>> getSpeakers({
    bool? top,
    String? ordering,
    String? search,
    int? page,
    int? pageSize,
  }) async {
    return EventsData.topSpeakers;
  }

  @override
  Future<List<EventItem>> getUpcomingEvents() async {
    return EventsData.upcomingEvents;
  }
}

class _TestProfileRepository implements ProfileRepository {
  static final UserProfile _mockProfile = UserProfile(
    id: 'usr_1',
    slug: 'juliusboakye',
    firstName: 'Nana',
    lastName: 'Acheampong',
    email: 'speaker@example.com',
    username: 'juliusboakye',
    organization: 'JNAB TECH SOLUTIONS',
    country: 'Ghana',
    nationality: 'Ghanaian',
    avatarPath: 'assets/images/Julius.png',
    shortBio: 'Staff Systems Architect & Tech Community Lead.',
    biography: 'Julius Nana Acheampong Boakye is a prominent Ghanaian software engineer.',
    socialLinks: const {},
    skills: const ['Django', 'Flutter', 'FullStack Engineer'],
    badges: [
      SpeakerBadge(
        id: 'b1',
        title: 'Master Storyteller',
        emoji: '🥇',
        subtitle: 'High Impact Speaker',
        description: 'Delivered engaging keynote talks',
        tier: 'gold',
        earnedAt: DateTime(2026, 1, 1),
        isAcquired: true,
      ),
    ],
    eventsSpoken: const [
      SpeakerEventSpoken(
        id: 'evt-1',
        name: 'PyCon Ghana',
        topic: 'Distributed Web3 on Stellar',
        date: '2027-05-20',
        image: 'assets/images/pycon_ghana.jpg',
      ),
      SpeakerEventSpoken(
        id: 'evt-2',
        name: 'DevFest Accra 2026',
        topic: 'Mobile Architecture',
        date: '2026-11-15',
        image: '',
      ),
    ],
    talks: const [
      SpeakerTalkItem(
        id: 'tlk-1',
        title: 'Distributed Web3 on Stellar',
        eventTitle: 'PyCon Ghana 2027',
      ),
    ],
    talksGiven: 24,
    attendeesCount: 1250,
    positivePercentage: 98,
    averageRating: 4.96,
  );

  @override
  Future<UserProfile> getUserProfile() async => _mockProfile;

  @override
  Future<UserProfile> getSpeakerProfile(String slugOrId) async => _mockProfile;

  @override
  Future<UserProfile> updateProfile(UserProfile updated) async => updated;

  @override
  Future<bool> sendSpeakerEmailRequest({
    required String speakerId,
    required String eventName,
    required String location,
    required String message,
  }) async => true;

  @override
  Future<bool> toggleFollowSpeaker(String slugOrId) async => true;
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('SpeakWise Onboarding "Get Started" navigates to Auth Gateway Screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRemoteDataSourceProvider.overrideWithValue(_TestAuthRemoteDataSource()),
          eventsRepositoryProvider.overrideWithValue(_TestEventsRepository()),
          profileRepositoryProvider.overrideWithValue(_TestProfileRepository()),
        ],
        child: const SpeakWiseApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial slide
    expect(find.text('SpeakWise'), findsWidgets);
    expect(find.text('Continue'), findsOneWidget);

    // Tap "Continue" to slide 2
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Tap "Continue" to slide 3
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Verify slide 3 has "Get Started"
    expect(find.text('Get Started'), findsOneWidget);

    // Tap "Get Started"
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Verify user is taken to the Auth Gateway Screen
    expect(find.textContaining('Elevate Your Voice'), findsOneWidget);
    expect(find.textContaining('Measure Your Impact'), findsOneWidget);
    expect(find.text('Continue with Email'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('SpeakWise Auth Gateway and Multi-Screen Navigation test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRemoteDataSourceProvider.overrideWithValue(_TestAuthRemoteDataSource()),
          eventsRepositoryProvider.overrideWithValue(_TestEventsRepository()),
          profileRepositoryProvider.overrideWithValue(_TestProfileRepository()),
        ],
        child: const SpeakWiseApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Skip on onboarding to reach the Auth Gateway Screen
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // Verify Auth Gateway Screen components matching reference
    expect(find.textContaining('Elevate Your Voice'), findsOneWidget);
    expect(find.textContaining('Measure Your Impact'), findsOneWidget);
    expect(find.text('Continue with Email'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);

    // Tap "Continue with Email" to navigate to Login Screen
    await tester.tap(find.text('Continue with Email'));
    await tester.pumpAndSettle();

    // Verify Login Screen components matching reference
    expect(find.textContaining('Welcome'), findsOneWidget);
    expect(find.textContaining('Back'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.textContaining("Don't have an account?"), findsOneWidget);

    // Tap "Sign up." to navigate to Signup Screen
    await tester.ensureVisible(find.textContaining('Sign up.'));
    await tester.tap(find.textContaining('Sign up.'));
    await tester.pumpAndSettle();

    // Verify Signup Screen components matching reference
    expect(find.textContaining("Let's create your"), findsOneWidget);
    expect(find.textContaining("Account"), findsOneWidget);
    expect(find.text('First Name'), findsOneWidget);
    expect(find.text('Last Name'), findsOneWidget);
    expect(find.text('Nationality'), findsOneWidget);
    expect(find.text('username'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);

    // Tap "Sign Up" to navigate to Verify OTP Screen
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    // Verify OTP Screen components matching reference
    expect(find.textContaining('Verify your'), findsOneWidget);
    expect(find.textContaining('email.'), findsOneWidget);
    expect(find.text('Verify'), findsOneWidget);
    expect(find.text('Change email'), findsOneWidget);
  });

  testWidgets('SpeakWise Main Explore Screen smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppConstants.keyHasSeenOnboarding: true,
      AppConstants.keyIsGuest: true,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRemoteDataSourceProvider.overrideWithValue(_TestAuthRemoteDataSource()),
          eventsRepositoryProvider.overrideWithValue(_TestEventsRepository()),
          profileRepositoryProvider.overrideWithValue(_TestProfileRepository()),
        ],
        child: const SpeakWiseApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Julius Boakye'), findsWidgets);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Discover'), findsWidgets);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Africa'), findsOneWidget);
    expect(find.text('Top Featured Event'), findsOneWidget);
    expect(find.text('PyCon Ghana 2027'), findsWidgets);
    expect(find.text('Buy Ticket'), findsWidgets);
    expect(find.text('View Event'), findsOneWidget);
    expect(find.text('Happening This Month'), findsOneWidget);
    expect(find.text('Top Keynote Speakers'), findsOneWidget);
    expect(find.text('More Upcoming Events'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
  });

  testWidgets('SpeakWise Explore navigation to Event Details Screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({
      AppConstants.keyHasSeenOnboarding: true,
      AppConstants.keyIsGuest: true,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRemoteDataSourceProvider.overrideWithValue(_TestAuthRemoteDataSource()),
          eventsRepositoryProvider.overrideWithValue(_TestEventsRepository()),
          profileRepositoryProvider.overrideWithValue(_TestProfileRepository()),
        ],
        child: const SpeakWiseApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Tap "View Event" on featured card
    await tester.tap(find.text('View Event').hitTestable());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify Event Details Screen matching Figma reference
    expect(find.text('Event Details'), findsOneWidget);
    expect(find.text('PyCon Ghana 2027'), findsWidgets);
    expect(find.text('Submit\na talk'), findsOneWidget);
    expect(find.text('About Event'), findsOneWidget);
    expect(find.text('Buy Ticket'), findsOneWidget);
  });

  testWidgets('SpeakWise Explore "See all" opens All Events directory', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({
      AppConstants.keyHasSeenOnboarding: true,
      AppConstants.keyIsGuest: true,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRemoteDataSourceProvider.overrideWithValue(_TestAuthRemoteDataSource()),
          eventsRepositoryProvider.overrideWithValue(_TestEventsRepository()),
          profileRepositoryProvider.overrideWithValue(_TestProfileRepository()),
        ],
        child: const SpeakWiseApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Tap "See all" on Categories or Happening This Month
    final seeAllFinders = find.text('See all');
    expect(seeAllFinders, findsWidgets);
    await tester.tap(seeAllFinders.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify All Events Directory Screen
    expect(find.textContaining('All Events'), findsOneWidget);
    expect(find.text('Discover'), findsWidgets);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Africa'), findsWidgets);
  });

  testWidgets('SpeakWise Profile Screen and Settings flow test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({
      AppConstants.keyHasSeenOnboarding: true,
      AppConstants.keyIsGuest: true,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRemoteDataSourceProvider.overrideWithValue(_TestAuthRemoteDataSource()),
          eventsRepositoryProvider.overrideWithValue(_TestEventsRepository()),
          profileRepositoryProvider.overrideWithValue(_TestProfileRepository()),
        ],
        child: const SpeakWiseApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Tap Profile Icon in bottom navigation bar (Icons.person_outline_rounded)
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify Profile Screen elements matching Webapp settings
    expect(find.text('Speaker Profile'), findsWidgets);
    expect(find.text('Nana Acheampong'), findsOneWidget);
    expect(find.text('@juliusboakye'), findsOneWidget);
    expect(find.text('JNAB TECH SOLUTIONS'), findsOneWidget);
    expect(find.text('Earned Digital Badges'), findsOneWidget);
    expect(find.text('Master Storyteller'), findsOneWidget);
    expect(find.text('Skills & Expertise'), findsOneWidget);
    expect(find.text('Django'), findsOneWidget);
    expect(find.text('Flutter'), findsOneWidget);

    // Tap "Settings" button to open Edit Profile & Settings Screen
    await tester.tap(find.text('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify Edit Profile Screen sections matching images 0 & 1
    expect(find.text('Profile Settings'), findsOneWidget);
    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('First Name *'), findsOneWidget);
    expect(find.text('Last Name *'), findsOneWidget);
    expect(find.text('Speaker Profile'), findsOneWidget);
    expect(find.text('Contact & Social Links'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('SpeakWise Talks and Feedback Screen with QR Code generation test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({
      AppConstants.keyHasSeenOnboarding: true,
      AppConstants.keyIsGuest: true,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRemoteDataSourceProvider.overrideWithValue(_TestAuthRemoteDataSource()),
          eventsRepositoryProvider.overrideWithValue(_TestEventsRepository()),
          profileRepositoryProvider.overrideWithValue(_TestProfileRepository()),
        ],
        child: const SpeakWiseApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Tap Talks / Microphone Icon in bottom navigation bar
    await tester.tap(find.byIcon(Icons.mic_none_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify Talks & Feedback Hub Screen with two tabs
    expect(find.text('Talks & Feedback'), findsOneWidget);
    expect(find.text('Feedback'), findsOneWidget);
    expect(find.text('My Speaking Sessions'), findsOneWidget);

    // Verify Feedback Tab contents (Dimension Analysis matching image 2)
    expect(find.text('Dimension Analysis'), findsOneWidget);
    expect(find.textContaining('8.'), findsWidgets);
    expect(find.text('Speech Clarity'), findsOneWidget);
    expect(find.text('Technical Depth'), findsOneWidget);
    expect(find.text('Attendee Reviews & Ratings'), findsOneWidget);

    // Switch to "My Speaking Sessions" Tab
    await tester.tap(find.text('My Speaking Sessions'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify Speaking Sessions Tab contents
    expect(find.text('Feedback QR Codes for Your Talks'), findsOneWidget);
    expect(find.text('Add Talk'), findsOneWidget);
    expect(find.text('Present QR Code'), findsWidgets);

    // Tap "Present QR Code" to open the QR Code modal
    final presentButtons = find.text('Present QR Code');
    await tester.tap(presentButtons.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify QR Code Modal Sheet
    expect(find.text('Feedback QR Code'), findsOneWidget);
    expect(find.text('Download QR'), findsOneWidget);
    expect(find.text('Share Link'), findsOneWidget);
  });

  testWidgets('SpeakWise Speaker Profile Details view and Request flow test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({
      AppConstants.keyHasSeenOnboarding: true,
      AppConstants.keyIsGuest: true,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRemoteDataSourceProvider.overrideWithValue(_TestAuthRemoteDataSource()),
          eventsRepositoryProvider.overrideWithValue(_TestEventsRepository()),
          profileRepositoryProvider.overrideWithValue(_TestProfileRepository()),
        ],
        child: const SpeakWiseApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Tap on a speaker from Top Keynote Speakers
    await tester.ensureVisible(find.text('Top Keynote Speakers'));
    await tester.pump();

    // Tap on the speaker name
    final speakerFinder = find.text('Julius Boakye');
    await tester.tap(speakerFinder.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify Speaker Profile Details Screen (matching Figma & WebApp)
    expect(find.text('Speaker Profile'), findsOneWidget);
    expect(find.text('Events Spoken'), findsOneWidget);
    expect(find.textContaining('About'), findsWidgets);
    expect(find.text('Skills and Experience'), findsOneWidget);
    expect(find.text('Talks Given'), findsOneWidget);
    expect(find.textContaining('Request'), findsWidgets);

    // Tap "Request" button to open Bottom Sheet (matching webapp form)
    final requestButtonFinder = find.textContaining('Request');
    await tester.tap(requestButtonFinder.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify Request Speaker modal matching uploaded webapp reference
    expect(find.text('How email requests work'), findsOneWidget);
    expect(find.text('Event Name *'), findsOneWidget);
    expect(find.text('Event Location *'), findsOneWidget);
    expect(find.text('Your Message *'), findsOneWidget);
    expect(find.text('Send Email Request'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('SpeakWise Login with invalid credentials stays on Login Screen and does not navigate', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppConstants.keyHasSeenOnboarding: true,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const SpeakWiseApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Tap "Continue with Email" to reach Login Screen
    await tester.tap(find.text('Continue with Email'));
    await tester.pumpAndSettle();

    // Verify Login Screen
    expect(find.text('Sign In'), findsOneWidget);

    // Enter invalid credentials
    await tester.enterText(find.byType(TextField).at(0), 'invalid@test.com');
    await tester.enterText(find.byType(TextField).at(1), 'wrongpass');

    // Tap "Sign In"
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    // Verify user is NOT logged in and remains on the Sign In screen
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.textContaining('Welcome'), findsOneWidget);
  });

  testWidgets('SpeakWise Forgot Password and Reset Password navigation and submission flow', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppConstants.keyHasSeenOnboarding: true,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRemoteDataSourceProvider.overrideWithValue(_TestAuthRemoteDataSource()),
          eventsRepositoryProvider.overrideWithValue(_TestEventsRepository()),
          profileRepositoryProvider.overrideWithValue(_TestProfileRepository()),
        ],
        child: const SpeakWiseApp(),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Navigate to Login Screen
    await tester.tap(find.text('Continue with Email'));
    await tester.pumpAndSettle();

    // 2. Tap "Forgot Password?"
    expect(find.text('Forgot Password?'), findsOneWidget);
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();

    // 3. Verify Forgot Password Screen is displayed with prefilled email
    expect(find.textContaining('Forgot\nPassword'), findsOneWidget);
    expect(find.text('Send Reset Link'), findsOneWidget);

    // Enter email address
    await tester.enterText(find.byType(TextField).first, 'user@example.com');
    await tester.pump();

    // 4. Tap "Send Reset Link"
    await tester.ensureVisible(find.text('Send Reset Link'));
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    // 5. Verify navigation to Set New Password screen
    expect(find.textContaining('Set New\nPassword'), findsOneWidget);
    expect(find.text('Update Password'), findsOneWidget);

    // 6. Enter token, new password, and matching confirm password
    await tester.enterText(find.byType(TextField).at(1), 'mock-token-12345');
    await tester.enterText(find.byType(TextField).at(2), 'NewPassword123!');
    await tester.enterText(find.byType(TextField).at(3), 'NewPassword123!');

    // 7. Tap "Update Password"
    await tester.ensureVisible(find.text('Update Password'));
    await tester.tap(find.text('Update Password'));
    await tester.pumpAndSettle();

    // 8. Verify redirected back to Sign In
    expect(find.textContaining('Welcome\nBack'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('SpeakWise Explore search field and upcoming event click test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({
      AppConstants.keyHasSeenOnboarding: true,
      AppConstants.keyIsGuest: true,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRemoteDataSourceProvider.overrideWithValue(_TestAuthRemoteDataSource()),
          eventsRepositoryProvider.overrideWithValue(_TestEventsRepository()),
          profileRepositoryProvider.overrideWithValue(_TestProfileRepository()),
        ],
        child: const SpeakWiseApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // 1. Verify Discover search bar exists and can be typed into
    final searchFinder = find.byType(TextField);
    expect(searchFinder, findsOneWidget);

    await tester.enterText(searchFinder, 'Ghana');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // 2. Verify search results header
    expect(find.text('Search Results'), findsOneWidget);
    expect(find.textContaining('found'), findsWidgets);

    // 3. Clear search by tapping X icon
    final closeFinder = find.byIcon(Icons.close_rounded);
    expect(closeFinder, findsOneWidget);
    await tester.tap(closeFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // 4. Verify returned to normal feed with More Upcoming Events
    expect(find.text('More Upcoming Events'), findsOneWidget);
    await tester.ensureVisible(find.text('More Upcoming Events'));
    await tester.pump();

    // 5. Scroll to and tap on an upcoming event card
    final upcomingItem = find.text('Redsketch Academy');
    await tester.ensureVisible(upcomingItem.first);
    await tester.tap(upcomingItem.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // 6. Verify Event Details screen opens and shows the clicked event's details
    expect(find.text('Event Details'), findsOneWidget);
    expect(find.text('Redsketch Academy'), findsWidgets);
    expect(find.text('About Event'), findsOneWidget);
  });

  testWidgets('SpeakWise Top Featured Events swipeable carousel test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({
      AppConstants.keyHasSeenOnboarding: true,
      AppConstants.keyIsGuest: true,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRemoteDataSourceProvider.overrideWithValue(_TestAuthRemoteDataSource()),
          eventsRepositoryProvider.overrideWithValue(_TestEventsRepository()),
          profileRepositoryProvider.overrideWithValue(_TestProfileRepository()),
        ],
        child: const SpeakWiseApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // 1. Verify Top Featured Event section exists and contains PageView
    expect(find.text('Top Featured Event'), findsOneWidget);
    final pageViewFinder = find.byType(PageView);
    expect(pageViewFinder, findsOneWidget);

    // 2. Verify first featured event card is visible
    expect(find.text('PyCon Ghana 2027'), findsWidgets);

    // 3. Swipe left to advance to the next featured event
    await tester.drag(pageViewFinder, const Offset(-500, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    // 4. Verify second featured event is now visible
    expect(find.text('Cortex Dev Summit 2026'), findsWidgets);

    // 5. Tap View Event on the swiped featured event using hitTestable
    final viewEventFinder = find.text('View Event').hitTestable();
    await tester.tap(viewEventFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // 6. Verify Event Details opened for the swiped featured event
    expect(find.text('Event Details'), findsOneWidget);
    expect(find.text('Cortex Dev Summit 2026'), findsWidgets);
    expect(find.text('CFP\nClosed'), findsOneWidget);
  });
}
