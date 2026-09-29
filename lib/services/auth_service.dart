import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/auth_response.dart';

class AuthService {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  AuthService(
    this._apiClient,
    this._secureStorage,
  );

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);

      await _secureStorage.saveAuthData(
        accessToken: authResponse.token,
        refreshToken: authResponse.refreshToken,
        userId: authResponse.userId,
        fullName: authResponse.fullName,
        email: authResponse.email,
        role: authResponse.role,
      );

      return authResponse;
    } on DioException catch (error) {
      throw Exception(_extractErrorMessage(error));
    }
  }

  Future<AuthResponse> register({
    required String fullName,
    required String email,
    String? phone,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.register,
        data: {
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);

      await _secureStorage.saveAuthData(
        accessToken: authResponse.token,
        refreshToken: authResponse.refreshToken,
        userId: authResponse.userId,
        fullName: authResponse.fullName,
        email: authResponse.email,
        role: authResponse.role,
      );

      return authResponse;
    } on DioException catch (error) {
      throw Exception(_extractErrorMessage(error));
    }
  }

  Future<AuthResponse> refreshToken() async {
    final refreshToken = await _secureStorage.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('No refresh token available.');
    }

    try {
      final response = await _apiClient.dio.post(
        ApiConstants.refresh,
        data: {
          'refreshToken': refreshToken,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);

      await _secureStorage.saveAuthData(
        accessToken: authResponse.token,
        refreshToken: authResponse.refreshToken,
        userId: authResponse.userId,
        fullName: authResponse.fullName,
        email: authResponse.email,
        role: authResponse.role,
      );

      return authResponse;
    } on DioException catch (error) {
      await _secureStorage.clearAuthData();
      throw Exception(_extractErrorMessage(error));
    }
  }

  Future<void> logout() async {
    final refreshToken = await _secureStorage.getRefreshToken();

    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _apiClient.dio.post(
          ApiConstants.logout,
          data: {
            'refreshToken': refreshToken,
          },
        );
      }
    } finally {
      await _secureStorage.clearAuthData();
    }
  }

  String _extractErrorMessage(DioException error) {
    final responseData = error.response?.data;

    if (responseData is Map<String, dynamic>) {
      if (responseData['message'] != null) {
        return responseData['message'].toString();
      }

      if (responseData['title'] != null) {
        return responseData['title'].toString();
      }
    }

    if (error.response?.statusCode == 401) {
      return 'Invalid email or password.';
    }

    if (error.response?.statusCode == 400) {
      return 'Invalid request. Please check your details.';
    }

    return 'Unable to connect to the server.';
  }
}