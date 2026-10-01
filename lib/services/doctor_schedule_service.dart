import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/doctor_schedule.dart';

class DoctorScheduleService {
  final ApiClient _apiClient;

  DoctorScheduleService(this._apiClient);

  Future<List<DoctorSchedule>> getSchedulesForDoctor(
    String doctorId,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.doctorsSchedules}/doctor/$doctorId',
      );

      final List<dynamic> data =
          response.data as List<dynamic>;

      return data
          .map(
            (item) => DoctorSchedule.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
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
    }

    if (error.response?.statusCode == 401) {
      return 'Your session has expired. Please sign in again.';
    }

    return 'Unable to load doctor availability.';
  }
}