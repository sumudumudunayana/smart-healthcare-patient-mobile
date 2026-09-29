import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/user_profile.dart';

class UserService {
  final ApiClient _apiClient;

  UserService(this._apiClient);

  Future<UserProfile> getMyProfile() async {
    try {
      final response = await _apiClient.dio.get(
        '/Users/me',
      );

      return UserProfile.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw Exception(
        _extractErrorMessage(error),
      );
    }
  }

  Future<UserProfile> updateMyProfile({
    required String fullName,
    String? phone,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/Users/me',
        data: {
          'fullName': fullName,
          'phone': phone,
        },
      );

      return UserProfile.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw Exception(
        _extractErrorMessage(error),
      );
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

      if (responseData['detail'] != null) {
        return responseData['detail'].toString();
      }

      if (responseData['errors'] is Map<String, dynamic>) {
        final errors =
            responseData['errors'] as Map<String, dynamic>;

        final messages = <String>[];

        for (final value in errors.values) {
          if (value is List) {
            messages.addAll(
              value.map(
                (item) => item.toString(),
              ),
            );
          } else {
            messages.add(
              value.toString(),
            );
          }
        }

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }
    }

    if (responseData is String &&
        responseData.isNotEmpty) {
      return responseData;
    }

    switch (error.response?.statusCode) {
      case 400:
        return 'Please check the information you entered.';

      case 401:
        return 'Your session has expired. Please log in again.';

      case 403:
        return 'You are not allowed to update this profile.';

      case 404:
        return 'User profile was not found.';

      default:
        return error.message ??
            'Something went wrong while updating your profile.';
    }
  }
}