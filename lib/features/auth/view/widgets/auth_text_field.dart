import 'package:flutter/material.dart';
import 'package:speakwise_mobile/app/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// Light Gray Stadium Pill Text Field (Auth Form Inputs)
/// Exactly matches the user's Auth design reference
/// ═══════════════════════════════════════════════════════════════
class AuthTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool readOnly;
  final bool enabled;
  final VoidCallback? onTap;

  const AuthTextField({
    super.key,
    this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.prefixIcon,
    this.onChanged,
    this.validator,
    this.readOnly = false,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.65,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFDCDCDC), // Light gray pill fill from mockup
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
        child: TextFormField(
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          validator: validator,
          style: AppTheme.font(
            color: const Color(0xFF1A1A1A), // Dark text for high contrast on light gray
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: Colors.black,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTheme.font(
              color: const Color(0xFF757575), // Muted dark placeholder
              fontSize: 14.5,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          ),
        ),
      ),
    );
  }
}
