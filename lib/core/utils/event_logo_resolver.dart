import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:speakwise_mobile/core/config/app_constants.dart';

/// ═══════════════════════════════════════════════════════════════
/// EventLogoResolver
/// Resolves high-resolution, branded event & conference logos online
/// dynamically so speaking engagements never have to rely on plain initials.
/// ═══════════════════════════════════════════════════════════════
class EventLogoResolver {
  static const Map<String, String> _knownConferenceDomains = {
    'pycon': 'python.org',
    'python': 'python.org',
    'devfest': 'developers.google.com',
    'gdg': 'developers.google.com',
    'google i/o': 'developers.google.com',
    'droidcon': 'droidcon.com',
    'flutter': 'flutter.dev',
    'dart': 'dart.dev',
    'react': 'react.dev',
    'next.js': 'nextjs.org',
    'django': 'djangoproject.com',
    'aws': 'aws.amazon.com',
    'amazon': 'aws.amazon.com',
    'docker': 'docker.com',
    'kubecon': 'kubernetes.io',
    'kubernetes': 'kubernetes.io',
    'github': 'github.com',
    'ted': 'ted.com',
    'tedx': 'ted.com',
    'stellar': 'stellar.org',
    'ethereum': 'ethereum.org',
    'web3': 'ethereum.org',
    'vue': 'vuejs.org',
    'angular': 'angular.dev',
    'kotlin': 'kotlinlang.org',
    'swift': 'swift.org',
    'rust': 'rust-lang.org',
    'go': 'go.dev',
    'golang': 'go.dev',
    'indabax': 'deeplearningindaba.com',
    'ai ghana': 'aighana.org',
    'speakwise': 'speakwise.live',
    'cognition': 'cognition-labs.com',
    'agentverse': 'fetch.ai',
  };

  /// Build Google High-Resolution Favicon / Touch Icon URL
  static String getLogoUrlForDomain(String domain, {int size = 128}) {
    return 'https://t2.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://$domain&size=$size';
  }

  /// Resolve high-resolution logo URL from event name & existing image
  static String resolveLogoUrl({
    required String eventName,
    String? currentImage,
  }) {
    // 1. If explicit valid image is provided
    if (currentImage != null && currentImage.trim().isNotEmpty) {
      var img = currentImage.trim();
      if (img.startsWith('/')) {
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
          return '$origin$img';
        } catch (_) {}
      }
      return img;
    }

    final lower = eventName.toLowerCase().trim();

    // 2. Check for known conference brand keywords
    for (final entry in _knownConferenceDomains.entries) {
      if (lower.contains(entry.key)) {
        return getLogoUrlForDomain(entry.value);
      }
    }

    // 3. If eventName contains a domain pattern (e.g. "pycon.gh", "devfest.accra.org", "mysite.com")
    final domainMatch = RegExp(r'([a-zA-Z0-9-]+\.[a-zA-Z]{2,})').firstMatch(eventName);
    if (domainMatch != null) {
      return getLogoUrlForDomain(domainMatch.group(1)!);
    }

    // 4. Clean domain guess from event title slug
    final cleanSlug = eventName
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '')
        .toLowerCase();

    if (cleanSlug.isNotEmpty) {
      return getLogoUrlForDomain('$cleanSlug.com');
    }

    return '';
  }
}
