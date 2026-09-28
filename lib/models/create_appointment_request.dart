class CreateAppointmentRequest {
  final String doctorId;
  final String scheduleId;
  final String appointmentDate;
  final String appointmentTime;
  final String? symptoms;

  CreateAppointmentRequest({
    required this.doctorId,
    required this.scheduleId,
    required this.appointmentDate,
    required this.appointmentTime,
    this.symptoms,
  });

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'scheduleId': scheduleId,
      'appointmentDate': appointmentDate,
      'appointmentTime': appointmentTime,
      'symptoms': symptoms?.trim().isEmpty == true
          ? null
          : symptoms?.trim(),
    };
  }
}