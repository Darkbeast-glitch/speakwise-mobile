import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/core/services/cache_manager.dart';
import 'package:speakwise_mobile/core/services/storage_service.dart';
import 'package:speakwise_mobile/features/auth/data/auth_remote_datasource.dart';
import 'package:speakwise_mobile/features/profile/viewmodel/profile_provider.dart';

/// ═══════════════════════════════════════════════════════════════
/// Screen: OAuth Callback Screen
/// Intercepts deep links from OAuth providers (Google / GitHub)
/// and exchanges the one-time code for JWT session credentials.
/// ═══════════════════════════════════════════════════════════════
class OAuthCallbackScreen extends ConsumerStatefulWidget {
  final String code;

  const OAuthCallbackScreen({super.key, required this.code});

  @override
  ConsumerState<OAuthCallbackScreen> createState() =>
      _OAuthCallbackScreenState();
}

class _OAuthCallbackScreenState extends ConsumerState<OAuthCallbackScreen> {
  String _statusMessage = 'Authenticating with SpeakWise...';
  bool _hasExchanged = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processOAuth();
    });
  }

  Future<void> _processOAuth() async {
    if (_hasExchanged) return;
    _hasExchanged = true;

    final code = widget.code.trim();
    if (code.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Authentication cancelled or no authorization code received.',
              style: AppTheme.font(color: Colors.white, fontSize: 13),
            ),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/auth/login');
      }
      return;
    }

    try {
      setState(() {
        _statusMessage = 'Finalizing your secure session...';
      });

      final auth = await ref
          .read(authRemoteDataSourceProvider)
          .exchangeOAuthCode(code);

      final storage = ref.read(storageServiceProvider);
      await storage.setHasSeenOnboarding(true);

      // Reset cache and force refresh profile so stale previous user data never persists
      try {
        await ref.read(cacheManagerProvider).clearAll();
        await ref.read(profileViewModelProvider.notifier).reset();
        await ref.read(profileViewModelProvider.notifier).loadProfile(force: true);
      } catch (e) {
        debugPrint('Profile refresh on OAuth notice: $e');
      }

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.black,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    auth.firstName.isNotEmpty
                        ? 'Welcome to SpeakWise, ${auth.firstName}!'
                        : 'Welcome to SpeakWise!',
                    style: AppTheme.font(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.primaryAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        context.go('/shell');
      }
    } catch (e) {
      debugPrint('OAuth exchange error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'OAuth sign-in failed. Please try logging in with your email or try again.',
              style: AppTheme.font(color: Colors.white, fontSize: 13),
            ),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        context.go('/auth/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppTheme.primaryAccent.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryAccent,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'SpeakWise',
                style: AppTheme.font(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: AppTheme.font(
                  color: AppTheme.textMuted,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
