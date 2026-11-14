import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/core/services/api_client.dart';
import 'package:speakwise_mobile/core/widgets/ambient_glow.dart';
import 'package:speakwise_mobile/features/auth/data/auth_remote_datasource.dart';
import 'package:speakwise_mobile/features/auth/view/widgets/auth_text_field.dart';

/// ═══════════════════════════════════════════════════════════════
/// Screen: Forgot Password Screen
/// Connected to Django API: POST /users/auth/password-reset/
/// ═══════════════════════════════════════════════════════════════
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final String initialEmail;

  const ForgotPasswordScreen({
    super.key,
    this.initialEmail = '',
  });

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onRequestReset() async {
    HapticFeedback.lightImpact();
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter your email address.',
            style: AppTheme.font(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final message = await ref.read(authRemoteDataSourceProvider).requestPasswordReset(email: email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: AppTheme.font(color: Colors.black, fontWeight: FontWeight.w700),
            ),
            backgroundColor: AppTheme.primaryAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        // Seamlessly take user to confirm screen where they can input token and set new password
        context.push('/auth/reset-password-confirm?email=${Uri.encodeComponent(email)}');
      }
    } catch (e) {
      debugPrint('Password reset request error: $e');
      if (mounted) {
        final message = e is ApiException
            ? e.message
            : 'Unable to process password reset. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: AppTheme.font(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
                // Top Navigation Row
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/auth/login');
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.surfaceBorder),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.textPrimary,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Title: "Forgot Password"
                Text(
                  'Forgot\nPassword',
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

                // SpeakWise Logo Mark
                Image.asset(
                  'assets/images/logo-white.png',
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.lock_reset_rounded,
                      color: AppTheme.primaryAccent,
                      size: 40,
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Explanatory Subtitle
                Text(
                  "Enter the email associated with your account and we'll send you a password reset link and token.",
                  textAlign: TextAlign.center,
                  style: AppTheme.font(
                    color: AppTheme.textMuted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 28),

                // Email Input (Light Gray Pill)
                AuthTextField(
                  controller: _emailController,
                  hintText: 'user@example.com',
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 22),

                // Primary Action: "Send Reset Link"
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Material(
                    color: AppTheme.primaryAccent,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: _isLoading ? null : _onRequestReset,
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
                                'Send Reset Link',
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

                const SizedBox(height: 18),

                // Link to manual token entry
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    final email = _emailController.text.trim();
                    context.push('/auth/reset-password-confirm?email=${Uri.encodeComponent(email)}');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Have a reset token already? Enter token & reset',
                      textAlign: TextAlign.center,
                      style: AppTheme.font(
                        color: AppTheme.primaryAccent,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Footer: "Remember your password? Sign In."
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/auth/login');
                    }
                  },
                  child: Text.rich(
                    TextSpan(
                      style: AppTheme.font(
                        color: AppTheme.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                      ),
                      children: [
                        const TextSpan(text: 'Remember your password? '),
                        TextSpan(
                          text: 'Sign In.',
                          style: AppTheme.font(
                            color: AppTheme.primaryAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
