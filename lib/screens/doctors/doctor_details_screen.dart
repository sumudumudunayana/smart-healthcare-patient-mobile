import 'package:flutter/material.dart';

import '../../models/doctor.dart';
import 'doctor_availability_screen.dart';

class DoctorDetailsScreen extends StatelessWidget {
  final Doctor doctor;

  const DoctorDetailsScreen({super.key, required this.doctor});

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }

    if (parts.isNotEmpty) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }

    return 'DR';
  }

  @override
  Widget build(BuildContext context) {
    final isActive = doctor.status.toLowerCase() == 'active';

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Doctor Details',
          style: TextStyle(
            color: Color(0xFF064E3B),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF064E3B)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDoctorHeader(isActive),
            const SizedBox(height: 20),
            _buildProfessionalInformation(),
            const SizedBox(height: 20),
            _buildContactInformation(),
            const SizedBox(height: 25),
            _buildAvailabilityButton(context, isActive),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorHeader(bool isActive) {
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
            color: const Color(0xFF064E3B).withValues(alpha: 0.13),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Center(
              child: Text(
                _getInitials(doctor.fullName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  doctor.specialization,
                  style: const TextStyle(
                    color: Color(0xFFA7F3D0),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (doctor.department != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    doctor.department!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 9,
                    ),
                  ),
                ],
                const SizedBox(height: 9),
                _buildStatusBadge(isActive),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        doctor.status,
        style: TextStyle(
          color: isActive ? const Color(0xFFA7F3D0) : Colors.white70,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildProfessionalInformation() {
    return _buildSection(
      title: 'Professional Information',
      icon: Icons.medical_services_outlined,
      children: [
        _buildInfoRow(
          Icons.workspace_premium_outlined,
          'Experience',
          '${doctor.experience} years',
        ),
        const SizedBox(height: 14),
        _buildInfoRow(
          Icons.badge_outlined,
          'License Number',
          doctor.licenseNumber,
        ),
        const SizedBox(height: 14),
        _buildInfoRow(
          Icons.local_hospital_outlined,
          'Department',
          doctor.department ?? 'Not assigned',
        ),
        const SizedBox(height: 14),
        _buildInfoRow(
          Icons.category_outlined,
          'Specialization',
          doctor.specialization,
        ),
      ],
    );
  }

  Widget _buildContactInformation() {
    return _buildSection(
      title: 'Contact Information',
      icon: Icons.contact_phone_outlined,
      children: [
        _buildInfoRow(Icons.email_outlined, 'Email', doctor.email),
        if (doctor.phone != null && doctor.phone!.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildInfoRow(Icons.phone_outlined, 'Phone', doctor.phone!),
        ],
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE2EEE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: const Color(0xFF059669), size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF064E3B),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF059669), size: 17),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityButton(BuildContext context, bool isActive) {
    return SizedBox(
      width: double.infinity,
      height: 51,
      child: ElevatedButton(
        onPressed: isActive
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DoctorAvailabilityScreen(doctor: doctor),
                  ),
                );
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF059669),
          disabledBackgroundColor: const Color(0xFFCBD5E1),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_rounded, size: 18),
            SizedBox(width: 9),
            Text(
              'View Availability',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
