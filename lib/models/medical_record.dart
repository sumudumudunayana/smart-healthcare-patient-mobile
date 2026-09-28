class MedicalRecord {
  final String recordId;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String appointmentId;
  final DateTime appointmentDate;
  final String appointmentTime;
  final String? diagnosis;
  final String? treatment;
  final String? notes;
  final DateTime createdAt;

  MedicalRecord({
    required this.recordId,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.appointmentId,
    required this.appointmentDate,
    required this.appointmentTime,
    this.diagnosis,
    this.treatment,
    this.notes,
    required this.createdAt,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      recordId: json['recordId']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      patientName: json['patientName']?.toString() ?? '',
      doctorId: json['doctorId']?.toString() ?? '',
      doctorName: json['doctorName']?.toString() ?? '',
      appointmentId: json['appointmentId']?.toString() ?? '',
      appointmentDate: DateTime.parse(
        json['appointmentDate'].toString(),
      ),
      appointmentTime:
          json['appointmentTime']?.toString() ?? '',
      diagnosis: json['diagnosis']?.toString(),
      treatment: json['treatment']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: DateTime.parse(
        json['createdAt'].toString(),
      ),
    );
  }
}