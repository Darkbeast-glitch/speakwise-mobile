import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speakwise_mobile/app/app_theme.dart';

enum AppButtonType {
  primary, // Neon Acid-Lime (#AAD900)
  light,   // High-contrast Crisp White (#FFFFFF)
  dark,    // Obsidian Dark Surface (#1A1D13)
  ghost,   // Transparent Bordered Pill
}

/// ═══════════════════════════════════════════════════════════════
/// SpeakWise Stadium Pill Button
/// ═══════════════════════════════════════════════════════════════
class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool isLoading;
  final Widget? icon;
  final double height;
  final double? width;
  final EdgeInsetsGeometry padding;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.height = 54.0,
    this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  });

  const AppButton.light({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height = 54.0,
    this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  }) : type = AppButtonType.light;

  const AppButton.dark({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height = 54.0,
    this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  }) : type = AppButtonType.dark;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color backgroundColor;
    Color textColor;
    BorderSide borderSide = BorderSide.none;

    switch (widget.type) {
      case AppButtonType.primary:
        backgroundColor = isEnabled
            ? (_isPressed ? const Color(0xFF98C200) : AppTheme.primaryAccent)
            : AppTheme.buttonDark;
        textColor = isEnabled ? AppTheme.textOnPrimary : AppTheme.textMuted;
        break;
      case AppButtonType.light:
        backgroundColor = isEnabled
            ? (_isPressed ? AppTheme.buttonLightPressed : AppTheme.buttonLight)
            : AppTheme.buttonDark;
        textColor = isEnabled ? AppTheme.textOnPrimary : AppTheme.textMuted;
        break;
      case AppButtonType.dark:
        backgroundColor = isEnabled
            ? (_isPressed ? const Color(0xFF24281A) : AppTheme.buttonDark)
            : AppTheme.surfaceDark;
        textColor = isEnabled ? AppTheme.textPrimary : AppTheme.textMuted;
        borderSide = const BorderSide(color: AppTheme.surfaceBorder, width: 1);
        break;
      case AppButtonType.ghost:
        backgroundColor = Colors.transparent;
        textColor = isEnabled ? AppTheme.textPrimary : AppTheme.textMuted;
        borderSide = const BorderSide(color: AppTheme.surfaceBorder, width: 1);
        break;
    }

    return AnimatedScale(
      scale: _isPressed && isEnabled ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      child: SizedBox(
        width: widget.width ?? double.infinity,
        height: widget.height,
        child: Material(
          color: backgroundColor,
          shape: StadiumBorder(side: borderSide),
          child: InkWell(
            customBorder: const StadiumBorder(),
            splashColor: Colors.black.withValues(alpha: 0.08),
            highlightColor: Colors.transparent,
            onHighlightChanged: (pressed) {
              setState(() => _isPressed = pressed);
            },
            onTap: isEnabled
                ? () {
                    HapticFeedback.lightImpact();
                    widget.onPressed?.call();
                  }
                : null,
            child: Padding(
              padding: widget.padding,
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: textColor,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            widget.icon!,
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.text,
                            style: AppTheme.font(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
