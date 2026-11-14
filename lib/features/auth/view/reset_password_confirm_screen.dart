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
/// Screen: Reset Password Confirm Screen
/// Connected to Django API: POST /users/auth/password-reset/confirm
/// ═══════════════════════════════════════════════════════════════
class ResetPasswordConfirmScreen extends ConsumerStatefulWidget {
  final String initialEmail;
  final String initialToken;

  const ResetPasswordConfirmScreen({
    super.key,
    this.initialEmail = '',
    this.initialToken = '',
  });

  @override
  ConsumerState<ResetPasswordConfirmScreen> createState() => _ResetPasswordConfirmScreenState();
}

class _ResetPasswordConfirmScreenState extends ConsumerState<ResetPasswordConfirmScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _tokenController;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
    _tokenController = TextEditingController(text: widget.initialToken);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onConfirmReset() async {
    HapticFeedback.lightImpact();
    final email = _emailController.text.trim();
    final token = _tokenController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty) {
      _showError('Please enter your email address.');
      return;
    }

    if (token.isEmpty) {
      _showError('Please enter the reset token received in your email.');
      return;
    }

    if (newPassword.isEmpty) {
      _showError('Please enter your new password.');
      return;
    }

    if (newPassword.length < 8) {
      _showError('New password must be at least 8 characters long.');
      return;
    }

    if (newPassword != confirmPassword) {
      _showError('Passwords do not match. Please re-type your password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final message = await ref.read(authRemoteDataSourceProvider).confirmPasswordReset(
            email: email,
            token: token,
            newPassword: newPassword,
          );

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

        // Redirect directly to login screen
        context.go('/auth/login');
      }
    } catch (e) {
      debugPrint('Password reset confirm error: $e');
      if (mounted) {
        final message = e is ApiException
            ? e.message
            : 'Unable to reset password. Please check your token or try again.';
        _showError(message);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onResendToken() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Please provide an email to resend the reset link.');
      return;
    }

    setState(() => _isResending = true);
    try {
      final msg = await ref.read(authRemoteDataSourceProvider).requestPasswordReset(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg, style: AppTheme.font(color: Colors.white, fontWeight: FontWeight.w600)),
            backgroundColor: AppTheme.surfaceDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e is ApiException ? e.message : 'Unable to resend token.';
        _showError(message);
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _showError(String message) {
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
                        context.go('/auth/forgot-password');
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

                // Title: "Set New Password"
                Text(
                  'Set New\nPassword',
                  textAlign: TextAlign.center,
                  style: AppTheme.font(
                    color: AppTheme.textPrimary,
                    fontSize: 38,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.6,
                    height: 1.15,
                  ),
                ),

                const SizedBox(height: 14),

                // Subtitle
                Text(
                  'Enter the reset token sent to your email and choose your new password.',
                  textAlign: TextAlign.center,
                  style: AppTheme.font(
                    color: AppTheme.textMuted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 28),

                // 1. Email Field
                AuthTextField(
                  controller: _emailController,
                  hintText: 'user@example.com',
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 14),

                // 2. Reset Token Field
                AuthTextField(
                  controller: _tokenController,
                  hintText: 'Reset token (e.g. c3f4a9...)',
                  keyboardType: TextInputType.text,
                ),

                const SizedBox(height: 14),

                // 3. New Password Field
                AuthTextField(
                  controller: _newPasswordController,
                  hintText: 'New password (min 8 characters)',
                  obscureText: _obscureNewPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: const Color(0xFF6E6E6E),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _obscureNewPassword = !_obscureNewPassword);
                    },
                  ),
                ),

                const SizedBox(height: 14),

                // 4. Confirm Password Field
                AuthTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm new password',
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: const Color(0xFF6E6E6E),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Primary Action Button: "Update Password"
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Material(
                    color: AppTheme.primaryAccent,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: _isLoading ? null : _onConfirmReset,
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
                                'Update Password',
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

                // Resend Token Link
                GestureDetector(
                  onTap: _isResending ? null : _onResendToken,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      _isResending ? 'Resending token...' : "Didn't receive a token? Resend email",
                      style: AppTheme.font(
                        color: AppTheme.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Return to Sign In Link
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.go('/auth/login');
                  },
                  child: Text.rich(
                    TextSpan(
                      style: AppTheme.font(
                        color: AppTheme.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                      ),
                      children: [
                        const TextSpan(text: 'Return to '),
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
