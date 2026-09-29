import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/doctor.dart';

class DoctorService {
  final ApiClient _apiClient;

  DoctorService(this._apiClient);

  Future<List<Doctor>> getDoctors({
    String? search,
    String? specializationId,
    String? departmentId,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};

      if (search != null && search.trim().isNotEmpty) {
        queryParameters['search'] = search.trim();
      }

      if (specializationId != null &&
          specializationId.isNotEmpty) {
        queryParameters['specializationId'] =
            specializationId;
      }

      if (departmentId != null &&
          departmentId.isNotEmpty) {
        queryParameters['departmentId'] =
            departmentId;
      }

      final response = await _apiClient.dio.get(
        ApiConstants.doctors,
        queryParameters: queryParameters,
      );

      final List<dynamic> data =
          response.data as List<dynamic>;

      return data
          .map(
            (item) => Doctor.fromJson(
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

  Future<Doctor?> getDoctorById(
    String doctorId,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.doctors}/$doctorId',
      );

      if (response.data == null) {
        return null;
      }

      return Doctor.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }

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

    return 'Unable to load doctors.';
  }
}