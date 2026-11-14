import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/core/config/app_constants.dart';

/// ═══════════════════════════════════════════════════════════════
/// AppNetworkImage Component
/// Resilient image loader that uses CachedNetworkImage with an
/// automatic instant Image.network fallback to prevent blank/missing
/// images if native SQLite caching is not yet compiled or unavailable.
/// ═══════════════════════════════════════════════════════════════
class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  static String resolveFullUrl(String rawUrl) {
    var effectiveUrl = rawUrl.trim();
    if (effectiveUrl.startsWith('/')) {
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
        effectiveUrl = '$origin$effectiveUrl';
      } catch (_) {}
    }
    return effectiveUrl;
  }

  Widget _buildLoadingIndicator() {
    return placeholder ??
        Container(
          width: width,
          height: height,
          color: const Color(0xFF1B1E16),
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryAccent,
              ),
            ),
          ),
        );
  }

  Widget _buildFallbackAssetOrPlaceholder() {
    if (errorWidget != null) return errorWidget!;

    return Image.asset(
      'assets/images/cortex_summit.jpg',
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, _, _) => Container(
        width: width,
        height: height,
        color: const Color(0xFF1B1E16),
        child: const Center(
          child: Icon(
            Icons.image_outlined,
            color: AppTheme.textMuted,
            size: 32,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveUrl = resolveFullUrl(imageUrl);

    Widget imageWidget;

    if (effectiveUrl.startsWith('http://') || effectiveUrl.startsWith('https://')) {
      imageWidget = CachedNetworkImage(
        imageUrl: effectiveUrl,
        fit: fit,
        width: width,
        height: height,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => _buildLoadingIndicator(),
        errorWidget: (context, url, error) {
          // Resilient instant fallback: If CachedNetworkImage fails (e.g. sqflite MissingPluginException
          // before a fresh rebuild or disk store issue), instantly load via Flutter's built-in Image.network!
          return Image.network(
            effectiveUrl,
            fit: fit,
            width: width,
            height: height,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildLoadingIndicator();
            },
            errorBuilder: (context, err, stack) => _buildFallbackAssetOrPlaceholder(),
          );
        },
      );
    } else {
      imageWidget = Image.asset(
        effectiveUrl.isNotEmpty ? effectiveUrl : 'assets/images/cortex_summit.jpg',
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => _buildFallbackAssetOrPlaceholder(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
