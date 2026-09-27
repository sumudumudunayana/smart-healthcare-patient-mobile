class Appointment {
  final String appointmentId;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String scheduleId;
  final DateTime appointmentDate;
  final String appointmentTime;
  final String status;
  final String? symptoms;
  final DateTime createdAt;

  Appointment({
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.scheduleId,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.status,
    this.symptoms,
    required this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      appointmentId: json['appointmentId']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      patientName: json['patientName']?.toString() ?? '',
      doctorId: json['doctorId']?.toString() ?? '',
      doctorName: json['doctorName']?.toString() ?? '',
      scheduleId: json['scheduleId']?.toString() ?? '',
      appointmentDate: DateTime.parse(
        json['appointmentDate'].toString(),
      ),
      appointmentTime: json['appointmentTime']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      symptoms: json['symptoms']?.toString(),
      createdAt: DateTime.parse(
        json['createdAt'].toString(),
      ),
    );
  }
}