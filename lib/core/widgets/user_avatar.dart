import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/core/config/app_constants.dart';

/// ═══════════════════════════════════════════════════════════════
/// UserAvatar Component
/// Elegant avatar displaying user photo if available, or clean
/// typographic initials fallback (avoiding hardcoded placeholder photos).
/// ═══════════════════════════════════════════════════════════════
class UserAvatar extends StatelessWidget {
  final String? name;
  final String? avatarUrl;
  final double size;
  final bool showBorder;
  final Color? borderColor;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;

  const UserAvatar({
    super.key,
    this.name,
    this.avatarUrl,
    this.size = 40.0,
    this.showBorder = true,
    this.borderColor,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
  });

  String get _initials {
    final rawName = (name ?? '').trim();
    if (rawName.isEmpty) return '';
    final parts = rawName.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final second = parts[1].isNotEmpty ? parts[1][0] : '';
      return '$first$second'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '';
  }

  bool get _hasValidCustomImage {
    if (avatarUrl == null || avatarUrl!.trim().isEmpty) return false;
    final path = avatarUrl!.trim();

    // Never use Julius.png as avatar image fallback
    if (path.contains('Julius.png')) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? AppTheme.surfaceBorder;
    final effectiveBgColor = backgroundColor ?? const Color(0xFF1E211A);
    final effectiveTextColor = textColor ?? AppTheme.primaryAccent;
    final effectiveFontSize = fontSize ?? (size * 0.38).clamp(10.0, 22.0);

    Widget content;

    if (_hasValidCustomImage) {
      var path = avatarUrl!.trim();
      if (path.startsWith('/')) {
        try {
          String base = AppConstants.defaultApiUrl;
          if (dotenv.isInitialized) {
            final envUrl = dotenv.maybeGet('API_BASE_URL');
            if (envUrl != null && envUrl.isNotEmpty) {
              base = envUrl;
            }
          }
          final baseUri = Uri.parse(base);
          final origin =
              '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
          path = '$origin$path';
        } catch (_) {}
      }

      if (path.startsWith('http://') || path.startsWith('https://')) {
        content = CachedNetworkImage(
          imageUrl: path,
          fit: BoxFit.cover,
          width: size,
          height: size,
          fadeInDuration: const Duration(milliseconds: 150),
          placeholder: (context, url) => _buildInitialsPlaceholder(
            effectiveBgColor,
            effectiveTextColor,
            effectiveFontSize,
          ),
          errorWidget: (context, url, error) {
            // Fallback to Image.network if CachedNetworkImage encounters native plugin issue
            return Image.network(
              path,
              fit: BoxFit.cover,
              width: size,
              height: size,
              errorBuilder: (_, _, _) => _buildInitialsPlaceholder(
                effectiveBgColor,
                effectiveTextColor,
                effectiveFontSize,
              ),
            );
          },
        );
      } else if (File(path).existsSync()) {
        content = Image.file(
          File(path),
          fit: BoxFit.cover,
          width: size,
          height: size,
        );
      } else {
        content = Image.asset(
          path,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) => _buildInitialsPlaceholder(
            effectiveBgColor,
            effectiveTextColor,
            effectiveFontSize,
          ),
        );
      }
    } else {
      content = _buildInitialsPlaceholder(
        effectiveBgColor,
        effectiveTextColor,
        effectiveFontSize,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder ? Border.all(color: effectiveBorderColor, width: 1.2) : null,
      ),
      child: ClipOval(child: content),
    );
  }

  Widget _buildInitialsPlaceholder(Color bgColor, Color txtColor, double fSize) {
    final initials = _initials;

    return Container(
      width: size,
      height: size,
      color: bgColor,
      child: Center(
        child: initials.isNotEmpty
            ? Text(
                initials,
                style: AppTheme.font(
                  color: txtColor,
                  fontSize: fSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              )
            : Icon(
                Icons.person_rounded,
                color: txtColor.withValues(alpha: 0.8),
                size: size * 0.55,
              ),
      ),
    );
  }
}
