class Prescription {
  final String prescriptionId;
  final String recordId;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String medicine;
  final String dosage;
  final String duration;
  final String? frequency;
  final String? instructions;
  final DateTime createdAt;

  Prescription({
    required this.prescriptionId,
    required this.recordId,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.medicine,
    required this.dosage,
    required this.duration,
    this.frequency,
    this.instructions,
    required this.createdAt,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      prescriptionId:
          json['prescriptionId']?.toString() ?? '',
      recordId:
          json['recordId']?.toString() ?? '',
      patientId:
          json['patientId']?.toString() ?? '',
      patientName:
          json['patientName']?.toString() ?? '',
      doctorId:
          json['doctorId']?.toString() ?? '',
      doctorName:
          json['doctorName']?.toString() ?? '',
      medicine:
          json['medicine']?.toString() ?? '',
      dosage:
          json['dosage']?.toString() ?? '',
      duration:
          json['duration']?.toString() ?? '',
      frequency:
          json['frequency']?.toString(),
      instructions:
          json['instructions']?.toString(),
      createdAt:
          DateTime.parse(json['createdAt'].toString()),
    );
  }
}