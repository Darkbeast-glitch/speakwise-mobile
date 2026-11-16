import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/core/services/api_client.dart';
import 'package:speakwise_mobile/core/widgets/ambient_glow.dart';
import 'package:speakwise_mobile/features/auth/data/auth_remote_datasource.dart';
import 'package:speakwise_mobile/features/auth/view/widgets/auth_text_field.dart';
import 'package:speakwise_mobile/features/auth/view/widgets/social_pill_button.dart';

/// ═══════════════════════════════════════════════════════════════
/// Screen 1C: Registration Screen ("Sign up")
/// Connected to Django API: POST /users/auth/register/
/// Fields:
/// 1. First Name
/// 2. Last Name
/// 3. Username
/// 4. Nationality
/// 5. Email
/// 6. Password
/// 7. Confirm Password
/// ═══════════════════════════════════════════════════════════════
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _nationalityController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
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

  void _onSignUp() async {
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final username = _usernameController.text.trim();
    final nationality = _nationalityController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Client-side validations
    if (firstName.isEmpty) {
      _showErrorSnackBar('Please enter your first name.');
      return;
    }
    if (lastName.isEmpty) {
      _showErrorSnackBar('Please enter your last name.');
      return;
    }
    if (username.isEmpty) {
      _showErrorSnackBar('Please choose a username.');
      return;
    }
    if (nationality.isEmpty) {
      _showErrorSnackBar('Please enter your nationality.');
      return;
    }
    if (email.isEmpty ||
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showErrorSnackBar('Please enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      _showErrorSnackBar('Please enter a password.');
      return;
    }
    if (password.length < 8) {
      _showErrorSnackBar('Password must be at least 8 characters long.');
      return;
    }
    if (password != confirmPassword) {
      _showErrorSnackBar('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ref
          .read(authRemoteDataSourceProvider)
          .register(
            firstName: firstName,
            lastName: lastName,
            nationality: nationality,
            username: username,
            email: email,
            password: password,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.message.isNotEmpty
                  ? response.message
                  : 'Verification code sent to $email.',
              style: AppTheme.font(
                color: Colors.black,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppTheme.primaryAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        context.go('/auth/verify-otp?email=${Uri.encodeComponent(email)}');
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      if (mounted) {
        String message;
        if (e is ApiException) {
          final raw = e.message;
          final lower = raw.toLowerCase();
          if (lower.contains('future not completed') ||
              lower.contains('timeout') ||
              lower.contains('timed out') ||
              e.statusCode == 408) {
            message =
                'Connection timed out. The server took too long to respond. Please check your internet connection and try again.';
          } else if (lower.contains('cannot reach server') ||
              lower.contains('socketexception') ||
              lower.contains('failed host lookup') ||
              lower.contains('connection refused') ||
              lower.contains('network is unreachable')) {
            message =
                'Unable to connect to SpeakWise server. Please check your internet connection.';
          } else {
            message = raw;
          }
        } else {
          final errStr = e.toString().toLowerCase();
          if (errStr.contains('future not completed') || errStr.contains('timeout')) {
            message =
                'Connection timed out. Please check your internet connection and try again.';
          } else {
            message =
                'Registration failed. Please check your details or server connection.';
          }
        }
        _showErrorSnackBar(message);
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
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // 1. Headline: "Let's create your Account"
                Text(
                  "Let's create your\nAccount",
                  textAlign: TextAlign.center,
                  style: AppTheme.font(
                    color: AppTheme.textPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.6,
                    height: 1.16,
                  ),
                ),

                const SizedBox(height: 28),

                // 2. Form Inputs (Stadium Pills matching Backend API fields)
                // First Name
                AuthTextField(
                  controller: _firstNameController,
                  hintText: 'First Name',
                  enabled: !_isLoading,
                  readOnly: _isLoading,
                ),

                const SizedBox(height: 14),

                // Last Name
                AuthTextField(
                  controller: _lastNameController,
                  hintText: 'Last Name',
                  enabled: !_isLoading,
                  readOnly: _isLoading,
                ),

                const SizedBox(height: 14),

                // Username
                AuthTextField(
                  controller: _usernameController,
                  hintText: 'Username',
                  enabled: !_isLoading,
                  readOnly: _isLoading,
                ),

                const SizedBox(height: 14),

                // Nationality
                AuthTextField(
                  controller: _nationalityController,
                  hintText: 'Nationality',
                  enabled: !_isLoading,
                  readOnly: _isLoading,
                ),

                const SizedBox(height: 14),

                // Email
                AuthTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  readOnly: _isLoading,
                ),

                const SizedBox(height: 14),

                // Password
                AuthTextField(
                  controller: _passwordController,
                  hintText: 'Password',
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
                        : () => setState(
                            () => _obscurePassword = !_obscurePassword),
                  ),
                ),

                const SizedBox(height: 14),

                // Confirm Password
                AuthTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm Password',
                  obscureText: _obscureConfirmPassword,
                  enabled: !_isLoading,
                  readOnly: _isLoading,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF6E6E6E),
                      size: 20,
                    ),
                    onPressed: _isLoading
                        ? null
                        : () => setState(() => _obscureConfirmPassword =
                            !_obscureConfirmPassword),
                  ),
                ),

                const SizedBox(height: 26),

                // 3. Primary Neon Lime CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Material(
                    color: AppTheme.primaryAccent,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: _isLoading ? null : _onSignUp,
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
                                'Sign Up',
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

                // 4. Footer: "Already have an account? Log in."
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
                        const TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Log in.',
                          style: AppTheme.font(
                            color: AppTheme.primaryAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 5. Divider: "— or continue with —"
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

                const SizedBox(height: 18),

                // 6. Social Buttons (Disabled)
                Row(
                  children: [
                    SocialPillButton(
                      icon: Image.asset(
                        'assets/images/googlelogo.png',
                        width: 22,
                        height: 22,
                      ),
                      enabled: false,
                      onTap: () => _onSocialDisabledTap('Google'),
                    ),
                    const SizedBox(width: 14),
                    SocialPillButton(
                      icon: const GithubLogo(size: 22, color: Colors.black),
                      enabled: false,
                      onTap: () => _onSocialDisabledTap('GitHub'),
                    ),
                  ],
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onSocialDisabledTap(String provider) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$provider sign-in is currently disabled. Please use your email.',
          style: AppTheme.font(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF1E1F24),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
