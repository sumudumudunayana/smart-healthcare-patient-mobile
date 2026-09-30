class UserProfile {
  final String userId;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final String status;

  UserProfile({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}