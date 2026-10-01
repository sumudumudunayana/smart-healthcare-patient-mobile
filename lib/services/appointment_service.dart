import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/appointment.dart';
import '../models/create_appointment_request.dart';

class AppointmentService {
  final ApiClient _apiClient;

  AppointmentService(this._apiClient);

  Future<List<Appointment>> getMyAppointments() async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.appointments}/my',
      );

      final List<dynamic> data = response.data as List<dynamic>;

      return data
          .map((item) => Appointment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw Exception(_extractErrorMessage(error));
    }
  }

  Future<Appointment> createAppointment(
    CreateAppointmentRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.appointments,
        data: request.toJson(),
      );

      return Appointment.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(_extractErrorMessage(error));
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
        final errors = responseData['errors'] as Map<String, dynamic>;

        final messages = <String>[];

        for (final value in errors.values) {
          if (value is List) {
            messages.addAll(value.map((item) => item.toString()));
          } else {
            messages.add(value.toString());
          }
        }

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }
    }

    if (responseData is String && responseData.isNotEmpty) {
      return responseData;
    }

    switch (error.response?.statusCode) {
      case 400:
        return 'The selected appointment time is not available.';
      case 401:
        return 'Your session has expired. Please log in again.';
      case 403:
        return 'You are not allowed to create this appointment.';
      case 404:
        return 'The requested appointment information was not found.';
      case 409:
        return 'This appointment slot has already been booked.';
      default:
        return error.message ??
            'Something went wrong while creating the appointment.';
    }
  }

  Future<List<Appointment>> getDoctorAppointmentsByDate({
    required String doctorId,
    required DateTime date,
  }) async {
    try {
      final formattedDate =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';

      final response = await _apiClient.dio.get(
        '${ApiConstants.appointments}/doctor/$doctorId/date/$formattedDate',
      );

      final List<dynamic> data = response.data as List<dynamic>;

      return data
          .map((item) => Appointment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw Exception(_extractErrorMessage(error));
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _apiClient.dio.patch(
        '${ApiConstants.appointments}/$appointmentId/cancel',
      );
    } on DioException catch (error) {
      throw Exception(_extractCancelErrorMessage(error));
    }
  }

  String _extractCancelErrorMessage(DioException error) {
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
        final errors = responseData['errors'] as Map<String, dynamic>;
        final messages = <String>[];

        for (final value in errors.values) {
          if (value is List) {
            messages.addAll(value.map((item) => item.toString()));
          } else {
            messages.add(value.toString());
          }
        }

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }
    }

    if (responseData is String && responseData.isNotEmpty) {
      return responseData;
    }

    switch (error.response?.statusCode) {
      case 400:
        return 'This appointment cannot be cancelled.';
      case 401:
        return 'Your session has expired. Please log in again.';
      case 403:
        return 'You are not allowed to cancel this appointment.';
      case 404:
        return 'The appointment was not found.';
      case 409:
        return 'This appointment cannot be cancelled at this time.';
      default:
        return error.message ??
            'Something went wrong while cancelling the appointment.';
    }
  }
}
