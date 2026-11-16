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
/// Sends a recovery email with a web reset link to set the new password.
/// ═══════════════════════════════════════════════════════════════
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final String initialEmail;

  const ForgotPasswordScreen({
    super.key,
    this.initialEmail = '',
  });

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final TextEditingController _emailController;
  bool _isLoading = false;
  bool _emailSent = false;
  String _sentEmail = '';

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

  void _showError(String message) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _onRequestReset() async {
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();

    if (email.isEmpty ||
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showError('Please enter a valid email address.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authRemoteDataSourceProvider)
          .requestPasswordReset(email: email);

      if (mounted) {
        setState(() {
          _emailSent = true;
          _sentEmail = email;
        });
      }
    } catch (e) {
      debugPrint('Password reset request error: $e');
      if (mounted) {
        final message = e is ApiException
            ? e.message
            : 'Unable to process password reset. Please try again.';
        _showError(message);
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
            child: _emailSent
                ? _buildConfirmationView(context)
                : _buildRequestForm(context),
          ),
        ),
      ),
    );
  }

  /// 1. Form state: User inputs their email
  Widget _buildRequestForm(BuildContext context) {
    return Column(
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

        const SizedBox(height: 20),

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
          "Enter the email associated with your account and we'll send you a recovery link to reset your password on the web.",
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
          enabled: !_isLoading,
          readOnly: _isLoading,
        ),

        const SizedBox(height: 22),

        // Primary Action: "Send Recovery Email"
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
                        'Send Recovery Email',
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

        const SizedBox(height: 26),

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
    );
  }

  /// 2. Confirmation state: Email sent notice
  Widget _buildConfirmationView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Top Navigation Row
        Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              context.go('/auth/login');
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

        const SizedBox(height: 32),

        // Glowing Icon Badge
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            color: AppTheme.primaryAccent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primaryAccent.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.mark_email_read_rounded,
              color: AppTheme.primaryAccent,
              size: 42,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Headline
        Text(
          'Recovery Email\nSent',
          textAlign: TextAlign.center,
          style: AppTheme.font(
            color: AppTheme.textPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            height: 1.15,
          ),
        ),

        const SizedBox(height: 18),

        // Details text exactly as requested by user
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text.rich(
            TextSpan(
              style: AppTheme.font(
                color: AppTheme.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
              children: [
                const TextSpan(
                  text: 'We have sent a recovery email to\n',
                ),
                TextSpan(
                  text: _sentEmail,
                  style: AppTheme.font(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                const TextSpan(
                  text:
                      '.\n\nIf it\'s in our system, you can follow the link in your email to set your new password on the web.',
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 36),

        // Primary Action: "Back to Log In"
        SizedBox(
          width: double.infinity,
          height: 50,
          child: Material(
            color: AppTheme.primaryAccent,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () {
                HapticFeedback.lightImpact();
                context.go('/auth/login');
              },
              child: Center(
                child: Text(
                  'Back to Log In',
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

        // Try another email button
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _emailSent = false);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Didn\'t receive it? Try another email',
              style: AppTheme.font(
                color: AppTheme.primaryAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
