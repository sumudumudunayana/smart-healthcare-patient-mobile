import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../models/appointment.dart';
import '../../models/create_appointment_request.dart';
import '../../models/doctor.dart';
import '../../models/doctor_schedule.dart';
import '../../services/appointment_service.dart';
import '../../services/doctor_schedule_service.dart';

class DoctorAvailabilityScreen extends StatefulWidget {
  final Doctor doctor;

  const DoctorAvailabilityScreen({super.key, required this.doctor});

  @override
  State<DoctorAvailabilityScreen> createState() =>
      _DoctorAvailabilityScreenState();
}

class _DoctorAvailabilityScreenState extends State<DoctorAvailabilityScreen> {
  late final DoctorScheduleService _scheduleService;
  late final AppointmentService _appointmentService;

  List<DoctorSchedule> _schedules = [];

  DoctorSchedule? _selectedSchedule;
  DateTime? _selectedDate;

  List<Appointment> _bookedAppointments = [];

  bool _isLoading = true;
  bool _isLoadingAppointments = false;
  bool _isBooking = false;

  String? _errorMessage;

  final TextEditingController _symptomsController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final secureStorage = SecureStorageService();
    final apiClient = ApiClient(secureStorage);

    _scheduleService = DoctorScheduleService(apiClient);
    _appointmentService = AppointmentService(apiClient);

    _loadSchedules();
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD DOCTOR SCHEDULES
  // ============================================================

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final schedules = await _scheduleService.getSchedulesForDoctor(
        widget.doctor.doctorId,
      );

      if (!mounted) return;

      setState(() {
        _schedules = schedules;
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

  // ============================================================
  // SELECT SCHEDULE
  // ============================================================

  Future<void> _selectSchedule(DoctorSchedule schedule) async {
    if (schedule.availabilityStatus.toLowerCase() != 'available') {
      return;
    }

    setState(() {
      _selectedSchedule = schedule;
      _selectedDate = null;
      _bookedAppointments = [];
    });

    await _selectDate();
  }

  // ============================================================
  // SELECT DATE
  // ============================================================

  Future<void> _selectDate() async {
    final schedule = _selectedSchedule;

    if (schedule == null) {
      return;
    }

    final now = DateTime.now();

    final firstAvailableDate = DateTime(now.year, now.month, now.day);

    final lastDate = DateTime(now.year + 1, now.month, now.day);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _getInitialDateForSchedule(schedule, firstAvailableDate),
      firstDate: firstAvailableDate,
      lastDate: lastDate,
      selectableDayPredicate: (date) {
        return _isMatchingScheduleDay(date, schedule.dayOfWeek);
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF059669),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF064E3B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = selectedDate;
      _bookedAppointments = [];
    });

    await _loadBookedAppointments(selectedDate);
  }

  DateTime _getInitialDateForSchedule(
    DoctorSchedule schedule,
    DateTime minimumDate,
  ) {
    DateTime date = minimumDate;

    for (int i = 0; i < 7; i++) {
      final candidate = date.add(Duration(days: i));

      if (_isMatchingScheduleDay(candidate, schedule.dayOfWeek)) {
        return candidate;
      }
    }

    return minimumDate;
  }

  bool _isMatchingScheduleDay(DateTime date, String scheduleDay) {
    return date.weekday == _dayNameToWeekday(scheduleDay);
  }

  int _dayNameToWeekday(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return DateTime.monday;
      case 'tuesday':
        return DateTime.tuesday;
      case 'wednesday':
        return DateTime.wednesday;
      case 'thursday':
        return DateTime.thursday;
      case 'friday':
        return DateTime.friday;
      case 'saturday':
        return DateTime.saturday;
      case 'sunday':
        return DateTime.sunday;
      default:
        return -1;
    }
  }

  // ============================================================
  // LOAD BOOKED APPOINTMENTS
  // ============================================================

  Future<void> _loadBookedAppointments(DateTime date) async {
    setState(() {
      _isLoadingAppointments = true;
    });

    try {
      final appointments = await _appointmentService
          .getDoctorAppointmentsByDate(
            doctorId: widget.doctor.doctorId,
            date: date,
          );

      if (!mounted) return;

      setState(() {
        _bookedAppointments = appointments;
      });
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
          _isLoadingAppointments = false;
        });
      }
    }
  }

  // ============================================================
  // GENERATE 30-MINUTE SLOTS
  // ============================================================

  List<TimeOfDay> _generateTimeSlots(DoctorSchedule schedule) {
    final start = _parseTime(schedule.startTime);
    final end = _parseTime(schedule.endTime);

    if (start == null || end == null) {
      return [];
    }

    final slots = <TimeOfDay>[];

    int currentMinutes = start.hour * 60 + start.minute;

    final endMinutes = end.hour * 60 + end.minute;

    while (currentMinutes < endMinutes) {
      final hour = currentMinutes ~/ 60;
      final minute = currentMinutes % 60;

      slots.add(TimeOfDay(hour: hour, minute: minute));

      currentMinutes += 30;
    }

    return slots;
  }

  TimeOfDay? _parseTime(String value) {
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

  // ============================================================
  // CHECK BOOKED SLOT
  // ============================================================

  bool _isSlotBooked(TimeOfDay slot) {
    return _bookedAppointments.any((appointment) {
      final appointmentTime = _parseTime(appointment.appointmentTime);

      if (appointmentTime == null) {
        return false;
      }

      return appointmentTime.hour == slot.hour &&
          appointmentTime.minute == slot.minute &&
          appointment.status.toLowerCase() != 'cancelled';
    });
  }

  // ============================================================
  // CHECK IF SLOT IS IN THE PAST
  // ============================================================

  bool _isSlotInPast(TimeOfDay slot) {
    if (_selectedDate == null) {
      return false;
    }

    final now = DateTime.now();

    final selectedDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      slot.hour,
      slot.minute,
    );

    return selectedDateTime.isBefore(now);
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ============================================================
  // FORMAT TIME
  // ============================================================

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;

    final minute = time.minute.toString().padLeft(2, '0');

    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  // ============================================================
  // SELECT TIME SLOT
  // ============================================================

  Future<void> _selectTimeSlot(TimeOfDay slot) async {
    if (_isSlotBooked(slot)) {
      return;
    }

    if (_isSlotInPast(slot)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This appointment time has already passed.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );

      return;
    }

    await _showBookingDialog(slot);
  }

  // ============================================================
  // BOOKING DIALOG
  // ============================================================

  Future<void> _showBookingDialog(TimeOfDay slot) async {
    _symptomsController.clear();

    await showDialog<void>(
      context: context,
      barrierDismissible: !_isBooking,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Confirm Appointment',
                style: TextStyle(
                  color: Color(0xFF064E3B),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBookingDetail(
                      icon: Icons.person_rounded,
                      label: 'Doctor',
                      value: widget.doctor.fullName,
                    ),
                    const SizedBox(height: 12),
                    _buildBookingDetail(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date',
                      value: _formatDate(_selectedDate!),
                    ),
                    const SizedBox(height: 12),
                    _buildBookingDetail(
                      icon: Icons.access_time_rounded,
                      label: 'Time',
                      value: _formatTime(slot),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Symptoms (Optional)',
                      style: TextStyle(
                        color: Color(0xFF064E3B),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _symptomsController,
                      maxLines: 4,
                      enabled: !_isBooking,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Describe your symptoms...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2EEE8),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2EEE8),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF059669),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              actions: [
                TextButton(
                  onPressed: _isBooking
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isBooking
                      ? null
                      : () async {
                          setDialogState(() {
                            _isBooking = true;
                          });

                          final success = await _createAppointment(slot);

                          if (!mounted) return;

                          if (!success) {
                            setDialogState(() {
                              _isBooking = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF94A3B8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: _isBooking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBookingDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: const Color(0xFF059669), size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF064E3B),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CREATE APPOINTMENT
  // ============================================================

  Future<bool> _createAppointment(TimeOfDay slot) async {
    if (_selectedSchedule == null || _selectedDate == null) {
      return false;
    }

    final appointmentDate =
        '${_selectedDate!.year.toString().padLeft(4, '0')}-'
        '${_selectedDate!.month.toString().padLeft(2, '0')}-'
        '${_selectedDate!.day.toString().padLeft(2, '0')}';

    final appointmentTime =
        '${slot.hour.toString().padLeft(2, '0')}:'
        '${slot.minute.toString().padLeft(2, '0')}:00';

    final request = CreateAppointmentRequest(
      doctorId: widget.doctor.doctorId,
      scheduleId: _selectedSchedule!.scheduleId,
      appointmentDate: appointmentDate,
      appointmentTime: appointmentTime,
      symptoms: _symptomsController.text,
    );

    try {
      final appointment = await _appointmentService.createAppointment(request);

      if (!mounted) {
        return true;
      }

      Navigator.of(context).pop();

      await _showBookingConfirmation(appointment);

      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }

      final message = error.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 4),
        ),
      );

      // Refresh booked slots because another patient
      // may have booked the slot.
      await _loadBookedAppointments(_selectedDate!);

      return false;
    }
  }

  // ============================================================
  // BOOKING CONFIRMATION
  // ============================================================

  Future<void> _showBookingConfirmation(Appointment appointment) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF059669),
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Appointment Confirmed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF064E3B),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              _buildConfirmationRow('Doctor', appointment.doctorName),
              const SizedBox(height: 10),
              _buildConfirmationRow(
                'Date',
                _formatDate(appointment.appointmentDate),
              ),
              const SizedBox(height: 10),
              _buildConfirmationRow(
                'Time',
                _formatAppointmentTime(appointment.appointmentTime),
              ),
              const SizedBox(height: 10),
              _buildConfirmationRow('Status', appointment.status),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF064E3B),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  String _formatAppointmentTime(String value) {
    final time = _parseTime(value);

    if (time == null) {
      return value;
    }

    return _formatTime(time);
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(String status) {
    if (status.toLowerCase() == 'available') {
      return const Color(0xFF059669);
    }

    return const Color(0xFFDC2626);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Doctor Availability',
          style: TextStyle(
            color: Color(0xFF064E3B),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF064E3B)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSchedules,
        color: const Color(0xFF059669),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDoctorHeader(),
              const SizedBox(height: 22),
              _buildTitle(),
              const SizedBox(height: 12),
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DOCTOR HEADER
  // ============================================================

  Widget _buildDoctorHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE2EEE8)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF047857), Color(0xFF10B981)],
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctor.fullName,
                  style: const TextStyle(
                    color: Color(0xFF064E3B),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.doctor.specialization,
                  style: const TextStyle(
                    color: Color(0xFF059669),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TITLE
  // ============================================================

  Widget _buildTitle() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Availability',
          style: TextStyle(
            color: Color(0xFF064E3B),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Select an available schedule to choose an appointment time.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 9),
        ),
      ],
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 50),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF059669)),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorBox();
    }

    if (_schedules.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        ..._schedules.map(
          (schedule) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildScheduleCard(schedule),
          ),
        ),
        if (_selectedSchedule != null) _buildBookingSection(),
      ],
    );
  }

  // ============================================================
  // SCHEDULE CARD
  // ============================================================

  Widget _buildScheduleCard(DoctorSchedule schedule) {
    final isAvailable =
        schedule.availabilityStatus.toLowerCase() == 'available';

    final isSelected = _selectedSchedule?.scheduleId == schedule.scheduleId;

    final statusColor = _statusColor(schedule.availabilityStatus);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2EEE8),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: Color(0xFF059669),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.dayOfWeek,
                      style: const TextStyle(
                        color: Color(0xFF064E3B),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${schedule.startTime} - ${schedule.endTime}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  schedule.availabilityStatus,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (isAvailable) ...[
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton(
                onPressed: () => _selectSchedule(schedule),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF059669),
                  side: const BorderSide(color: Color(0xFF059669)),
                  backgroundColor: isSelected
                      ? const Color(0xFFECFDF5)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: Text(
                  isSelected ? 'Schedule Selected' : 'Select Schedule',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // BOOKING SECTION
  // ============================================================

  Widget _buildBookingSection() {
    final schedule = _selectedSchedule!;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE2EEE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Book an Appointment',
            style: TextStyle(
              color: Color(0xFF064E3B),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${schedule.dayOfWeek} • ${schedule.startTime} - ${schedule.endTime}',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
          ),
          const SizedBox(height: 18),

          // DATE
          const Text(
            'Appointment Date',
            style: TextStyle(
              color: Color(0xFF064E3B),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            height: 45,
            child: OutlinedButton.icon(
              onPressed: _selectDate,
              icon: const Icon(Icons.calendar_month_rounded, size: 18),
              label: Text(
                _selectedDate == null
                    ? 'Select Date'
                    : _formatDate(_selectedDate!),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF059669),
                side: const BorderSide(color: Color(0xFF059669)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),

          if (_selectedDate != null) ...[
            const SizedBox(height: 20),

            const Text(
              'Available Time Slots',
              style: TextStyle(
                color: Color(0xFF064E3B),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),

            const Text(
              'Appointments are 30 minutes long. Booked times cannot be selected.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 9),
            ),

            const SizedBox(height: 12),

            _buildTimeSlots(schedule),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // TIME SLOTS
  // ============================================================

  Widget _buildTimeSlots(DoctorSchedule schedule) {
    if (_isLoadingAppointments) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF059669)),
        ),
      );
    }

    final slots = _generateTimeSlots(schedule);

    if (slots.isEmpty) {
      return const Text(
        'No appointment slots are available.',
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) {
        final isBooked = _isSlotBooked(slot);

        final isPast = _isSlotInPast(slot);

        final isDisabled = isBooked || isPast;

        return SizedBox(
          width: 105,
          height: 42,
          child: OutlinedButton(
            onPressed: isDisabled ? null : () => _selectTimeSlot(slot),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDisabled
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF059669),
              backgroundColor: isBooked
                  ? const Color(0xFFF1F5F9)
                  : isPast
                  ? const Color(0xFFF8FAFC)
                  : Colors.white,
              disabledForegroundColor: const Color(0xFF94A3B8),
              side: BorderSide(
                color: isBooked
                    ? const Color(0xFFCBD5E1)
                    : isPast
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFF059669),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatTime(slot),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDisabled
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF064E3B),
                  ),
                ),
                if (isBooked)
                  const Text(
                    'Booked',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  )
                else if (isPast)
                  const Text(
                    'Passed',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE2EEE8)),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_busy_rounded, color: Color(0xFF94A3B8), size: 42),
          SizedBox(height: 12),
          Text(
            'No schedules available',
            style: TextStyle(
              color: Color(0xFF475569),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'This doctor has no schedules configured yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR BOX
  // ============================================================

  Widget _buildErrorBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
