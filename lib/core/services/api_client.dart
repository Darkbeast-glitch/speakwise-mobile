import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:speakwise_mobile/core/config/app_constants.dart';
import 'package:speakwise_mobile/core/services/remote_config_service.dart';
import 'package:speakwise_mobile/core/services/storage_service.dart';

/// Custom Exception thrown during API operations
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic data;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.data,
  });

  @override
  String toString() => 'ApiException (status: $statusCode): $message';
}

/// ═══════════════════════════════════════════════════════════════
/// SpeakWise Django REST API Client
/// Implements JSON over HTTP/S with Bearer JWT Authentication
/// ═══════════════════════════════════════════════════════════════
class ApiClient {
  final http.Client _client;
  final StorageService storageService;
  final String _baseUrl;

  ApiClient({
    http.Client? client,
    required this.storageService,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = _resolveBaseUrl(baseUrl) {
    debugPrint('🌐 SpeakWise ApiClient connected to: $_baseUrl');
  }

  static String _resolveBaseUrl(String? customBaseUrl) {
    if (customBaseUrl != null && customBaseUrl.isNotEmpty) {
      return _normalizeUrl(customBaseUrl);
    }
    try {
      if (dotenv.isInitialized) {
        final envUrl = dotenv.maybeGet('API_BASE_URL');
        if (envUrl != null && envUrl.isNotEmpty) {
          return _normalizeUrl(envUrl);
        }
      }
    } catch (_) {
      // Fallback safely if dotenv is not initialized in tests
    }
    return _defaultEnvironmentUrl();
  }

  static String _normalizeUrl(String rawUrl) {
    var url = rawUrl.trim().replaceAll(RegExp(r'/+$'), '');

    // 1. Fix https:// on local / private LAN addresses (Django dev server uses plain http://)
    if (url.startsWith('https://127.0.0.1') ||
        url.startsWith('https://localhost') ||
        url.startsWith('https://10.') ||
        url.startsWith('https://192.168.') ||
        url.startsWith('https://172.')) {
      url = url.replaceFirst('https://', 'http://');
    }

    // 2. Android Emulator mapping: 127.0.0.1 and localhost point to the emulator itself.
    // Map to 10.0.2.2 so the Android Emulator communicates with your Mac's host machine.
    if (!kIsWeb && Platform.isAndroid) {
      url = url.replaceAll('127.0.0.1', '10.0.2.2').replaceAll('localhost', '10.0.2.2');
    }

    return url;
  }

  static String _defaultEnvironmentUrl() {
    return AppConstants.defaultApiUrl.replaceAll(RegExp(r'/+$'), '');
  }

  String get baseUrl => _baseUrl;

  Map<String, String> _buildHeaders({bool authenticated = true, Map<String, String>? customHeaders}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Client-Platform': 'mobile-app',
      'X-App-Name': 'speakwise-mobile',
      'X-Platform': !kIsWeb && Platform.isIOS ? 'ios' : 'android',
      'User-Agent': 'SpeakWise-Mobile/1.0.0 (${!kIsWeb && Platform.isIOS ? 'iOS' : 'Android'})',
    };

    if (authenticated) {
      final token = storageService.authToken;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$_baseUrl$cleanPath';

    if (queryParameters == null || queryParameters.isEmpty) {
      return Uri.parse(fullUrl);
    }

    final queryMap = queryParameters.map((key, value) => MapEntry(key, value.toString()));
    return Uri.parse(fullUrl).replace(queryParameters: queryMap);
  }

  bool _isRefreshing = false;
  final Map<String, Future<dynamic>> _inFlightGetRequests = {};

  Future<bool> tryRefreshToken() => _tryRefreshToken();

  Future<bool> _tryRefreshToken() async {
    final refresh = storageService.refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    if (_isRefreshing) return false;

    _isRefreshing = true;
    try {
      final refreshEndpoints = [
        '/users/auth/token/refresh/',
        '/token/refresh/',
        '/auth/token/refresh/',
        '/users/token/refresh/',
      ];

      for (final endpoint in refreshEndpoints) {
        try {
          final uri = _buildUri(endpoint);
          final response = await _client
              .post(
                uri,
                headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
                body: jsonEncode({'refresh': refresh}),
              )
              .timeout(const Duration(seconds: 8));

          if (response.statusCode >= 200 && response.statusCode < 300) {
            final dynamic json = jsonDecode(response.body);
            if (json is Map) {
              final newAccess = json['access']?.toString() ??
                  json['access_token']?.toString() ??
                  json['token']?.toString();
              if (newAccess != null && newAccess.isNotEmpty) {
                await storageService.setAuthToken(newAccess);
                final newRefresh = json['refresh']?.toString() ?? json['refresh_token']?.toString();
                if (newRefresh != null && newRefresh.isNotEmpty) {
                  await storageService.setRefreshToken(newRefresh);
                }
                debugPrint('🔄 JWT access token successfully refreshed via $endpoint');
                return true;
              }
            }
          }
        } catch (_) {
          continue;
        }
      }
    } catch (e) {
      debugPrint('Token refresh attempt notice: $e');
    } finally {
      _isRefreshing = false;
    }
    return false;
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final requestKey = 'GET:${uri.toString()}:$authenticated';

    if (_inFlightGetRequests.containsKey(requestKey)) {
      debugPrint('⚡ Coalescing concurrent in-flight GET request: $requestKey');
      return await _inFlightGetRequests[requestKey]!;
    }

    final future = _executeGet(
      uri,
      authenticated: authenticated,
      headers: headers,
    );
    _inFlightGetRequests[requestKey] = future;
    try {
      return await future;
    } finally {
      _inFlightGetRequests.remove(requestKey);
    }
  }

  Future<dynamic> _executeGet(
    Uri uri, {
    required bool authenticated,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client
          .get(uri, headers: _buildHeaders(authenticated: authenticated, customHeaders: headers))
          .timeout(AppConstants.receiveTimeout);

      return _processResponse(response);
    } on ApiException catch (e) {
      if (e.statusCode == 401 && authenticated && storageService.refreshToken != null && storageService.refreshToken!.isNotEmpty) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final retryRes = await _client
              .get(uri, headers: _buildHeaders(authenticated: authenticated, customHeaders: headers))
              .timeout(AppConstants.receiveTimeout);
          return _processResponse(retryRes);
        }
      }
      rethrow;
    } on SocketException catch (e) {
      _handleRequestError(e);
    } catch (e) {
      _handleRequestError(e);
    }
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    try {
      final response = await _client
          .post(
            uri,
            headers: _buildHeaders(authenticated: authenticated, customHeaders: headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(AppConstants.connectTimeout);

      return _processResponse(response);
    } on ApiException catch (e) {
      if (e.statusCode == 401 && authenticated && storageService.refreshToken != null && storageService.refreshToken!.isNotEmpty) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final retryRes = await _client
              .post(
                uri,
                headers: _buildHeaders(authenticated: authenticated, customHeaders: headers),
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(AppConstants.connectTimeout);
          return _processResponse(retryRes);
        }
      }
      rethrow;
    } on SocketException catch (e) {
      _handleRequestError(e);
    } catch (e) {
      _handleRequestError(e);
    }
  }

  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    try {
      final response = await _client
          .patch(
            uri,
            headers: _buildHeaders(authenticated: authenticated, customHeaders: headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(AppConstants.connectTimeout);

      return _processResponse(response);
    } on ApiException catch (e) {
      if (e.statusCode == 401 && authenticated && storageService.refreshToken != null && storageService.refreshToken!.isNotEmpty) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final retryRes = await _client
              .patch(
                uri,
                headers: _buildHeaders(authenticated: authenticated, customHeaders: headers),
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(AppConstants.connectTimeout);
          return _processResponse(retryRes);
        }
      }
      rethrow;
    } on SocketException catch (e) {
      _handleRequestError(e);
    } catch (e) {
      _handleRequestError(e);
    }
  }

  Future<dynamic> delete(
    String path, {
    bool authenticated = true,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    try {
      final response = await _client
          .delete(uri, headers: _buildHeaders(authenticated: authenticated, customHeaders: headers))
          .timeout(AppConstants.connectTimeout);

      return _processResponse(response);
    } on ApiException catch (e) {
      if (e.statusCode == 401 && authenticated && storageService.refreshToken != null && storageService.refreshToken!.isNotEmpty) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final retryRes = await _client
              .delete(uri, headers: _buildHeaders(authenticated: authenticated, customHeaders: headers))
              .timeout(AppConstants.connectTimeout);
          return _processResponse(retryRes);
        }
      }
      rethrow;
    } on SocketException catch (e) {
      _handleRequestError(e);
    } catch (e) {
      _handleRequestError(e);
    }
  }

  Never _handleRequestError(dynamic e) {
    if (e is ApiException) throw e;

    final errStr = e.toString().toLowerCase();

    if (e is TimeoutException ||
        errStr.contains('timeout') ||
        errStr.contains('future not completed') ||
        errStr.contains('timed out')) {
      throw const ApiException(
        statusCode: 408,
        message:
            'Connection timed out. The server took too long to respond. Please check your internet connection and try again.',
      );
    }

    if (e is SocketException ||
        errStr.contains('socketexception') ||
        errStr.contains('failed host lookup') ||
        errStr.contains('connection refused') ||
        errStr.contains('network is unreachable')) {
      throw ApiException(
        statusCode: 0,
        message:
            'Cannot reach server at $_baseUrl. Please check your Wi-Fi or data connection and try again.',
      );
    }

    if (errStr.contains('handshake') || errStr.contains('certificate')) {
      throw const ApiException(
        statusCode: 0,
        message: 'Secure connection error. Please try again.',
      );
    }

    throw const ApiException(
      statusCode: 500,
      message:
          'A network error occurred. Please check your connection and try again.',
    );
  }

  dynamic _processResponse(http.Response response) {
    final statusCode = response.statusCode;
    final bodyString = response.body;

    dynamic jsonBody;
    if (bodyString.isNotEmpty) {
      try {
        jsonBody = jsonDecode(bodyString);
      } catch (_) {
        jsonBody = bodyString;
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      return jsonBody;
    }

    String errorMessage = 'Request failed with status $statusCode';
    if (jsonBody is Map<String, dynamic>) {
      if (jsonBody.containsKey('detail')) {
        final detail = jsonBody['detail'];
        errorMessage = detail is List ? detail.join(', ') : detail.toString();
      } else if (jsonBody.containsKey('non_field_errors')) {
        final nfe = jsonBody['non_field_errors'];
        errorMessage = nfe is List ? nfe.join(', ') : nfe.toString();
      } else if (jsonBody.containsKey('message')) {
        errorMessage = jsonBody['message'].toString();
      } else if (jsonBody.containsKey('error')) {
        errorMessage = jsonBody['error'].toString();
      } else {
        errorMessage = jsonBody.entries.map((e) {
          final val = e.value is List ? (e.value as List).join(', ') : e.value;
          return '${e.key}: $val';
        }).join('\n');
      }
    }

    debugPrint('API Error [$statusCode]: $errorMessage');
    throw ApiException(
      statusCode: statusCode,
      message: errorMessage,
      data: jsonBody,
    );
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final remoteConfig = ref.watch(remoteConfigServiceProvider);
  return ApiClient(
    storageService: storage,
    baseUrl: remoteConfig.apiBaseUrl,
  );
});
