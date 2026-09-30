import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../models/ai_appointment_result.dart';
import '../../models/ai_triage_result.dart';
import '../../models/create_appointment_request.dart';
import '../../services/ai_service.dart';
import '../../services/appointment_service.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  late final SecureStorageService _secureStorageService;
  late final ApiClient _apiClient;
  late final AIService _aiService;
  late final AppointmentService _appointmentService;

  final TextEditingController _appointmentController =
      TextEditingController();

  final TextEditingController _symptomsController = TextEditingController();

  final TextEditingController _durationController = TextEditingController();

  final TextEditingController _additionalInfoController =
      TextEditingController();

  bool _isLoading = false;
  String? _bookingSlotKey;

  String _selectedMode = 'home';

  AIAppointmentResult? _appointmentResult;
  AITriageResult? _triageResult;

  @override
  void initState() {
    super.initState();

    _secureStorageService = SecureStorageService();

    _apiClient = ApiClient(_secureStorageService);

    _aiService = AIService(_apiClient);

    _appointmentService = AppointmentService(_apiClient);
  }

  @override
  void dispose() {
    _appointmentController.dispose();
    _symptomsController.dispose();
    _durationController.dispose();
    _additionalInfoController.dispose();

    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _processAppointmentRequest() async {
    final request = _appointmentController.text.trim();

    if (request.isEmpty) {
      _showMessage('Please describe the appointment you need.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _appointmentResult = null;
    });

    try {
      final response = await _aiService.process(
        request: request,
      );

      if (!response.success) {
        throw Exception(response.message);
      }

      final result = _aiService.parseAppointmentResult(response);

      if (!mounted) {
        return;
      }

      setState(() {
        _appointmentResult = result;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(_cleanErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _processTriageRequest() async {
    final symptoms = _symptomsController.text.trim();

    if (symptoms.isEmpty) {
      _showMessage('Please describe your symptoms.');
      return;
    }

    FocusScope.of(context).unfocus();

    final String request = _buildTriageRequest();

    setState(() {
      _isLoading = true;
      _triageResult = null;
    });

    try {
      final response = await _aiService.process(
        request: request,
      );

      if (!response.success) {
        throw Exception(response.message);
      }

      final result = _aiService.parseTriageResult(response);

      if (!mounted) {
        return;
      }

      setState(() {
        _triageResult = result;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(_cleanErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _buildTriageRequest() {
    final symptoms = _symptomsController.text.trim();

    final duration = _durationController.text.trim();

    final additionalInformation = _additionalInfoController.text.trim();

    final buffer = StringBuffer();

    buffer.writeln('Symptoms: $symptoms');

    if (duration.isNotEmpty) {
      buffer.writeln('Duration: $duration');
    }

    if (additionalInformation.isNotEmpty) {
      buffer.writeln(
        'Additional information: '
        '$additionalInformation',
      );
    }

    return buffer.toString().trim();
  }

  String _cleanErrorMessage(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }

  void _openAppointmentMode() {
    setState(() {
      _selectedMode = 'appointment';
      _triageResult = null;
    });
  }

  void _openTriageMode() {
    setState(() {
      _selectedMode = 'triage';
      _appointmentResult = null;
    });
  }

  void _returnToHome() {
    FocusScope.of(context).unfocus();

    setState(() {
      _selectedMode = 'home';

      _appointmentResult = null;

      _triageResult = null;
    });
  }

  Future<void> _bookAISlot(AIAppointmentSlot slot) async {
    if (_bookingSlotKey != null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Confirm Appointment',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF172B24),
            ),
          ),
          content: Text(
            'Would you like to book an appointment with '
            '${slot.doctorName} on '
            '${_formatAppointmentDate(slot.appointmentDate)} at '
            '${_formatAppointmentTime(slot.appointmentTime)}?',
            style: const TextStyle(
              color: Color(0xFF475569),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final slotKey =
        '${slot.doctorId}_${slot.scheduleId}_'
        '${slot.appointmentDate}_${slot.appointmentTime}';

    setState(() {
      _bookingSlotKey = slotKey;
    });

    try {
      final request = CreateAppointmentRequest(
        doctorId: slot.doctorId,
        scheduleId: slot.scheduleId,
        appointmentDate: slot.appointmentDate,
        appointmentTime: slot.appointmentTime,
        symptoms: _appointmentController.text.trim(),
      );

      await _appointmentService.createAppointment(request);

      if (!mounted) {
        return;
      }

      setState(() {
        _bookingSlotKey = null;
      });

      _showMessage(
        'Appointment booked successfully with ${slot.doctorName}.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _bookingSlotKey = null;
      });

      _showMessage(_cleanErrorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: _selectedMode == 'home'
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _returnToHome,
              ),
        title: const Text(
          'AI Assistant',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _buildCurrentView(),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_selectedMode) {
      case 'appointment':
        return _buildAppointmentView();

      case 'triage':
        return _buildTriageView();

      default:
        return _buildHomeView();
    }
  }

  Widget _buildHomeView() {
    return SingleChildScrollView(
      key: const ValueKey('ai-home'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF059669),
                  Color(0xFF047857),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 36,
                ),
                SizedBox(height: 16),
                Text(
                  'Smart Healthcare AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Use natural language to find '
                  'appointments or describe your '
                  'symptoms for a preliminary '
                  'triage recommendation.',
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.5,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'How can I help you?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF172B24),
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            icon: Icons.calendar_month_rounded,
            title: 'Appointment Scheduling',
            description:
                'Tell me which specialist you '
                'want to see and when you prefer '
                'to visit.',
            onTap: _openAppointmentMode,
          ),
          const SizedBox(height: 14),
          _buildFeatureCard(
            icon: Icons.health_and_safety_rounded,
            title: 'Symptom Triage',
            description:
                'Describe your symptoms and '
                'receive a preliminary urgency '
                'and specialization recommendation.',
            onTap: _openTriageMode,
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFDE68A),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFD97706),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI responses are preliminary '
                    'recommendations and do not replace '
                    'professional medical advice.',
                    style: TextStyle(
                      color: Color(0xFF92400E),
                      height: 1.45,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE2E8E5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF059669),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF172B24),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentView() {
    return SingleChildScrollView(
      key: const ValueKey('ai-appointment'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find an appointment',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF172B24),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Describe the appointment you need '
            'in your own words.',
            style: TextStyle(
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _appointmentController,
            label: 'Appointment request',
            hint:
                'Example: I want to see a cardiologist next Monday afternoon.',
            maxLines: 5,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed:
                  _isLoading || _bookingSlotKey != null
                      ? null
                      : _processAppointmentRequest,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search_rounded),
              label: Text(
                _isLoading
                    ? 'Finding available slots...'
                    : 'Find Available Slots',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          if (_appointmentResult != null) ...[
            const SizedBox(height: 28),
            _buildAppointmentResults(_appointmentResult!),
          ],
        ],
      ),
    );
  }

  Widget _buildAppointmentResults(AIAppointmentResult result) {
    if (result.availableSlots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE2E8E5),
          ),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 42,
              color: Color(0xFF64748B),
            ),
            SizedBox(height: 12),
            Text(
              'No available slots found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Try changing your preferred date, '
              'time, or specialization.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available appointment slots',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF172B24),
          ),
        ),
        const SizedBox(height: 12),
        ...result.availableSlots.map(
          _buildAppointmentSlot,
        ),
      ],
    );
  }

  Widget _buildAppointmentSlot(AIAppointmentSlot slot) {
    final slotKey =
        '${slot.doctorId}_${slot.scheduleId}_'
        '${slot.appointmentDate}_${slot.appointmentTime}';

    final bool isBooking = _bookingSlotKey == slotKey;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFDDE8E3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF059669),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  slot.doctorName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF172B24),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.medical_services_outlined,
            slot.specialization,
          ),
          if (slot.department != null &&
              slot.department!.trim().isNotEmpty)
            _buildInfoRow(
              Icons.local_hospital_outlined,
              slot.department!,
            ),
          _buildInfoRow(
            Icons.calendar_today_outlined,
            _formatAppointmentDate(slot.appointmentDate),
          ),
          _buildInfoRow(
            Icons.access_time_rounded,
            _formatAppointmentTime(slot.appointmentTime),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed:
                  _bookingSlotKey != null
                      ? null
                      : () => _bookAISlot(slot),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF059669),
                side: const BorderSide(
                  color: Color(0xFF059669),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isBooking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF059669),
                      ),
                    )
                  : const Text(
                      'Select This Slot',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF64748B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriageView() {
    return SingleChildScrollView(
      key: const ValueKey('ai-triage'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Symptom Triage',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF172B24),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Describe what you are experiencing. '
            'The AI will provide a preliminary '
            'triage recommendation.',
            style: TextStyle(
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _symptomsController,
            label: 'Symptoms',
            hint: 'Describe your symptoms...',
            maxLines: 6,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _durationController,
            label: 'Duration',
            hint: 'Example: Since this morning',
            maxLines: 2,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _additionalInfoController,
            label: 'Additional information',
            hint: 'Anything else you think is relevant...',
            maxLines: 4,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed:
                  _isLoading || _bookingSlotKey != null
                      ? null
                      : _processTriageRequest,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.health_and_safety_rounded,
                    ),
              label: Text(
                _isLoading
                    ? 'Analyzing symptoms...'
                    : 'Analyze Symptoms',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          if (_triageResult != null) ...[
            const SizedBox(height: 28),
            _buildTriageResult(_triageResult!),
          ],
        ],
      ),
    );
  }

  Widget _buildTriageResult(AITriageResult result) {
    final bool emergency = result.emergencyIndicator;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Triage Recommendation',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF172B24),
          ),
        ),
        const SizedBox(height: 14),
        if (emergency)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFCA5A5),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'The AI has identified an '
                    'emergency indicator. This '
                    'recommendation requires '
                    'healthcare professional review.',
                    style: TextStyle(
                      color: Color(0xFF991B1B),
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE2E8E5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTriageInfo(
                'Urgency Level',
                result.urgencyLevel,
                Icons.priority_high_rounded,
              ),
              const Divider(height: 28),
              _buildTriageInfo(
                'Recommended Specialization',
                result.recommendedSpecialization,
                Icons.medical_services_outlined,
              ),
              const Divider(height: 28),
              const Text(
                'Reasoning',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.reasoning,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFDE68A),
            ),
          ),
          child: const Text(
            'This is a preliminary AI recommendation '
            'and is not a medical diagnosis or treatment '
            'plan. Please consult a qualified healthcare '
            'professional for medical advice.',
            style: TextStyle(
              color: Color(0xFF92400E),
              height: 1.5,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTriageInfo(
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 21,
            color: const Color(0xFF059669),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF172B24),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required int maxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8E5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8E5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF059669),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatAppointmentDate(String value) {
    try {
      final date = DateTime.parse(value);

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return value;
    }
  }

  String _formatAppointmentTime(String value) {
    if (value.length >= 5) {
      return value.substring(0, 5);
    }

    return value;
  }
}