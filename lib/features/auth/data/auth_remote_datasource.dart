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
    }

    return AuthResponse(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      nationality: json['nationality']?.toString(),
      speakerId: json['speaker_id']?.toString(),
      accessToken: json['access_token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString() ?? '',
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

    if (response is Map && response.containsKey('detail')) {
      return response['detail'].toString();
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
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storageService = ref.watch(storageServiceProvider);
  return DjangoAuthRemoteDataSource(
    apiClient: apiClient,
    storageService: storageService,
  );
});
