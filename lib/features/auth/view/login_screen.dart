import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/app/router.dart';
import 'package:speakwise_mobile/core/config/app_constants.dart';
import 'package:speakwise_mobile/core/services/api_client.dart';
import 'package:speakwise_mobile/core/services/cache_manager.dart';
import 'package:speakwise_mobile/core/widgets/widgets.dart';
import 'package:speakwise_mobile/features/auth/auth.dart';
import 'package:speakwise_mobile/features/profile/profile.dart';
import 'package:speakwise_mobile/features/talks/viewmodel/talks_provider.dart';

/// ═══════════════════════════════════════════════════════════════
/// Screen 1B: Sign In Screen ("Login Screen")
/// Connected to Django API: POST /users/auth/login/
/// ═══════════════════════════════════════════════════════════════
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignIn() async {
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter your email and password.',
            style: AppTheme.font(color: Colors.white),
          ),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authRemoteDataSourceProvider)
          .login(email: email, password: password);
      // Immediately clear old cached profile and load fresh profile for the logged in user
      try {
        await ref.read(cacheManagerProvider).remove('user_profile_cache');
        await ref.read(profileViewModelProvider.notifier).reset();
        await ref
            .read(profileViewModelProvider.notifier)
            .loadProfile(force: true);
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.primaryAccent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Login successfully',
                  style: AppTheme.font(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1B1D1F),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: AppTheme.primaryAccent.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
          ),
        );
        ref.invalidate(talksViewModelProvider);
        ref.invalidate(profileViewModelProvider);
        ref.invalidate(routerProvider);
        context.go('/shell');
      }
    } catch (e) {
      debugPrint('Django Auth Login failed: $e');
      if (mounted) {
        final message = _formatLoginErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: AppTheme.font(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatLoginErrorMessage(dynamic error) {
    if (error is ApiException) {
      final raw = error.message;
      final lower = raw.toLowerCase();

      if (lower.contains('future not completed') ||
          lower.contains('timeoutexception') ||
          lower.contains('timed out') ||
          error.statusCode == 408) {
        return 'Connection timed out. The server is taking longer than usual to respond. Please check your internet connection and try again.';
      }

      if (lower.contains('cannot reach server') ||
          lower.contains('socketexception') ||
          lower.contains('failed host lookup') ||
          lower.contains('connection refused') ||
          lower.contains('network is unreachable')) {
        return 'Unable to reach SpeakWise server. Please check your internet connection.';
      }

      if (error.statusCode == 401 ||
          (error.statusCode == 400 &&
              (lower.contains('credential') ||
                  lower.contains('password') ||
                  lower.contains('no active account') ||
                  lower.contains('user not found') ||
                  lower.contains('invalid')))) {
        return 'Incorrect email or password. Please verify your credentials.';
      }

      if (raw.trim().isNotEmpty && !raw.startsWith('ApiException')) {
        return raw;
      }
    }

    final str = error.toString().toLowerCase();
    if (str.contains('future not completed') || str.contains('timeout')) {
      return 'Connection timed out. The server took too long to respond. Please check your internet connection and try again.';
    }

    return 'Unable to sign in. Please check your credentials or network connection.';
  }

  Future<void> _launchOAuth(String provider) async {
    HapticFeedback.lightImpact();
    final lower = provider.toLowerCase();
    String base = AppConstants.defaultApiUrl;
    if (dotenv.isInitialized) {
      final envUrl = dotenv.maybeGet('API_BASE_URL');
      if (envUrl != null && envUrl.isNotEmpty) {
        base = envUrl;
      }
    }
    final baseUri = Uri.parse(base);
    final path = baseUri.path.endsWith('/api')
        ? '${baseUri.path}/users/auth/$lower-login/'
        : '${baseUri.path.replaceAll(RegExp(r'/+$'), '')}/api/users/auth/$lower-login/';

    final oauthUri = baseUri.replace(
      path: path.replaceAll(RegExp(r'/+'), '/'),
      queryParameters: {'platform': 'mobile'},
    );

    try {
      final launched = await launchUrl(
        oauthUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not launch browser for $provider authentication.',
              style: AppTheme.font(color: Colors.white, fontSize: 13),
            ),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('OAuth launch error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to open $provider login: $e',
              style: AppTheme.font(color: Colors.white, fontSize: 13),
            ),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: AmbientGlow(
        glowOpacity: 0.26,
        glowAlignment: const Alignment(0.0, -0.65),
        radius: 0.95,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),

                // 1. Title: "Welcome Back"
                Text(
                  'Welcome\nBack',
                  textAlign: TextAlign.center,
                  style: AppTheme.font(
                    color: AppTheme.textPrimary,
                    fontSize: 38,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.6,
                    height: 1.15,
                  ),
                ),

                const SizedBox(height: 20),

                // 2. SpeakWise Logo Mark
                Image.asset(
                  'assets/images/logo-white.png',
                  height: 90,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.mic_none_rounded,
                      color: AppTheme.primaryAccent,
                      size: 40,
                    );
                  },
                ),

                const SizedBox(height: 24),

                // 3. Email Input (Light Gray Pill)
                AuthTextField(
                  controller: _emailController,
                  hintText: 'Enter your email here',
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  readOnly: _isLoading,
                ),

                const SizedBox(height: 14),

                // 4. Password Input (Light Gray Pill)
                AuthTextField(
                  controller: _passwordController,
                  hintText: 'Enter your password.',
                  obscureText: _obscurePassword,
                  enabled: !_isLoading,
                  readOnly: _isLoading,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF6E6E6E),
                      size: 20,
                    ),
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                  ),
                ),

                const SizedBox(height: 8),

                // 5. "Forgot Password?" Right Link
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            final email = _emailController.text.trim();
                            if (email.isNotEmpty) {
                              context.push(
                                '/auth/forgot-password?email=${Uri.encodeComponent(email)}',
                              );
                            } else {
                              context.push('/auth/forgot-password');
                            }
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Forgot Password?',
                        style: AppTheme.font(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 6. Primary "Sign In" Button (Electric Neon Lime Pill)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Material(
                    color: AppTheme.primaryAccent,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: _isLoading ? null : _onSignIn,
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : Text(
                                'Sign In',
                                style: AppTheme.font(
                                  color: Colors.black,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.1,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 7. Footer: "Don't have an account? Sign up."
                GestureDetector(
                  onTap: _isLoading
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          context.go('/auth/signup');
                        },
                  child: Text.rich(
                    TextSpan(
                      style: AppTheme.font(
                        color: AppTheme.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                      ),
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: 'Sign up.',
                          style: AppTheme.font(
                            color: AppTheme.primaryAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                // 8. Divider: "— or continue with —"
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 0.8,
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or continue with',
                        style: AppTheme.font(
                          color: AppTheme.textMuted.withValues(alpha: 0.8),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 0.8,
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 9. Social Buttons (Enabled)
                Row(
                  children: [
                    SocialPillButton(
                      icon: Image.asset(
                        'assets/images/googlelogo.png',
                        width: 30,
                        height: 30,
                      ),
                      enabled: true,
                      onTap: () => _launchOAuth('google'),
                    ),
                    const SizedBox(width: 14),
                    SocialPillButton(
                      icon: const GithubLogo(size: 22, color: Colors.black),
                      enabled: true,
                      onTap: () => _launchOAuth('github'),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
