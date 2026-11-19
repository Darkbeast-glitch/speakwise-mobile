import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/core/widgets/widgets.dart';
import 'package:speakwise_mobile/features/profile/profile.dart';

/// ═══════════════════════════════════════════════════════════════
/// Edit Profile & Account Settings Screen
/// Exact match of User Webapp Settings Reference (Images 0 & 1)
/// ═══════════════════════════════════════════════════════════════
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _nationalityController;
  late TextEditingController _organizationController;
  late TextEditingController _countryController;
  late TextEditingController _shortBioController;
  late TextEditingController _biographyController;
  late TextEditingController _linkedInController;
  late TextEditingController _twitterController;
  late TextEditingController _gitHubController;
  late TextEditingController _instagramController;
  late TextEditingController _youTubeController;
  late TextEditingController _websiteController;
  late TextEditingController _newSkillController;

  late List<String> _skills;
  XFile? _selectedImage;
  bool _removedAvatar = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileViewModelProvider).profile;

    _firstNameController = TextEditingController(text: profile.firstName);
    _lastNameController = TextEditingController(text: profile.lastName);
    _emailController = TextEditingController(text: profile.email);
    _usernameController = TextEditingController(text: profile.username);
    _nationalityController = TextEditingController(text: profile.nationality);
    _organizationController = TextEditingController(text: profile.organization);
    _countryController = TextEditingController(text: profile.country);
    _shortBioController = TextEditingController(text: profile.shortBio);
    _biographyController = TextEditingController(text: profile.biography);
    _linkedInController = TextEditingController(
      text: profile.socialLinks['LinkedIn'] ?? '',
    );
    _twitterController = TextEditingController(
      text: profile.socialLinks['Twitter'] ?? '',
    );
    _gitHubController = TextEditingController(
      text: profile.socialLinks['GitHub'] ?? '',
    );
    _instagramController = TextEditingController(
      text: profile.socialLinks['Instagram'] ?? '',
    );
    _youTubeController = TextEditingController(
      text: profile.socialLinks['YouTube'] ?? '',
    );
    _websiteController = TextEditingController(
      text: profile.socialLinks['Website'] ?? '',
    );
    _newSkillController = TextEditingController();

    _skills = List<String>.from(profile.skills);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _nationalityController.dispose();
    _organizationController.dispose();
    _countryController.dispose();
    _shortBioController.dispose();
    _biographyController.dispose();
    _linkedInController.dispose();
    _twitterController.dispose();
    _gitHubController.dispose();
    _instagramController.dispose();
    _youTubeController.dispose();
    _websiteController.dispose();
    _newSkillController.dispose();
    super.dispose();
  }

  void _onSave() async {
    HapticFeedback.mediumImpact();

    final socialMap = {
      'LinkedIn': _linkedInController.text.trim(),
      'Twitter': _twitterController.text.trim(),
      'GitHub': _gitHubController.text.trim(),
      'Instagram': _instagramController.text.trim(),
      'YouTube': _youTubeController.text.trim(),
      'Website': _websiteController.text.trim(),
    };

    await ref
        .read(profileViewModelProvider.notifier)
        .updateProfile(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          username: _usernameController.text.trim(),
          nationality: _nationalityController.text.trim(),
          organization: _organizationController.text.trim(),
          country: _countryController.text.trim(),
          shortBio: _shortBioController.text.trim(),
          biography: _biographyController.text.trim(),
          socialLinks: socialMap,
          skills: _skills,
          avatarPath: _selectedImage != null
              ? _selectedImage!.path
              : (_removedAvatar ? '' : null),
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile information saved successfully!',
            style: AppTheme.font(
              color: Colors.black,
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
      context.pop();
    }
  }

  void _addSkill() {
    final text = _newSkillController.text.trim();
    if (text.isNotEmpty && !_skills.contains(text)) {
      setState(() {
        _skills.add(text);
        _newSkillController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: AmbientGlow(
        glowOpacity: 0.18,
        glowAlignment: const Alignment(0.0, -0.7),
        radius: 0.9,
        child: SafeArea(
          child: Column(
            children: [
              // 1. Top Navigation Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.pop();
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF161616),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Profile Settings',
                      style: AppTheme.font(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _onSave,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAccent,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusPill,
                          ),
                        ),
                        child: Text(
                          'Save',
                          style: AppTheme.font(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Scrollable Settings Form
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  children: [
                    // Profile Image Card
                    _buildImageCard(),

                    const SizedBox(height: 18),

                    // Section 1: Personal Information
                    _buildCard(
                      title: 'Personal Information',
                      subtitle: 'Your basic account information',
                      children: [
                        _fieldLabel('First Name *'),
                        _inputField(_firstNameController, 'First Name'),
                        const SizedBox(height: 14),
                        _fieldLabel('Last Name *'),
                        _inputField(_lastNameController, 'Last Name'),
                        const SizedBox(height: 14),
                        _fieldLabel('Email'),
                        _inputField(
                          _emailController,
                          'email@example.com',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),
                        _fieldLabel('Username'),
                        _inputField(_usernameController, 'username'),
                        const SizedBox(height: 14),
                        _fieldLabel('Nationality *'),
                        _inputField(_nationalityController, 'Country / Nationality'),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Section 2: Speaker Profile
                    _buildCard(
                      title: 'Speaker Profile',
                      subtitle: 'Professional information and bio',
                      children: [
                        _fieldLabel('Organization'),
                        _inputField(
                          _organizationController,
                          'Company or Organization',
                        ),
                        const SizedBox(height: 14),
                        _fieldLabel('Country'),
                        _inputField(_countryController, 'Ghana'),
                        const SizedBox(height: 14),
                        _fieldLabel('Short Bio'),
                        _inputField(
                          _shortBioController,
                          'Short bio summarizing your focus...',
                          maxLines: 2,
                        ),
                        const SizedBox(height: 14),
                        _fieldLabel('Biography'),
                        _inputField(
                          _biographyController,
                          'Detailed biography...',
                          maxLines: 5,
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Section 3: Contact & Social Links
                    _buildCard(
                      title: 'Contact & Social Links',
                      subtitle:
                          'Shown on the Contact tab of your public profile. Leave a field empty to hide it.',
                      children: [
                        _fieldLabel('LinkedIn'),
                        _inputField(
                          _linkedInController,
                          'https://linkedin.com/in/your-name',
                        ),
                        const SizedBox(height: 14),
                        _fieldLabel('Twitter'),
                        _inputField(
                          _twitterController,
                          'https://x.com/your-handle',
                        ),
                        const SizedBox(height: 14),
                        _fieldLabel('GitHub'),
                        _inputField(
                          _gitHubController,
                          'https://github.com/your-username',
                        ),
                        const SizedBox(height: 14),
                        _fieldLabel('Instagram'),
                        _inputField(
                          _instagramController,
                          'https://instagram.com/your-handle',
                        ),
                        const SizedBox(height: 14),
                        _fieldLabel('YouTube'),
                        _inputField(
                          _youTubeController,
                          'https://youtube.com/@your-channel',
                        ),
                        const SizedBox(height: 14),
                        _fieldLabel('Website'),
                        _inputField(
                          _websiteController,
                          'https://your-website.com',
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Section 4: Skills & Expertise
                    _buildCard(
                      title: 'Skills & Expertise',
                      subtitle:
                          'Add your skills and areas of expertise to help organizers find you',
                      children: [
                        _fieldLabel('Search or add a skill...'),
                        Row(
                          children: [
                            Expanded(
                              child: _inputField(
                                _newSkillController,
                                'e.g., Python, Keynote...',
                                onSubmitted: (_) => _addSkill(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: _addSkill,
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryAccent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.black,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your Skills (${_skills.length})',
                          style: AppTheme.font(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _skills.map((skill) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E201B),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusPill,
                                ),
                                border: Border.all(
                                  color: AppTheme.primaryAccent.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    skill,
                                    style: AppTheme.font(
                                      color: AppTheme.textPrimary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _removeSkill(skill),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: AppTheme.textMuted,
                                      size: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Save Changes Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: Material(
                        color: AppTheme.primaryAccent,
                        shape: const StadiumBorder(),
                        child: InkWell(
                          customBorder: const StadiumBorder(),
                          onTap: _onSave,
                          child: Center(
                            child: Text(
                              'Save Changes',
                              style: AppTheme.font(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _selectedImage = picked;
          _removedAvatar = false;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not access photo: $e',
              style: AppTheme.font(color: Colors.white, fontSize: 13),
            ),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _showPhotoPickerOptions(UserProfile profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141416),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final hasPhoto = _selectedImage != null ||
            (!_removedAvatar &&
                profile.avatarPath.trim().isNotEmpty &&
                !profile.avatarPath.contains('Julius.png'));

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Change Profile Photo',
                  style: AppTheme.font(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E211A),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppTheme.primaryAccent,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Take Photo',
                    style: AppTheme.font(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Use your camera to capture a new photo',
                    style: AppTheme.font(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 6),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E211A),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: AppTheme.primaryAccent,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: AppTheme.font(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Select an existing picture from your device',
                    style: AppTheme.font(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (hasPhoto) ...[
                  const SizedBox(height: 6),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A1515),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE53935).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFE53935),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Remove Photo',
                      style: AppTheme.font(
                        color: const Color(0xFFE53935),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Revert to initials avatar fallback',
                      style: AppTheme.font(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _selectedImage = null;
                        _removedAvatar = true;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageCard() {
    final profile = ref.watch(profileViewModelProvider).profile;
    final fullName =
        '${_firstNameController.text} ${_lastNameController.text}'.trim();
    final effectiveName = fullName.isNotEmpty ? fullName : profile.username;
    final hasCustomPhoto = _selectedImage != null ||
        (!_removedAvatar &&
            profile.avatarPath.trim().isNotEmpty &&
            !profile.avatarPath.contains('Julius.png'));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F110C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryAccent, width: 2),
            ),
            child: _selectedImage != null
                ? ClipOval(
                    child: Image.file(
                      File(_selectedImage!.path),
                      fit: BoxFit.cover,
                      width: 68,
                      height: 68,
                    ),
                  )
                : UserAvatar(
                    name: effectiveName,
                    avatarUrl: _removedAvatar ? '' : profile.avatarPath,
                    size: 68,
                    showBorder: false,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Photo',
                  style: AppTheme.font(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedImage != null
                      ? 'New photo selected'
                      : (hasCustomPhoto
                          ? 'Custom photo set'
                          : 'Using initials fallback'),
                  style: AppTheme.font(color: AppTheme.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showPhotoPickerOptions(profile);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1D16),
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Text(
                      'Change photo',
                      style: AppTheme.font(
                        color: AppTheme.primaryAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F110C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.font(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: AppTheme.font(
              color: AppTheme.textMuted,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: AppTheme.font(
          color: AppTheme.textMuted,
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _inputField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141611),
        borderRadius: BorderRadius.circular(
          maxLines > 1 ? 14 : AppTheme.radiusPill,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: maxLines > 1 ? 12 : 2,
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onSubmitted: onSubmitted,
        style: AppTheme.font(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: AppTheme.primaryAccent,
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: hint,
          hintStyle: AppTheme.font(
            color: Colors.white.withValues(alpha: 0.28),
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }
}
