/// Modelo de diagnóstico
class DiagnosisModel {
  final int? diagnosisId;
  final int appointmentId;
  final bool hasSpasticity;
  final String? diagnosisSummary;
  final DateTime? diagnosisDate;

  DiagnosisModel({
    this.diagnosisId,
    required this.appointmentId,
    required this.hasSpasticity,
    this.diagnosisSummary,
    this.diagnosisDate,
  });

  factory DiagnosisModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisModel(
      diagnosisId: json['diagnosisId'] as int?,
      appointmentId: json['appointmentId'] as int,
      hasSpasticity: json['hasSpasticity'] as bool,
      diagnosisSummary: json['diagnosisSummary'] as String?,
      diagnosisDate: json['diagnosisDate'] != null
          ? DateTime.parse(json['diagnosisDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (diagnosisId != null) 'diagnosisId': diagnosisId,
      'appointmentId': appointmentId,
      'hasSpasticity': hasSpasticity,
      if (diagnosisSummary != null) 'diagnosisSummary': diagnosisSummary,
    };
  }

  @override
  String toString() =>
      'DiagnosisModel(id: $diagnosisId, hasSpasticity: $hasSpasticity)';
}

