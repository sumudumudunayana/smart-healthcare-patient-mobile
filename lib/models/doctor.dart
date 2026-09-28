class Doctor {
  final String doctorId;
  final String userId;
  final String fullName;
  final String email;
  final String? phone;
  final String specialization;
  final String? department;
  final String licenseNumber;
  final int experience;
  final String status;

  Doctor({
    required this.doctorId,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.specialization,
    required this.department,
    required this.licenseNumber,
    required this.experience,
    required this.status,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      doctorId: json['doctorId'].toString(),
      userId: json['userId'].toString(),
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      specialization:
          json['specialization']?.toString() ?? '',
      department: json['department']?.toString(),
      licenseNumber:
          json['licenseNumber']?.toString() ?? '',
      experience:
          int.tryParse(
                json['experience'].toString(),
              ) ??
              0,
      status: json['status']?.toString() ?? '',
    );
  }
}