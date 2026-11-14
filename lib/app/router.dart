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

  final initialLocation = !hasSeenOnboarding
      ? '/onboarding'
      : (!isAuthenticated ? '/auth' : '/shell');

  return GoRouter(
    initialLocation: initialLocation,
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
            path: 'reset-password-confirm',
            builder: (context, state) {
              final email = state.uri.queryParameters['email'] ?? '';
              final token = state.uri.queryParameters['token'] ?? '';
              return ResetPasswordConfirmScreen(
                initialEmail: email,
                initialToken: token,
              );
            },
          ),
        ],
      ),
      // Deep link alias matching backend email template: /reset-password?token=...&email=...
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final token = state.uri.queryParameters['token'] ?? '';
          return ResetPasswordConfirmScreen(
            initialEmail: email,
            initialToken: token,
          );
        },
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
