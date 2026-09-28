class LabReport {
  final String labReportId;
  final String patientId;
  final String patientName;
  final String recordId;
  final String doctorId;
  final String doctorName;
  final String reportName;
  final String? reportType;
  final String? filePath;
  final DateTime uploadedAt;
  final String? uploadedBy;

  LabReport({
    required this.labReportId,
    required this.patientId,
    required this.patientName,
    required this.recordId,
    required this.doctorId,
    required this.doctorName,
    required this.reportName,
    this.reportType,
    this.filePath,
    required this.uploadedAt,
    this.uploadedBy,
  });

  factory LabReport.fromJson(Map<String, dynamic> json) {
    return LabReport(
      labReportId:
          json['labReportId']?.toString() ?? '',
      patientId:
          json['patientId']?.toString() ?? '',
      patientName:
          json['patientName']?.toString() ?? '',
      recordId:
          json['recordId']?.toString() ?? '',
      doctorId:
          json['doctorId']?.toString() ?? '',
      doctorName:
          json['doctorName']?.toString() ?? '',
      reportName:
          json['reportName']?.toString() ?? '',
      reportType:
          json['reportType']?.toString(),
      filePath:
          json['filePath']?.toString(),
      uploadedAt:
          DateTime.parse(
            json['uploadedAt'].toString(),
          ),
      uploadedBy:
          json['uploadedBy']?.toString(),
    );
  }
}