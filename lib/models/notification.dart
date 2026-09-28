class PatientNotification {
  final String notificationId;
  final String userId;
  final String message;
  final String notificationType;
  final String status;
  final DateTime createdAt;
  final DateTime? readAt;

  PatientNotification({
    required this.notificationId,
    required this.userId,
    required this.message,
    required this.notificationType,
    required this.status,
    required this.createdAt,
    this.readAt,
  });

  bool get isRead => status.toLowerCase() == 'read';

  factory PatientNotification.fromJson(Map<String, dynamic> json) {
    return PatientNotification(
      notificationId: json['notificationId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      notificationType:
          json['notificationType']?.toString() ?? 'General',
      status: json['status']?.toString() ?? 'Unread',
      createdAt: DateTime.parse(
        json['createdAt'].toString(),
      ).toLocal(),
      readAt: json['readAt'] != null
          ? DateTime.parse(
              json['readAt'].toString(),
            ).toLocal()
          : null,
    );
  }
}