import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/features/talks/data/models/talk_model.dart';
import 'package:speakwise_mobile/features/talks/view/widgets/talk_qr_code_modal.dart';
import 'package:speakwise_mobile/features/talks/viewmodel/talks_provider.dart';

/// ═══════════════════════════════════════════════════════════════
/// Add / Edit Speaking Experience Form Modal
/// Exact match of User Webapp Modal Reference (Image 2)
/// ═══════════════════════════════════════════════════════════════
class AddTalkModal extends ConsumerStatefulWidget {
  final SpeakingTalk? talkToEdit;

  const AddTalkModal({super.key, this.talkToEdit});

  static Future<void> show(BuildContext context, {SpeakingTalk? talkToEdit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddTalkModal(talkToEdit: talkToEdit),
    );
  }

  @override
  ConsumerState<AddTalkModal> createState() => _AddTalkModalState();
}

class _AddTalkModalState extends ConsumerState<AddTalkModal> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  late final TextEditingController _eventDateController;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _presentationUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final talk = widget.talkToEdit;
    if (talk != null) {
      _eventNameController.text = talk.eventName;
      _eventDateController = TextEditingController(text: talk.eventDate);
      _titleController.text = talk.title;
      _descriptionController.text = talk.description;
      _presentationUrlController.text = talk.presentationUrl ?? '';
      _videoUrlController.text = talk.videoUrl ?? '';
    } else {
      final now = DateTime.now();
      _eventDateController = TextEditingController(
        text:
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      );
    }
    // Listeners to live-update the Cover Preview
    _eventNameController.addListener(() => setState(() {}));
    _titleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventDateController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _presentationUrlController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (_eventNameController.text.trim().isEmpty ||
        _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in the Event Name and Talk Title.',
            style: AppTheme.font(color: Colors.white),
          ),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    final isEditing = widget.talkToEdit != null;
    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    if (isEditing) {
      await ref.read(talksViewModelProvider.notifier).updateTalk(
            talkId: widget.talkToEdit!.id,
            eventName: _eventNameController.text.trim(),
            eventDate: _eventDateController.text.trim().isNotEmpty
                ? _eventDateController.text.trim()
                : widget.talkToEdit!.eventDate,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : widget.talkToEdit!.description,
            presentationUrl: _presentationUrlController.text.trim().isNotEmpty
                ? _presentationUrlController.text.trim()
                : null,
            videoUrl: _videoUrlController.text.trim().isNotEmpty
                ? _videoUrlController.text.trim()
                : null,
          );

      setState(() => _isSubmitting = false);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Talk updated successfully!',
              style: AppTheme.font(
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
            backgroundColor: AppTheme.primaryAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      final savedTalk = await ref.read(talksViewModelProvider.notifier).addTalk(
            eventName: _eventNameController.text.trim(),
            eventDate: _eventDateController.text.trim().isNotEmpty
                ? _eventDateController.text.trim()
                : '13/11/2026',
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : 'Comprehensive technical presentation and interactive Q&A session.',
            presentationUrl: _presentationUrlController.text.trim().isNotEmpty
                ? _presentationUrlController.text.trim()
                : null,
            videoUrl: _videoUrlController.text.trim().isNotEmpty
                ? _videoUrlController.text.trim()
                : null,
          );

      setState(() => _isSubmitting = false);

      if (mounted) {
        Navigator.pop(context); // Close add form modal

        // Promptly show the Generated Feedback QR Code modal for this new talk!
        TalkQrCodeModal.show(context, savedTalk);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F110B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 14),

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.talkToEdit != null
                          ? 'Edit Speaking Experience'
                          : 'Add Speaking Experience',
                      style: AppTheme.font(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.talkToEdit != null
                          ? 'Update your session details and links'
                          : 'Share your conference talks and presentations with the community',
                      style: AppTheme.font(
                        color: AppTheme.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF181A14),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.close_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Scrollable Form Body
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Field 1: Event/Conference Name *
                    _fieldLabel('Event/Conference Name *'),
                    _inputField(
                      _eventNameController,
                      'e.g., PyCon Ghana 2025',
                    ),

                    const SizedBox(height: 14),

                    // Field 2: Event Date *
                    _fieldLabel('Event Date *'),
                    _inputField(
                      _eventDateController,
                      'YYYY-MM-DD',
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                          color: AppTheme.textMuted,
                          size: 18,
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: AppTheme.primaryAccent,
                                    onPrimary: Colors.black,
                                    surface: Color(0xFF141611),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            _eventDateController.text =
                                '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Field 3: Talk Topic/Title *
                    _fieldLabel('Talk Topic/Title *'),
                    _inputField(
                      _titleController,
                      'e.g., Building Scalable APIs with Python',
                    ),

                    const SizedBox(height: 16),

                    // Live Experience Cover Preview (Matching Image 2)
                    _fieldLabel('Experience cover preview'),
                    _buildCoverPreview(),

                    const SizedBox(height: 16),

                    // Field 4: Description * with rich text toolbar
                    _fieldLabel('Description *'),
                    _buildDescriptionField(),

                    const SizedBox(height: 14),

                    // Field 5: Presentation Link (Optional)
                    _fieldLabel('Presentation Link (Optional)'),
                    _inputField(
                      _presentationUrlController,
                      'https://slides.com/your-presentation',
                      prefixIcon: const Icon(
                        Icons.link_rounded,
                        color: AppTheme.primaryAccent,
                        size: 18,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Field 6: Video Recording Link (Optional)
                    _fieldLabel('Video Recording Link (Optional)'),
                    _inputField(
                      _videoUrlController,
                      'https://youtube.com/watch?v=...',
                      prefixIcon: const Icon(
                        Icons.play_circle_outline_rounded,
                        color: AppTheme.primaryAccent,
                        size: 18,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryAccent,
                          foregroundColor: Colors.black,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: _isSubmitting ? null : _onSave,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.black,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_rounded, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.talkToEdit != null
                                        ? 'Save Changes'
                                        : 'Save Speaking Experience',
                                    style: AppTheme.font(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.1,
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
        ],
      ),
    );
  }

  Widget _buildCoverPreview() {
    final eventName = _eventNameController.text.trim().isNotEmpty
        ? _eventNameController.text.trim()
        : 'Your event name';
    final talkTitle = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'Your talk title';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF38152F),
            Color(0xFF220D22),
            Color(0xFF120815),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background concentric decorative rings
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Positioned(
            right: -10,
            top: 0,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 1.5,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eventName,
                  style: AppTheme.font(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  talkTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.font(
                    color: Colors.white,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Generated from your event name and talk title.',
                  style: AppTheme.font(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141611),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: TextField(
        controller: _descriptionController,
        maxLines: 4,
        style: AppTheme.font(color: Colors.white, fontSize: 13.5),
        cursorColor: AppTheme.primaryAccent,
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText:
              'Share what your talk covers, key takeaways, and prerequisites...',
          hintStyle: AppTheme.font(
            color: Colors.white.withValues(alpha: 0.28),
            fontSize: 13,
          ),
        ),
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
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141611),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: TextField(
        controller: controller,
        style: AppTheme.font(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: AppTheme.primaryAccent,
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          prefixIcon: prefixIcon,
          prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          suffixIcon: suffixIcon,
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
