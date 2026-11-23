import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speakwise_mobile/core/services/storage_service.dart';
import 'package:speakwise_mobile/features/auth/auth.dart';
import 'package:speakwise_mobile/features/explore/explore.dart';
import 'package:speakwise_mobile/features/onboarding/onboarding.dart';
import 'package:speakwise_mobile/features/profile/profile.dart';
import 'package:speakwise_mobile/features/shell/view/main_shell_screen.dart';

/// ═══════════════════════════════════════════════════════════════
/// SpeakWise App Router Configuration
/// ═══════════════════════════════════════════════════════════════
final routerProvider = Provider<GoRouter>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final hasSeenOnboarding = storage.hasSeenOnboarding;
  final isAuthenticated = storage.isAuthenticated;

  // 1. Logged in users always start directly in /shell
  // 2. First-time installs see /onboarding
  // 3. Logged-out returning users see /auth
  final initialLocation = isAuthenticated
      ? '/shell'
      : (!hasSeenOnboarding ? '/onboarding' : '/auth');

  return GoRouter(
    initialLocation: initialLocation,
    redirect: (context, state) {
      final isAuth = storage.isAuthenticated;
      final path = state.uri.path;
      final isAuthRoute = path.startsWith('/auth') || path == '/onboarding';

      // If user is already authenticated, keep them in /shell
      if (isAuth && isAuthRoute) {
        return '/shell';
      }

      // If user is not authenticated, protect authenticated areas
      if (!isAuth && (path == '/shell' || path.startsWith('/profile/edit'))) {
        return storage.hasSeenOnboarding ? '/auth' : '/onboarding';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthGatewayScreen(),
        routes: [
          GoRoute(
            path: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: 'signup',
            builder: (context, state) => const SignupScreen(),
          ),
          GoRoute(
            path: 'verify-otp',
            builder: (context, state) {
              final email = state.uri.queryParameters['email'] ?? 'user@example.com';
              return VerifyOtpScreen(email: email);
            },
          ),
          GoRoute(
            path: 'forgot-password',
            builder: (context, state) {
              final email = state.uri.queryParameters['email'] ?? '';
              return ForgotPasswordScreen(initialEmail: email);
            },
          ),
          GoRoute(
            path: 'callback',
            builder: (context, state) {
              final code = state.uri.queryParameters['code'] ?? '';
              return OAuthCallbackScreen(code: code);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/reset-password',
        redirect: (context, state) => '/auth/login',
      ),
      GoRoute(
        path: '/shell',
        builder: (context, state) {
          final tabParam = state.uri.queryParameters['tab'];
          final initialTab = int.tryParse(tabParam ?? '') ?? 0;
          return MainShellScreen(initialIndex: initialTab);
        },
      ),
      GoRoute(
        path: '/event/:id',
        builder: (context, state) {
          final eventId = state.pathParameters['id'] ?? 'pycon-gh-2027';
          final initialEvent = state.extra is EventItem ? state.extra as EventItem : null;
          return EventDetailsScreen(
            eventId: eventId,
            initialEvent: initialEvent,
          );
        },
      ),
      GoRoute(
        path: '/events/all',
        builder: (context, state) {
          final category = state.uri.queryParameters['category'] ?? 'all';
          return AllEventsScreen(initialCategory: category);
        },
      ),
      GoRoute(
        path: '/speakers/all',
        builder: (context, state) {
          final filter = state.uri.queryParameters['filter'];
          return AllSpeakersScreen(initialFilter: filter);
        },
      ),
      GoRoute(
        path: '/speakers',
        builder: (context, state) {
          final filter = state.uri.queryParameters['filter'];
          return AllSpeakersScreen(initialFilter: filter);
        },
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/speaker/:id',
        builder: (context, state) {
          final speakerId = state.pathParameters['id'] ?? 'juliusb';
          return SpeakerProfileDetailsScreen(speakerId: speakerId);
        },
      ),
    ],
  );
});
