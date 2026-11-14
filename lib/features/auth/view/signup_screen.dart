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
/// ═══════════════════════════════════════════════════════════════
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _firstNameController = TextEditingController(text: 'Julius');
  final _lastNameController = TextEditingController(text: 'Boakye');
  final _nationalityController = TextEditingController(text: 'Ghanaian');
  final _usernameController = TextEditingController(text: 'juliusb');
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nationalityController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _onSignUp() async {
    HapticFeedback.lightImpact();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final nationality = _nationalityController.text.trim();
    final username = _usernameController.text.trim();
    final email = '${username.isNotEmpty ? username : 'user'}@example.com';

    setState(() => _isLoading = true);

    try {
      await ref.read(authRemoteDataSourceProvider).register(
            firstName: firstName.isNotEmpty ? firstName : 'Julius',
            lastName: lastName.isNotEmpty ? lastName : 'Boakye',
            nationality: nationality.isNotEmpty ? nationality : 'Ghanaian',
            username: username.isNotEmpty ? username : 'juliusb',
            email: email,
            password: 'Password123!',
          );
      if (mounted) {
        context.go('/auth/verify-otp?email=$email');
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      if (mounted) {
        final message = e is ApiException
            ? e.message
            : 'Registration failed. Please check your details or server connection.';
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
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 36),

                // 1. Headline: "Let's create your Account"
                Text(
                  "Let's create your\nAccount",
                  textAlign: TextAlign.center,
                  style: AppTheme.font(
                    color: AppTheme.textPrimary,
                    fontSize: 35,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.6,
                    height: 1.16,
                  ),
                ),

                const SizedBox(height: 36),

                // 2. Form Inputs (4 Light Gray Stadium Pills)
                AuthTextField(
                  controller: _firstNameController,
                  hintText: 'First Name',
                ),

                const SizedBox(height: 14),

                AuthTextField(
                  controller: _lastNameController,
                  hintText: 'Last Name',
                ),

                const SizedBox(height: 14),

                AuthTextField(
                  controller: _nationalityController,
                  hintText: 'Nationality',
                ),

                const SizedBox(height: 14),

                AuthTextField(
                  controller: _usernameController,
                  hintText: 'username',
                ),

                const SizedBox(height: 28),

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

                const SizedBox(height: 26),

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

                const SizedBox(height: 20),

                // 6. Social Buttons (Light Gray Stadium Pills)
                Row(
                  children: [
                    SocialPillButton(
                      icon: Image.asset(
                        'assets/images/googlelogo.png',
                        width: 22,
                        height: 22,
                      ),
                      onTap: () => context.go('/shell'),
                    ),
                    const SizedBox(width: 14),
                    SocialPillButton(
                      icon: const GithubLogo(
                        size: 22,
                        color: Colors.black,
                      ),
                      onTap: () => context.go('/shell'),
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
