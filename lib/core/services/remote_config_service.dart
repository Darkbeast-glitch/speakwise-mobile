import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speakwise_mobile/core/config/app_constants.dart';

/// ═══════════════════════════════════════════════════════════════
/// RemoteConfigService
/// Robust configuration manager leveraging Firebase Remote Config
/// with smart fallback to local .env and AppConstants.
/// ═══════════════════════════════════════════════════════════════
class RemoteConfigService {
  // Config Parameter Keys
  static const String keyApiBaseUrl = 'api_base_url';
  static const String keyEnableFeaturedCarousel = 'enable_featured_carousel';
  static const String keyEnableOnlineEventLogos = 'enable_online_event_logos';
  static const String keyMaintenanceMode = 'maintenance_mode';
  static const String keyMaintenanceMessage = 'maintenance_message';
  static const String keyMinSupportedVersion = 'min_supported_version';
  static const String keyConnectTimeoutSeconds = 'connect_timeout_seconds';

  FirebaseRemoteConfig? _remoteConfig;
  StreamSubscription<RemoteConfigUpdate>? _configSubscription;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Returns baseline default values sourced from .env and AppConstants
  static Map<String, dynamic> getDefaultParameters() {
    String defaultBaseUrl = AppConstants.defaultApiUrl;
    try {
      if (dotenv.isInitialized) {
        final envUrl = dotenv.maybeGet('API_BASE_URL');
        if (envUrl != null && envUrl.trim().isNotEmpty) {
          defaultBaseUrl = envUrl.trim();
        }
      }
    } catch (_) {}

    return {
      keyApiBaseUrl: defaultBaseUrl,
      keyEnableFeaturedCarousel: true,
      keyEnableOnlineEventLogos: true,
      keyMaintenanceMode: false,
      keyMaintenanceMessage:
          'SpeakWise is undergoing scheduled improvements. Please check back shortly.',
      keyMinSupportedVersion: '1.0.0',
      keyConnectTimeoutSeconds: 15,
    };
  }

  /// Initialize Firebase Remote Config safely
  Future<void> init() async {
    try {
      // Ensure Firebase Core has been initialized before accessing RemoteConfig
      if (Firebase.apps.isEmpty) {
        debugPrint('ℹ️ Firebase app not initialized. Using local .env defaults for RemoteConfig.');
        _isInitialized = true;
        return;
      }

      final instance = FirebaseRemoteConfig.instance;
      _remoteConfig = instance;

      // Configure fetch intervals: 1 minute during debug for live testing, 1 hour in release
      await instance.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode ? const Duration(minutes: 1) : const Duration(hours: 1),
        ),
      );

      // Load defaults
      final defaults = getDefaultParameters();
      await instance.setDefaults(defaults);

      // Attempt to fetch & activate remote parameters
      final activated = await instance.fetchAndActivate();
      debugPrint('🚀 Firebase Remote Config initialized. New values activated: $activated');
      debugPrint('🌐 Effective API Base URL: $apiBaseUrl');

      // Listen for real-time config updates (Firebase Remote Config v5+)
      try {
        _configSubscription = instance.onConfigUpdated.listen(
          (event) async {
            try {
              await instance.activate();
              debugPrint('🔄 Remote Config updated in real-time with keys: ${event.updatedKeys}');
            } catch (e) {
              debugPrint('⚠️ Error activating real-time remote config update: $e');
            }
          },
          onError: (error) {
            debugPrint('⚠️ Remote Config update stream notice: $error');
          },
        );
      } catch (e) {
        debugPrint('ℹ️ Real-time RemoteConfig update stream not available: $e');
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('⚠️ RemoteConfigService initialization failed (using local fallbacks): $e');
      _isInitialized = true;
    }
  }

  /// Active API Base URL
  /// Priority:
  /// 1. Local .env override (in debug mode, or if pointing to local host/IP)
  /// 2. Firebase Remote Config (for production / release)
  /// 3. Fallback to .env / AppConstants
  String get apiBaseUrl {
    // 1. Local Development Priority: If in debug mode or if .env specifies a local URL, respect .env first
    try {
      if (dotenv.isInitialized) {
        final envUrl = dotenv.maybeGet('API_BASE_URL');
        if (envUrl != null && envUrl.trim().isNotEmpty) {
          var trimmed = envUrl.trim();
          final isLocalTarget = trimmed.contains('localhost') ||
              trimmed.contains('127.0.0.1') ||
              trimmed.contains('192.168.') ||
              trimmed.contains('10.') ||
              trimmed.contains('172.');
          if (kDebugMode || isLocalTarget) {
            return trimmed;
          }
        }
      }
    } catch (_) {}

    // 2. Production / Release: Fetch from Firebase Remote Config if available
    if (_remoteConfig != null) {
      try {
        final remoteVal = _remoteConfig!.getString(keyApiBaseUrl).trim();
        if (remoteVal.isNotEmpty) return remoteVal;
      } catch (_) {}
    }

    // 3. Fallback to .env in release if RemoteConfig didn't provide a value
    try {
      if (dotenv.isInitialized) {
        final envUrl = dotenv.maybeGet('API_BASE_URL');
        if (envUrl != null && envUrl.trim().isNotEmpty) {
          return envUrl.trim();
        }
      }
    } catch (_) {}

    return AppConstants.defaultApiUrl;
  }

  /// Whether the auto-swiping hero banner on the Explore screen is enabled
  bool get enableFeaturedCarousel {
    if (_remoteConfig != null) {
      try {
        return _remoteConfig!.getBool(keyEnableFeaturedCarousel);
      } catch (_) {}
    }
    return true;
  }

  /// Whether to fetch branded conference logos online for Events Spoken
  bool get enableOnlineEventLogos {
    if (_remoteConfig != null) {
      try {
        return _remoteConfig!.getBool(keyEnableOnlineEventLogos);
      } catch (_) {}
    }
    return true;
  }

  /// Whether the app is currently in maintenance mode
  bool get isMaintenanceMode {
    if (_remoteConfig != null) {
      try {
        return _remoteConfig!.getBool(keyMaintenanceMode);
      } catch (_) {}
    }
    return false;
  }

  /// Custom maintenance banner message
  String get maintenanceMessage {
    if (_remoteConfig != null) {
      try {
        final msg = _remoteConfig!.getString(keyMaintenanceMessage).trim();
        if (msg.isNotEmpty) return msg;
      } catch (_) {}
    }
    return 'SpeakWise is undergoing scheduled improvements. Please check back shortly.';
  }

  /// Minimum supported app version for mandatory update prompt
  String get minSupportedVersion {
    if (_remoteConfig != null) {
      try {
        final ver = _remoteConfig!.getString(keyMinSupportedVersion).trim();
        if (ver.isNotEmpty) return ver;
      } catch (_) {}
    }
    return '1.0.0';
  }

  /// Connect timeout in seconds
  int get connectTimeoutSeconds {
    if (_remoteConfig != null) {
      try {
        final val = _remoteConfig!.getInt(keyConnectTimeoutSeconds);
        if (val > 0) return val;
      } catch (_) {}
    }
    return 15;
  }

  /// Diagnostic dump of all current configuration values
  Map<String, dynamic> getAllValues() {
    return {
      'api_base_url': apiBaseUrl,
      'enable_featured_carousel': enableFeaturedCarousel,
      'enable_online_event_logos': enableOnlineEventLogos,
      'maintenance_mode': isMaintenanceMode,
      'maintenance_message': maintenanceMessage,
      'min_supported_version': minSupportedVersion,
      'connect_timeout_seconds': connectTimeoutSeconds,
      'is_firebase_connected': _remoteConfig != null,
    };
  }

  /// Clean up streams
  void dispose() {
    _configSubscription?.cancel();
  }
}

/// Riverpod Provider for RemoteConfigService
final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService();
});
