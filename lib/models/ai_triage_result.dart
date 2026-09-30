class AITriageResult {
  final String urgencyLevel;
  final String recommendedSpecialization;
  final bool emergencyIndicator;
  final String reasoning;

  const AITriageResult({
    required this.urgencyLevel,
    required this.recommendedSpecialization,
    required this.emergencyIndicator,
    required this.reasoning,
  });

  factory AITriageResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return AITriageResult(
      urgencyLevel:
          json['urgencyLevel']?.toString() ??
          json['UrgencyLevel']?.toString() ??
          'Unknown',
      recommendedSpecialization:
          json['recommendedSpecialization']?.toString() ??
          json['RecommendedSpecialization']?.toString() ??
          'Not specified',
      emergencyIndicator:
          json['emergencyIndicator'] == true ||
          json['EmergencyIndicator'] == true,
      reasoning:
          json['reasoning']?.toString() ??
          json['Reasoning']?.toString() ??
          'No reasoning was provided.',
    );
  }
}