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

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParameters);
    try {
      final response = await _client
          .get(uri, headers: _buildHeaders(authenticated: authenticated, customHeaders: headers))
          .timeout(AppConstants.receiveTimeout);

      return _processResponse(response);
    } on SocketException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Cannot reach server at $_baseUrl. Check your Wi-Fi network and backend status (${e.message}).',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 500, message: e.toString());
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
    } on SocketException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Cannot reach server at $_baseUrl. Check your Wi-Fi network and backend status (${e.message}).',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 500, message: e.toString());
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
    } on SocketException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Cannot reach server at $_baseUrl. Check your Wi-Fi network and backend status (${e.message}).',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 500, message: e.toString());
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
    } on SocketException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Cannot reach server at $_baseUrl. Check your Wi-Fi network and backend status (${e.message}).',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 500, message: e.toString());
    }
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
