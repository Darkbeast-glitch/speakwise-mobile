import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/core/config/app_constants.dart';
import 'package:speakwise_mobile/core/services/storage_service.dart';
import 'package:speakwise_mobile/core/widgets/ambient_glow.dart';

/// ═══════════════════════════════════════════════════════════════
/// Screen 1A: Main Auth Gateway Screen ("Auth Screen")
/// Exact Reproduction of User Reference UI
/// ═══════════════════════════════════════════════════════════════
class AuthGatewayScreen extends ConsumerWidget {
  const AuthGatewayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: AmbientGlow(
        glowOpacity: 0.28,
        glowAlignment: const Alignment(0.0, -0.6),
        radius: 0.95,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final logoHeight = (constraints.maxHeight * 0.86).clamp(
                120.0,
                260.0,
              );

              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Spacer(flex: 2),

                          // 1. SpeakWise Large Ribbon Logo Mark
                          Image.asset(
                            'assets/images/logo-white.png',
                            height: logoHeight,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceDark,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.surfaceBorder,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.mic_none_rounded,
                                  color: AppTheme.primaryAccent,
                                  size: 44,
                                ),
                              );
                            },
                          ),

                          const Spacer(flex: 3),

                          // 2. Main Headline
                          Text(
                            'Elevate Your Voice\nMeasure Your Impact',
                            textAlign: TextAlign.center,
                            style: AppTheme.font(
                              color: AppTheme.textPrimary,
                              fontSize: 34,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.6,
                              height: 1.18,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // 3. Subtitle
                          Text(
                            'Turn every talk into verified reputation\nwith instant, real time audience feedback.',
                            textAlign: TextAlign.center,
                            style: AppTheme.font(
                              color: AppTheme.textMuted,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),

                          const Spacer(flex: 3),

                          // 4. Primary Neon Lime Pill: "Continue with Email"
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: Material(
                              color: AppTheme.primaryAccent,
                              shape: const StadiumBorder(),
                              child: InkWell(
                                customBorder: const StadiumBorder(),
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  context.go('/auth/login');
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.mail_outline_rounded,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Continue with Email',
                                      style: AppTheme.font(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // 5. Disabled Social Pill: "Continue with Google"
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: Material(
                              color: Colors.white.withValues(alpha: 0.08),
                              shape: StadiumBorder(
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: InkWell(
                                customBorder: const StadiumBorder(),
                                onTap: () async {
                                  HapticFeedback.lightImpact();
                                  String base = AppConstants.defaultApiUrl;
                                  if (dotenv.isInitialized) {
                                    final envUrl =
                                        dotenv.maybeGet('API_BASE_URL');
                                    if (envUrl != null && envUrl.isNotEmpty) {
                                      base = envUrl;
                                    }
                                  }
                                  final baseUri = Uri.parse(base);
                                  final path = baseUri.path.endsWith('/api')
                                      ? '${baseUri.path}/users/auth/google-login/'
                                      : '${baseUri.path.replaceAll(RegExp(r'/+$'), '')}/api/users/auth/google-login/';

                                  final oauthUri = baseUri.replace(
                                    path: path.replaceAll(RegExp(r'/+'), '/'),
                                    queryParameters: {'platform': 'mobile'},
                                  );

                                  try {
                                    final launched = await launchUrl(
                                      oauthUri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                    if (!launched && context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Could not open Google authentication.',
                                            style: AppTheme.font(
                                                color: Colors.white,
                                                fontSize: 13),
                                          ),
                                          backgroundColor: AppTheme.errorRed,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    debugPrint('OAuth error: $e');
                                  }
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/googlelogo.png',
                                      width: 20,
                                      height: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Continue with Google',
                                      style: AppTheme.font(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 6. Text Link: "Continue as Guest"
                          GestureDetector(
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              await ref
                                  .read(storageServiceProvider)
                                  .setIsGuest(true);
                              if (context.mounted) {
                                context.go('/shell');
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Continue as Guest',
                                style: AppTheme.font(
                                  color: AppTheme.textMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
