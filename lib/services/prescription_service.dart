import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/prescription.dart';

class PrescriptionService {
  final ApiClient _apiClient;

  PrescriptionService(this._apiClient);

  Future<List<Prescription>> getMyPrescriptions() async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.prescriptions}/my',
      );

      final List<dynamic> data =
          response.data as List<dynamic>;

      return data
          .map(
            (item) => Prescription.fromJson(
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
      case 401:
        return 'Your session has expired. Please log in again.';

      case 403:
        return 'You are not allowed to view these prescriptions.';

      case 404:
        return 'Prescriptions were not found.';

      case 409:
        return 'Unable to retrieve prescriptions.';

      default:
        return error.message ??
            'Something went wrong while loading prescriptions.';
    }
  }
}