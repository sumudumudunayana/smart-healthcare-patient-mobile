import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../models/appointment.dart';
import '../../services/appointment_service.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late final SecureStorageService _secureStorage;
  late final AppointmentService _appointmentService;

  late final TabController _tabController;

  List<Appointment> _appointments = [];

  bool _isLoading = true;
  String? _errorMessage;
  String? _cancellingAppointmentId;

  @override
  void initState() {
    super.initState();

    _secureStorage = SecureStorageService();

    final apiClient = ApiClient(_secureStorage);

    _appointmentService = AppointmentService(apiClient);

    _tabController = TabController(length: 3, vsync: this);

    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appointments = await _appointmentService.getMyAppointments();

      if (!mounted) return;

      setState(() {
        _appointments = appointments;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    final confirmed = await _showCancelConfirmation(appointment);

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _cancellingAppointmentId = appointment.appointmentId;
    });

    try {
      await _appointmentService.cancelAppointment(appointment.appointmentId);

      if (!mounted) return;

      await _loadAppointments();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment cancelled successfully.'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _cancellingAppointmentId = null;
        });
      }
    }
  }

  Future<bool> _showCancelConfirmation(Appointment appointment) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Cancel Appointment',
            style: TextStyle(
              color: Color(0xFF064E3B),
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to cancel your appointment with '
            '${appointment.doctorName} on '
            '${_formatDate(appointment.appointmentDate)} '
            'at ${_formatTime(appointment.appointmentTime)}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Keep Appointment',
                style: TextStyle(color: Color(0xFF475569)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel Appointment'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  List<Appointment> _getUpcomingAppointments() {
    final now = DateTime.now();

    final appointments = _appointments.where((appointment) {
      final appointmentDateTime = _buildAppointmentDateTime(appointment);

      final status = appointment.status.toLowerCase();

      return appointmentDateTime.isAfter(now) &&
          status != 'cancelled' &&
          status != 'completed';
    }).toList();

    appointments.sort(
      (a, b) =>
          _buildAppointmentDateTime(a).compareTo(_buildAppointmentDateTime(b)),
    );

    return appointments;
  }

  List<Appointment> _getPastAppointments() {
    final now = DateTime.now();

    final appointments = _appointments.where((appointment) {
      final appointmentDateTime = _buildAppointmentDateTime(appointment);

      final status = appointment.status.toLowerCase();

      return appointmentDateTime.isBefore(now) && status != 'cancelled';
    }).toList();

    appointments.sort(
      (a, b) =>
          _buildAppointmentDateTime(b).compareTo(_buildAppointmentDateTime(a)),
    );

    return appointments;
  }

  List<Appointment> _getCancelledAppointments() {
    final appointments = _appointments
        .where((appointment) => appointment.status.toLowerCase() == 'cancelled')
        .toList();

    appointments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return appointments;
  }

  DateTime _buildAppointmentDateTime(Appointment appointment) {
    final time = _parseAppointmentTime(appointment.appointmentTime);

    if (time == null) {
      return DateTime(
        appointment.appointmentDate.year,
        appointment.appointmentDate.month,
        appointment.appointmentDate.day,
      );
    }

    return DateTime(
      appointment.appointmentDate.year,
      appointment.appointmentDate.month,
      appointment.appointmentDate.day,
      time.hour,
      time.minute,
    );
  }

  TimeOfDay? _parseAppointmentTime(String value) {
    try {
      final parts = value.split(':');

      if (parts.length < 2) {
        return null;
      }

      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} '
        '${date.day}, ${date.year}';
  }

  String _formatTime(String value) {
    final parsed = _parseAppointmentTime(value);

    if (parsed == null) {
      return value;
    }

    final hour = parsed.hour;
    final minute = parsed.minute;

    final period = hour >= 12 ? 'PM' : 'AM';

    final displayHour = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;

    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return const Color(0xFF059669);

      case 'completed':
        return const Color(0xFF2563EB);

      case 'cancelled':
        return const Color(0xFFDC2626);

      case 'noshow':
        return const Color(0xFFD97706);

      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Appointments',
          style: TextStyle(
            color: Color(0xFF064E3B),
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadAppointments,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF059669),
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: const Color(0xFF059669),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF059669)),
      );
    }

    if (_errorMessage != null) {
      return RefreshIndicator(
        onRefresh: _loadAppointments,
        color: const Color(0xFF059669),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [const SizedBox(height: 100), _buildErrorState()],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      color: const Color(0xFF059669),
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentList(
            _getUpcomingAppointments(),
            emptyTitle: 'No upcoming appointments',
            emptySubtitle: 'Your upcoming appointments will appear here.',
            emptyIcon: Icons.event_available_rounded,
          ),
          _buildAppointmentList(
            _getPastAppointments(),
            emptyTitle: 'No past appointments',
            emptySubtitle:
                'Completed and previous appointments will appear here.',
            emptyIcon: Icons.history_rounded,
          ),
          _buildAppointmentList(
            _getCancelledAppointments(),
            emptyTitle: 'No cancelled appointments',
            emptySubtitle: 'Appointments you cancel will appear here.',
            emptyIcon: Icons.event_busy_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentList(
    List<Appointment> appointments, {
    required String emptyTitle,
    required String emptySubtitle,
    required IconData emptyIcon,
  }) {
    if (appointments.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 90),
          _buildEmptyState(
            title: emptyTitle,
            subtitle: emptySubtitle,
            icon: emptyIcon,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: appointments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildAppointmentCard(appointments[index]);
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final statusColor = _statusColor(appointment.status);

    final isUpcoming = _getUpcomingAppointments().any(
      (item) => item.appointmentId == appointment.appointmentId,
    );

    final isCancelling = _cancellingAppointmentId == appointment.appointmentId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDEBE4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF064E3B).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF059669),
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Doctor',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      appointment.doctorName,
                      style: const TextStyle(
                        color: Color(0xFF064E3B),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(appointment.status, statusColor),
            ],
          ),

          const SizedBox(height: 16),

          const Divider(height: 1, color: Color(0xFFEDF2EF)),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  Icons.calendar_today_rounded,
                  _formatDate(appointment.appointmentDate),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDetailItem(
                  Icons.access_time_rounded,
                  _formatTime(appointment.appointmentTime),
                ),
              ),
            ],
          ),

          if (appointment.symptoms != null &&
              appointment.symptoms!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildSymptomsSection(appointment.symptoms!),
          ],

          if (isUpcoming) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                onPressed: isCancelling
                    ? null
                    : () => _cancelAppointment(appointment),
                icon: isCancelling
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFDC2626),
                        ),
                      )
                    : const Icon(Icons.event_busy_rounded, size: 17),
                label: Text(
                  isCancelling ? 'Cancelling...' : 'Cancel Appointment',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF059669)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSymptomsSection(String symptoms) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Symptoms',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            symptoms,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EEE8)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF94A3B8), size: 38),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 38,
          ),
          const SizedBox(height: 12),
          const Text(
            'Unable to load appointments',
            style: TextStyle(
              color: Color(0xFF991B1B),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB91C1C),
              fontSize: 10,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _loadAppointments,
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Try Again'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF059669),
              side: const BorderSide(color: Color(0xFF059669)),
            ),
          ),
        ],
      ),
    );
  }
}
