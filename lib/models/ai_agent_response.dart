class AIAgentResponse {
  final bool success;
  final String agentName;
  final String message;
  final String? output;
  final bool requiresHumanApproval;
  final String? workflowId;

  const AIAgentResponse({
    required this.success,
    required this.agentName,
    required this.message,
    this.output,
    required this.requiresHumanApproval,
    this.workflowId,
  });

  factory AIAgentResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return AIAgentResponse(
      success: json['success'] == true,
      agentName: json['agentName']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      output: json['output']?.toString(),
      requiresHumanApproval:
          json['requiresHumanApproval'] == true,
      workflowId: json['workflowId']?.toString(),
    );
  }
}