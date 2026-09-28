class AuthResponse {
  final String token;
  final String refreshToken;
  final String userId;
  final String fullName;
  final String email;
  final String role;

  AuthResponse({
    required this.token,
    required this.refreshToken,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String,
      userId: json['userId'].toString(),
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
    );
  }
}