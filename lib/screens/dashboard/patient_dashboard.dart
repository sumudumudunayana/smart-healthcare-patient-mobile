import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../models/appointment.dart';
import '../../services/appointment_service.dart';
import '../doctors/doctor_search_screen.dart';
import '../appointments/appointments_screen.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../../routes/app_route_observer.dart';
import '../medical_records/medical_records_screen.dart';
import '../prescriptions/prescriptions_screen.dart';
import '../lab_reports/lab_reports_screen.dart';
import '../ai/ai_assistant_screen.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> with RouteAware {
  late final SecureStorageService _secureStorage;
  late final AppointmentService _appointmentService;
  late final AuthService _authService;

  String _patientName = 'Patient';
  List<Appointment> _appointments = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _secureStorage = SecureStorageService();

    final apiClient = ApiClient(_secureStorage);

    _appointmentService = AppointmentService(apiClient);

    _authService = AuthService(apiClient, _secureStorage);

    _loadDashboard();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route = ModalRoute.of(context);

    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    _loadDashboard();
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final name = await _secureStorage.getUserName();

      final appointments = await _appointmentService.getMyAppointments();

      if (!mounted) return;

      setState(() {
        _patientName = name?.trim().isNotEmpty == true
            ? name!.trim()
            : 'Patient';

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

  Future<void> _logout() async {
    try {
      await _authService.logout();

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to sign out. Please try again.')),
      );
    }
  }

  Appointment? _getNextAppointment() {
    final now = DateTime.now();

    final upcoming = _appointments.where((appointment) {
      final date = appointment.appointmentDate;
      final appointmentTime = _parseAppointmentTime(
        appointment.appointmentTime,
      );

      if (appointmentTime == null) {
        return false;
      }

      final appointmentDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        appointmentTime.hour,
        appointmentTime.minute,
      );

      final status = appointment.status.toLowerCase();

      return appointmentDateTime.isAfter(now) &&
          status != 'cancelled' &&
          status != 'completed';
    }).toList();

    if (upcoming.isEmpty) {
      return null;
    }

    upcoming.sort((a, b) {
      final aTime = _buildAppointmentDateTime(a);
      final bTime = _buildAppointmentDateTime(b);

      return aTime.compareTo(bTime);
    });

    return upcoming.first;
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

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        color: const Color(0xFF059669),
        child: _buildBody(),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              gradient: const LinearGradient(
                colors: [Color(0xFF047857), Color(0xFF10B981)],
              ),
            ),
            child: const Center(
              child: Text(
                '+',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SmartHealthcare',
                style: TextStyle(
                  color: Color(0xFF064E3B),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Patient Portal',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 9),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _loadDashboard,
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
        ),
        IconButton(
          onPressed: _logout,
          icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF059669)),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 22),
          if (_errorMessage != null) ...[
            _buildErrorBox(),
            const SizedBox(height: 20),
          ],
          _buildSummaryCards(),
          const SizedBox(height: 25),
          _buildNextAppointmentSection(),
          const SizedBox(height: 25),
          _buildQuickActions(),
          const SizedBox(height: 25),
          _buildRecentAppointments(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF064E3B).withValues(alpha: 0.14),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PATIENT PORTAL',
                  style: TextStyle(
                    color: Color(0xFFA7F3D0),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hello, $_patientName 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Manage your healthcare journey '
                  'from one place.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.health_and_safety_rounded,
                color: Color(0xFFA7F3D0),
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final scheduledCount = _appointments
        .where((appointment) => appointment.status.toLowerCase() == 'scheduled')
        .length;

    final completedCount = _appointments
        .where((appointment) => appointment.status.toLowerCase() == 'completed')
        .length;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.calendar_month_rounded,
            title: 'Appointments',
            value: '${_appointments.length}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.event_available_rounded,
            title: 'Scheduled',
            value: '$scheduledCount',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.check_circle_outline_rounded,
            title: 'Completed',
            value: '$completedCount',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2EEE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: const Color(0xFF059669), size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF064E3B),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildNextAppointmentSection() {
    final appointment = _getNextAppointment();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Next Appointment',
          style: TextStyle(
            color: Color(0xFF064E3B),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 11),
        if (appointment == null)
          _buildEmptyAppointment()
        else
          _buildAppointmentCard(appointment),
      ],
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final statusColor = _statusColor(appointment.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFDDEBE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF059669),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(appointment.status, statusColor),
            ],
          ),
          const SizedBox(height: 17),
          const Divider(height: 1, color: Color(0xFFEDF2EF)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildAppointmentDetail(
                  Icons.calendar_today_rounded,
                  _formatDate(appointment.appointmentDate),
                ),
              ),
              Expanded(
                child: _buildAppointmentDetail(
                  Icons.access_time_rounded,
                  appointment.appointmentTime,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentDetail(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF059669)),
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

  Widget _buildEmptyAppointment() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE2EEE8)),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_busy_rounded, color: Color(0xFF94A3B8), size: 34),
          SizedBox(height: 10),
          Text(
            'No upcoming appointments',
            style: TextStyle(
              color: Color(0xFF475569),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Your upcoming appointments will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Quick Actions',
        style: TextStyle(
          color: Color(0xFF064E3B),
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 11),

      // Row 1
      Row(
        children: [
          Expanded(
            child: _buildActionCard(
              icon: Icons.auto_awesome_rounded,
              title: 'AI Assistant',
              subtitle: 'Get healthcare assistance',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AIAssistantScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionCard(
              icon: Icons.search_rounded,
              title: 'Find a Doctor',
              subtitle: 'Browse doctors',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DoctorSearchScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      const SizedBox(height: 12),

      // Row 2
      Row(
        children: [
          Expanded(
            child: _buildActionCard(
              icon: Icons.calendar_month_rounded,
              title: 'Appointments',
              subtitle: 'View your visits',
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AppointmentsScreen(),
                  ),
                );

                if (!mounted) return;

                await _loadDashboard();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionCard(
              icon: Icons.medical_information_outlined,
              title: 'Medical Records',
              subtitle: 'View your records',
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MedicalRecordsScreen(),
                  ),
                );

                if (!mounted) return;

                await _loadDashboard();
              },
            ),
          ),
        ],
      ),

      const SizedBox(height: 12),

      // Row 3
      Row(
        children: [
          Expanded(
            child: _buildActionCard(
              icon: Icons.medication_outlined,
              title: 'Prescriptions',
              subtitle: 'View prescriptions',
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PrescriptionsScreen(),
                  ),
                );

                if (!mounted) return;

                await _loadDashboard();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionCard(
              icon: Icons.science_outlined,
              title: 'Lab Reports',
              subtitle: 'View lab reports',
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LabReportsScreen(),
                  ),
                );

                if (!mounted) return;

                await _loadDashboard();
              },
            ),
          ),
        ],
      ),
    ],
  );
}

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2EEE8)),
        ),
        child: Row(
          children: [
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF059669), size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF064E3B),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 8,
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

  Widget _buildRecentAppointments() {
    final recent = [..._appointments]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final items = recent.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Appointments',
          style: TextStyle(
            color: Color(0xFF064E3B),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 11),
        if (items.isEmpty)
          _buildEmptyRecentAppointments()
        else
          ...items.map(
            (appointment) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildRecentAppointment(appointment),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentAppointment(Appointment appointment) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE2EEE8)),
      ),
      child: Row(
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.medical_services_outlined,
              color: Color(0xFF059669),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.doctorName,
                  style: const TextStyle(
                    color: Color(0xFF064E3B),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatDate(appointment.appointmentDate)} • ${appointment.appointmentTime}',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8),
                ),
              ],
            ),
          ),
          _buildStatusBadge(
            appointment.status,
            _statusColor(appointment.status),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecentAppointments() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE2EEE8)),
      ),
      child: const Center(
        child: Text(
          'No appointment history yet.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
        ),
      ),
    );
  }

  Widget _buildErrorBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
