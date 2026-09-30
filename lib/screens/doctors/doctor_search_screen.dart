import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../models/doctor.dart';
import '../../services/doctor_service.dart';
import 'doctor_details_screen.dart';

class DoctorSearchScreen extends StatefulWidget {
  const DoctorSearchScreen({super.key});

  @override
  State<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<DoctorSearchScreen> {
  late final DoctorService _doctorService;

  final TextEditingController _searchController = TextEditingController();

  Timer? _searchTimer;

  List<Doctor> _doctors = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    final secureStorage = SecureStorageService();
    final apiClient = ApiClient(secureStorage);

    _doctorService = DoctorService(apiClient);

    _searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _loadDoctors();
  }

  Future<void> _loadDoctors({String? search}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final doctors = await _doctorService.getDoctors(search: search);

      if (!mounted) return;

      setState(() {
        _doctors = doctors;
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

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();

    _searchTimer = Timer(const Duration(milliseconds: 450), () {
      _loadDoctors(search: value);
    });
  }

  Future<void> _refreshDoctors() async {
    await _loadDoctors(search: _searchController.text);
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();

    super.dispose();
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
          'Find a Doctor',
          style: TextStyle(
            color: Color(0xFF064E3B),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF064E3B)),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDoctors,
        color: const Color(0xFF059669),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchHeader(),
              const SizedBox(height: 20),
              _buildSearchField(),
              const SizedBox(height: 20),
              _buildResultsHeader(),
              const SizedBox(height: 12),
              _buildResults(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(17),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FIND THE RIGHT DOCTOR',
            style: TextStyle(
              color: Color(0xFFA7F3D0),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Find a doctor for your healthcare needs.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Search by doctor name, specialization, '
            'or department.',
            style: TextStyle(
              color: Color(0xB3FFFFFF),
              fontSize: 10,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD7E7DF)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search doctor, specialization...',
          hintStyle: const TextStyle(color: Color(0xFFA3B5AD), fontSize: 11),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF059669),
            size: 21,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _loadDoctors();
                    setState(() {});
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Available Doctors',
          style: TextStyle(
            color: Color(0xFF064E3B),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (!_isLoading)
          Text(
            '${_doctors.length} doctors',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 9),
          ),
      ],
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 45),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF059669)),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorBox();
    }

    if (_doctors.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: _doctors
          .map(
            (doctor) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDoctorCard(doctor),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    final isActive = doctor.status.toLowerCase() == 'active';

    return InkWell(
      onTap: isActive
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DoctorDetailsScreen(doctor: doctor),
                ),
              );
            }
          : null,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE2EEE8)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _buildDoctorAvatar(doctor.fullName),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.fullName,
                        style: const TextStyle(
                          color: Color(0xFF064E3B),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctor.specialization,
                        style: const TextStyle(
                          color: Color(0xFF059669),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (doctor.department != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          doctor.department!,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildActiveBadge(doctor.status, isActive),
              ],
            ),
            const SizedBox(height: 15),
            const Divider(height: 1, color: Color(0xFFEDF2EF)),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: _buildDoctorInfo(
                    Icons.work_outline_rounded,
                    '${doctor.experience} years',
                    'Experience',
                  ),
                ),
                Expanded(
                  child: _buildDoctorInfo(
                    Icons.email_outlined,
                    doctor.email,
                    'Email',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorAvatar(String name) {
    String initials = 'DR';

    final parts = name
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      initials = '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      initials = parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }

    return Container(
      width: 49,
      height: 49,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF047857), Color(0xFF10B981)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveBadge(String status, bool isActive) {
    final color = isActive ? const Color(0xFF059669) : const Color(0xFF94A3B8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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

  Widget _buildDoctorInfo(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF059669), size: 15),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 38),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE2EEE8)),
      ),
      child: const Column(
        children: [
          Icon(Icons.person_search_rounded, color: Color(0xFF94A3B8), size: 42),
          SizedBox(height: 12),
          Text(
            'No doctors found',
            style: TextStyle(
              color: Color(0xFF475569),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Try a different doctor name or specialization.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
          ),
        ],
      ),
    );
  }

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
