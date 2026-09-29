import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../models/notification.dart';
import '../../services/notification_service.dart';

class PatientNotificationsScreen extends StatefulWidget {
  const PatientNotificationsScreen({super.key});

  @override
  State<PatientNotificationsScreen> createState() =>
      _PatientNotificationsScreenState();
}

class _PatientNotificationsScreenState
    extends State<PatientNotificationsScreen> {
  late final NotificationService _notificationService;

  final SecureStorageService _secureStorage =
      SecureStorageService();

  List<PatientNotification> _notifications = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    final apiClient = ApiClient(_secureStorage);
    _notificationService = NotificationService(apiClient);

    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notifications =
          await _notificationService.getMyNotifications();

      if (!mounted) return;

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _handleNotificationTap(
    PatientNotification notification,
  ) async {
    if (notification.isRead) {
      return;
    }

    try {
      final updatedNotification =
          await _notificationService.markAsRead(
        notification.notificationId,
      );

      if (!mounted) return;

      setState(() {
        final index = _notifications.indexWhere(
          (item) =>
              item.notificationId ==
              updatedNotification.notificationId,
        );

        if (index != -1) {
          _notifications[index] = updatedNotification;
        }
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  int get _unreadCount {
    return _notifications
        .where((notification) => !notification.isRead)
        .length;
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'appointment':
        return Icons.calendar_month_rounded;

      case 'reminder':
        return Icons.notifications_active_rounded;

      case 'medical':
      case 'medicalrecord':
      case 'medical_record':
        return Icons.medical_services_rounded;

      case 'prescription':
        return Icons.medication_rounded;

      case 'lab':
      case 'labreport':
      case 'lab_report':
        return Icons.science_rounded;

      case 'billing':
      case 'payment':
        return Icons.receipt_long_rounded;

      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationIconBackground(String type) {
    switch (type.toLowerCase()) {
      case 'appointment':
        return const Color(0xFFDBEAFE);

      case 'reminder':
        return const Color(0xFFFEF3C7);

      case 'medical':
      case 'medicalrecord':
      case 'medical_record':
        return const Color(0xFFD1FAE5);

      case 'prescription':
        return const Color(0xFFEDE9FE);

      case 'lab':
      case 'labreport':
      case 'lab_report':
        return const Color(0xFFCFFAFE);

      case 'billing':
      case 'payment':
        return const Color(0xFFFCE7F3);

      default:
        return const Color(0xFFE2E8F0);
    }
  }

  Color _getNotificationIconColor(String type) {
    switch (type.toLowerCase()) {
      case 'appointment':
        return const Color(0xFF2563EB);

      case 'reminder':
        return const Color(0xFFD97706);

      case 'medical':
      case 'medicalrecord':
      case 'medical_record':
        return const Color(0xFF059669);

      case 'prescription':
        return const Color(0xFF7C3AED);

      case 'lab':
      case 'labreport':
      case 'lab_report':
        return const Color(0xFF0891B2);

      case 'billing':
      case 'payment':
        return const Color(0xFFDB2777);

      default:
        return const Color(0xFF64748B);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;

    return '$day/$month/$year';
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        18,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(
                color: Color(0xFF064E3B),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (_unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_unreadCount unread',
                style: const TextStyle(
                  color: Color(0xFF047857),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    PatientNotification notification,
  ) {
    final isUnread = !notification.isRead;

    final iconBackground =
        _getNotificationIconBackground(
      notification.notificationType,
    );

    final iconColor =
        _getNotificationIconColor(
      notification.notificationType,
    );

    return InkWell(
      onTap: () => _handleNotificationTap(notification),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread
              ? const Color(0xFFF0FDF4)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isUnread
                ? const Color(0xFFBBF7D0)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _getNotificationIcon(
                  notification.notificationType,
                ),
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.notificationType,
                          style: TextStyle(
                            color: isUnread
                                ? const Color(0xFF064E3B)
                                : const Color(0xFF475569),
                            fontSize: 14,
                            fontWeight: isUnread
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: Color(0xFF059669),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDateTime(
                      notification.createdAt,
                    ),
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: const Color(0xFF059669),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 150),
          Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 18),
          Center(
            child: Text(
              'No notifications yet',
              style: TextStyle(
                color: Color(0xFF334155),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: 8),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 35,
              ),
              child: Text(
                'Your healthcare notifications will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: const Color(0xFF059669),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationCard(
            _notifications[index],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF7),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF059669),
                      ),
                    )
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _notifications.isEmpty
                          ? _buildEmptyState()
                          : _buildNotificationList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: const Color(0xFF059669),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 130),
          const Icon(
            Icons.cloud_off_rounded,
            size: 60,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'Unable to load notifications',
              style: TextStyle(
                color: Color(0xFF334155),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 30,
            ),
            child: Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: _loadNotifications,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}