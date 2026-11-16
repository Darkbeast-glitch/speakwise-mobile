import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speakwise_mobile/core/services/api_client.dart';
import 'package:speakwise_mobile/core/services/storage_service.dart';

class AuthResponse {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String username;
  final String? nationality;
  final String? speakerId;
  final String accessToken;
  final String refreshToken;
  final String? speakerSlug;

  const AuthResponse({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.username,
    this.nationality,
    this.speakerId,
    required this.accessToken,
    required this.refreshToken,
    this.speakerSlug,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    String? slug;
    if (json['profile'] is Map && json['profile']['speaker_profile'] is Map) {
      slug = json['profile']['speaker_profile']['slug']?.toString();
    } else if (json['speaker_profile'] is Map) {
      slug = json['speaker_profile']['slug']?.toString();
    } else if (json['speaker_slug'] != null) {
      slug = json['speaker_slug']?.toString();
    }

    final token = json['access_token']?.toString() ??
        json['access']?.toString() ??
        json['token']?.toString() ??
        json['key']?.toString() ??
        (json['tokens'] is Map ? json['tokens']['access']?.toString() : null) ??
        (json['data'] is Map
            ? (json['data']['access_token']?.toString() ??
                json['data']['access']?.toString() ??
                json['data']['token']?.toString())
            : null) ??
        '';

    final refresh = json['refresh_token']?.toString() ??
        json['refresh']?.toString() ??
        (json['tokens'] is Map ? json['tokens']['refresh']?.toString() : null) ??
        (json['data'] is Map
            ? (json['data']['refresh_token']?.toString() ??
                json['data']['refresh']?.toString())
            : null) ??
        '';

    final userObj = json['user'] is Map ? json['user'] as Map<String, dynamic> : null;

    return AuthResponse(
      id: json['id']?.toString() ?? userObj?['id']?.toString() ?? '',
      email: json['email']?.toString() ?? userObj?['email']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? userObj?['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? userObj?['last_name']?.toString() ?? '',
      username: json['username']?.toString() ?? userObj?['username']?.toString() ?? '',
      nationality: json['nationality']?.toString() ?? userObj?['nationality']?.toString(),
      speakerId: json['speaker_id']?.toString() ??
          (json['speaker_profile'] is Map ? json['speaker_profile']['id']?.toString() : null) ??
          userObj?['speaker_id']?.toString(),
      accessToken: token,
      refreshToken: refresh,
      speakerSlug: slug,
    );
  }
}

class RegisterResponse {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String username;
  final String message;

  const RegisterResponse({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.message,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      message: json['message']?.toString() ?? 'Verification code sent to your email.',
    );
  }
}

abstract class AuthRemoteDataSource {
  Future<AuthResponse> login({required String email, required String password});
  Future<RegisterResponse> register({
    required String firstName,
    required String lastName,
    required String nationality,
    required String username,
    required String email,
    required String password,
  });
  Future<String> verifyOtp({required String email, required String otp});
  Future<String> resendOtp({required String email});
  Future<String> requestPasswordReset({required String email});
  Future<String> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
  });
  Future<void> logout();
  Future<bool> validateSession();
}

class DjangoAuthRemoteDataSource implements AuthRemoteDataSource {
  final ApiClient apiClient;
  final StorageService storageService;

  DjangoAuthRemoteDataSource({
    required this.apiClient,
    required this.storageService,
  });

  @override
  Future<AuthResponse> login({required String email, required String password}) async {
    final response = await apiClient.post(
      '/users/auth/login/',
      authenticated: false,
      body: {
        'email': email,
        'password': password,
      },
    );

    final auth = AuthResponse.fromJson(response as Map<String, dynamic>);

    // Persist JWT session tokens and user identity in StorageService
    await storageService.setAuthToken(auth.accessToken);
    await storageService.setRefreshToken(auth.refreshToken);
    await storageService.setUserId(auth.id);
    await storageService.setUserEmail(auth.email);
    await storageService.setUsername(auth.username);
    if (auth.firstName.isNotEmpty) {
      await storageService.setFirstName(auth.firstName);
    }
    if (auth.lastName.isNotEmpty) {
      await storageService.setLastName(auth.lastName);
    }
    if (auth.nationality != null && auth.nationality!.isNotEmpty) {
      await storageService.setNationality(auth.nationality!);
    }
    if (auth.speakerId != null) {
      await storageService.setSpeakerId(auth.speakerId!);
    }
    if (auth.speakerSlug != null) {
      await storageService.setSpeakerSlug(auth.speakerSlug!);
    }
    await storageService.setIsGuest(false);
    await storageService.setHasSeenOnboarding(true);

    return auth;
  }

  @override
  Future<RegisterResponse> register({
    required String firstName,
    required String lastName,
    required String nationality,
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post(
      '/users/auth/register/',
      authenticated: false,
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'nationality': nationality,
        'username': username,
        'email': email,
        'password': password,
      },
    );

    return RegisterResponse.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<String> verifyOtp({required String email, required String otp}) async {
    final response = await apiClient.post(
      '/users/auth/verify-otp/',
      authenticated: false,
      body: {
        'email': email,
        'otp': otp,
      },
    );

    if (response is Map) {
      final token = response['access_token']?.toString() ??
          response['access']?.toString() ??
          response['token']?.toString() ??
          (response['tokens'] is Map ? response['tokens']['access']?.toString() : null);
      final refresh = response['refresh_token']?.toString() ??
          response['refresh']?.toString() ??
          (response['tokens'] is Map ? response['tokens']['refresh']?.toString() : null);

      if (token != null && token.isNotEmpty) {
        await storageService.setAuthToken(token);
      }
      if (refresh != null && refresh.isNotEmpty) {
        await storageService.setRefreshToken(refresh);
      }
      if (response.containsKey('detail')) {
        return response['detail'].toString();
      }
    }
    return 'Email verified successfully.';
  }

  @override
  Future<String> resendOtp({required String email}) async {
    final response = await apiClient.post(
      '/users/auth/resend-otp/',
      authenticated: false,
      body: {'email': email},
    );

    if (response is Map && response.containsKey('detail')) {
      return response['detail'].toString();
    }
    return 'A new verification code has been sent.';
  }

  @override
  Future<String> requestPasswordReset({required String email}) async {
    final response = await apiClient.post(
      '/users/auth/password-reset/',
      authenticated: false,
      body: {'email': email},
    );

    if (response is Map && response.containsKey('detail')) {
      return response['detail'].toString();
    }
    return 'Password reset email sent successfully.';
  }

  @override
  Future<String> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final response = await apiClient.post(
      '/users/auth/password-reset/confirm',
      authenticated: false,
      body: {
        'email': email,
        'token': token,
        'new_password': newPassword,
      },
    );

    if (response is Map && response.containsKey('detail')) {
      return response['detail'].toString();
    }
    return 'Password reset successfully.';
  }

  @override
  Future<void> logout() async {
    final refreshToken = storageService.refreshToken;
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await apiClient.post(
          '/users/auth/logout/',
          body: {'refresh_token': refreshToken},
        );
      }
    } catch (_) {
      // Ignore network errors on logout
    } finally {
      await storageService.clearAuth();
    }
  }

  @override
  Future<bool> validateSession() async {
    final token = storageService.authToken;
    if (token == null || token.isEmpty) return false;
    if (storageService.isGuest) return true;

    try {
      final res = await apiClient.get('/users/me/', authenticated: true);
      if (res is Map<String, dynamic>) {
        if (res['id'] != null) {
          await storageService.setUserId(res['id'].toString());
        }
        if (res['email'] != null) {
          await storageService.setUserEmail(res['email'].toString());
        }
        if (res['username'] != null) {
          await storageService.setUsername(res['username'].toString());
        }
        if (res['first_name'] != null && res['first_name'].toString().isNotEmpty) {
          await storageService.setFirstName(res['first_name'].toString());
        }
        if (res['last_name'] != null && res['last_name'].toString().isNotEmpty) {
          await storageService.setLastName(res['last_name'].toString());
        }
        final spSlug = res['speaker_slug']?.toString() ??
            (res['speaker_profile'] is Map ? res['speaker_profile']['slug']?.toString() : null);
        if (spSlug != null && spSlug.isNotEmpty) {
          await storageService.setSpeakerSlug(spSlug);
        }
        return true;
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // Try refresh token once
        final refreshed = await apiClient.tryRefreshToken();
        if (refreshed) return true;
        // Keep credentials cached even if refresh encounters a temporary glitch;
        // only explicit user logout clears auth.
        return true;
      }
    } catch (e) {
      // Offline / network failure: keep user logged in with cached credentials
      return true;
    }
    return true;
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storageService = ref.watch(storageServiceProvider);
  return DjangoAuthRemoteDataSource(
    apiClient: apiClient,
    storageService: storageService,
  );
});
