import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/notification.dart';

class NotificationService {
  final ApiClient _apiClient;

  NotificationService(this._apiClient);

  Future<List<PatientNotification>> getMyNotifications() async {
    try {
      final response = await _apiClient.dio.get(
        '/Notifications/my',
      );

      final List<dynamic> data = response.data as List<dynamic>;

      return data
          .map(
            (json) => PatientNotification.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw Exception(_extractErrorMessage(error));
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  Future<PatientNotification> markAsRead(
    String notificationId,
  ) async {
    try {
      final response = await _apiClient.dio.patch(
        '/Notifications/$notificationId/read',
      );

      return PatientNotification.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw Exception(_extractErrorMessage(error));
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  String _extractErrorMessage(DioException error) {
    final responseData = error.response?.data;

    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'];

      if (message != null &&
          message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    if (error.response?.statusCode == 401) {
      return 'Your session has expired. Please log in again.';
    }

    if (error.response?.statusCode == 404) {
      return 'Notification was not found.';
    }

    if (error.response?.statusCode == 403) {
      return 'You do not have permission to modify this notification.';
    }

    return 'Unable to process the notification request.';
  }
}