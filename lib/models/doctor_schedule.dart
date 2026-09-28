class DoctorSchedule {
  final String scheduleId;
  final String doctorId;
  final String doctorName;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String availabilityStatus;

  DoctorSchedule({
    required this.scheduleId,
    required this.doctorId,
    required this.doctorName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.availabilityStatus,
  });

  factory DoctorSchedule.fromJson(
    Map<String, dynamic> json,
  ) {
    return DoctorSchedule(
      scheduleId: json['scheduleId'].toString(),
      doctorId: json['doctorId'].toString(),
      doctorName:
          json['doctorName']?.toString() ?? '',
      dayOfWeek:
          json['dayOfWeek']?.toString() ?? '',
      startTime:
          json['startTime']?.toString() ?? '',
      endTime:
          json['endTime']?.toString() ?? '',
      availabilityStatus:
          json['availabilityStatus']?.toString() ?? '',
    );
  }
}