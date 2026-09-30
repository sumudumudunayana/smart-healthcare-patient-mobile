class AIAppointmentSlot {
  final String doctorId;
  final String doctorName;
  final String scheduleId;
  final String appointmentDate;
  final String appointmentTime;
  final String specialization;
  final String? department;

  const AIAppointmentSlot({
    required this.doctorId,
    required this.doctorName,
    required this.scheduleId,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.specialization,
    this.department,
  });

  factory AIAppointmentSlot.fromJson(
    Map<String, dynamic> json,
  ) {
    return AIAppointmentSlot(
      doctorId:
          json['DoctorId']?.toString() ??
          json['doctorId']?.toString() ??
          '',
      doctorName:
          json['DoctorName']?.toString() ??
          json['doctorName']?.toString() ??
          '',
      scheduleId:
          json['ScheduleId']?.toString() ??
          json['scheduleId']?.toString() ??
          '',
      appointmentDate:
          json['AppointmentDate']?.toString() ??
          json['appointmentDate']?.toString() ??
          '',
      appointmentTime:
          json['AppointmentTime']?.toString() ??
          json['appointmentTime']?.toString() ??
          '',
      specialization:
          json['Specialization']?.toString() ??
          json['specialization']?.toString() ??
          '',
      department:
          json['Department']?.toString() ??
          json['department']?.toString(),
    );
  }
}

class AIAppointmentRequest {
  final String specialization;
  final String preferredDate;
  final String preferredTimePeriod;
  final String additionalPreferences;

  const AIAppointmentRequest({
    required this.specialization,
    required this.preferredDate,
    required this.preferredTimePeriod,
    required this.additionalPreferences,
  });

  factory AIAppointmentRequest.fromJson(
    Map<String, dynamic> json,
  ) {
    return AIAppointmentRequest(
      specialization:
          json['Specialization']?.toString() ??
          json['specialization']?.toString() ??
          '',
      preferredDate:
          json['PreferredDate']?.toString() ??
          json['preferredDate']?.toString() ??
          '',
      preferredTimePeriod:
          json['PreferredTimePeriod']?.toString() ??
          json['preferredTimePeriod']?.toString() ??
          '',
      additionalPreferences:
          json['AdditionalPreferences']?.toString() ??
          json['additionalPreferences']?.toString() ??
          '',
    );
  }
}

class AIAppointmentResult {
  final AIAppointmentRequest request;
  final List<AIAppointmentSlot> availableSlots;

  const AIAppointmentResult({
    required this.request,
    required this.availableSlots,
  });

  factory AIAppointmentResult.fromJson(
    Map<String, dynamic> json,
  ) {
    final dynamic requestData =
        json['Request'] ?? json['request'];

    final dynamic slotsData =
        json['AvailableSlots'] ?? json['availableSlots'];

    return AIAppointmentResult(
      request: AIAppointmentRequest.fromJson(
        requestData is Map
            ? Map<String, dynamic>.from(requestData)
            : <String, dynamic>{},
      ),
      availableSlots: slotsData is List
          ? slotsData
              .whereType<Map>()
              .map(
                (item) => AIAppointmentSlot.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : [],
    );
  }
}