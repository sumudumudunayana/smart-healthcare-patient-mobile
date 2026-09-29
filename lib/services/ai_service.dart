import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/ai_agent_response.dart';
import '../models/ai_appointment_result.dart';
import '../models/ai_triage_result.dart';

class AIService {
  final ApiClient _apiClient;

  AIService(this._apiClient);

  Future<AIAgentResponse> process({
    required String request,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/ai/process',
        data: {
          'request': request,
        },
      );

      return AIAgentResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw Exception(
        _extractErrorMessage(error),
      );
    }
  }

  AIAppointmentResult parseAppointmentResult(
    AIAgentResponse response,
  ) {
    if (response.output == null ||
        response.output!.isEmpty) {
      return const AIAppointmentResult(
        request: AIAppointmentRequest(
          specialization: '',
          preferredDate: '',
          preferredTimePeriod: '',
          additionalPreferences: '',
        ),
        availableSlots: [],
      );
    }

    try {
      final dynamic decoded =
          jsonDecode(response.output!);

      if (decoded is! Map) {
        throw const FormatException(
          'Invalid appointment response format.',
        );
      }

      return AIAppointmentResult.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      throw Exception(
        'The appointment scheduling response could not be read.',
      );
    }
  }

  AITriageResult parseTriageResult(
    AIAgentResponse response,
  ) {
    if (response.output == null ||
        response.output!.isEmpty) {
      throw Exception(
        'No triage result was returned by the AI service.',
      );
    }

    try {
      final dynamic decoded =
          jsonDecode(response.output!);

      if (decoded is! Map) {
        throw const FormatException(
          'Invalid triage response format.',
        );
      }

      return AITriageResult.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      throw Exception(
        'The triage response could not be read.',
      );
    }
  }

  String _extractErrorMessage(
    DioException error,
  ) {
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

      if (responseData['errors']
          is Map<String, dynamic>) {
        final errors =
            responseData['errors']
                as Map<String, dynamic>;

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
        return 'Please provide a valid AI request.';

      case 401:
        return 'Your session has expired. Please log in again.';

      case 403:
        return 'You are not allowed to use the AI assistant.';

      case 404:
        return 'The AI service was not found.';

      case 500:
        return 'The AI service is temporarily unavailable.';

      default:
        return error.message ??
            'Something went wrong while processing your AI request.';
    }
  }
}