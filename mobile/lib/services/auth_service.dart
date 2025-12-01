import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<AuthResponse> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/register',
        data: {
          'email': email,
          'password': password,
          if (fullName != null) 'fullName': fullName,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);
      await _apiClient.saveTokens(
        authResponse.tokens.accessToken,
        authResponse.tokens.refreshToken,
      );

      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);
      await _apiClient.saveTokens(
        authResponse.tokens.accessToken,
        authResponse.tokens.refreshToken,
      );

      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _apiClient.clearTokens();
  }

  Future<bool> isLoggedIn() async {
    final token = await _apiClient.getAccessToken();
    return token != null;
  }
}
