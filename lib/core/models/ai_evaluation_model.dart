import 'ai_tool_model.dart';

/// Modelo de evaluación con IA
class AiEvaluationModel {
  final int? evaluationId;
  final int appointmentId;
  final int aiToolId;
  final String aiResult;
  final bool isSelected;
  final String? justification;
  final DateTime? evaluationDate;
  final AiToolModel? aiTool;

  AiEvaluationModel({
    this.evaluationId,
    required this.appointmentId,
    required this.aiToolId,
    required this.aiResult,
    this.isSelected = false,
    this.justification,
    this.evaluationDate,
    this.aiTool,
  });

  factory AiEvaluationModel.fromJson(Map<String, dynamic> json) {
    return AiEvaluationModel(
      evaluationId: json['evaluationId'] as int?,
      appointmentId: json['appointmentId'] as int,
      aiToolId: json['aiToolId'] as int,
      aiResult: json['aiResult'] as String,
      isSelected: json['isSelected'] as bool? ?? false,
      justification: json['justification'] as String?,
      evaluationDate: json['evaluationDate'] != null
          ? DateTime.parse(json['evaluationDate'] as String)
          : null,
      aiTool: json['aiTool'] != null
          ? AiToolModel.fromJson(json['aiTool'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (evaluationId != null) 'evaluationId': evaluationId,
      'appointmentId': appointmentId,
      'aiToolId': aiToolId,
      'aiResult': aiResult,
      'isSelected': isSelected,
      if (justification != null) 'justification': justification,
    };
  }

  AiEvaluationModel copyWith({
    int? evaluationId,
    int? appointmentId,
    int? aiToolId,
    String? aiResult,
    bool? isSelected,
    String? justification,
    DateTime? evaluationDate,
    AiToolModel? aiTool,
  }) {
    return AiEvaluationModel(
      evaluationId: evaluationId ?? this.evaluationId,
      appointmentId: appointmentId ?? this.appointmentId,
      aiToolId: aiToolId ?? this.aiToolId,
      aiResult: aiResult ?? this.aiResult,
      isSelected: isSelected ?? this.isSelected,
      justification: justification ?? this.justification,
      evaluationDate: evaluationDate ?? this.evaluationDate,
      aiTool: aiTool ?? this.aiTool,
    );
  }

  @override
  String toString() =>
      'AiEvaluationModel(id: $evaluationId, tool: ${aiTool?.name}, selected: $isSelected)';
}

/// Resultado parseado de la IA
class AiDiagnosisResult {
  final String diagnosis;
  final int confidencePercent;
  final String reasoning;
  final List<String> suggestedPlan;

  AiDiagnosisResult({
    required this.diagnosis,
    required this.confidencePercent,
    required this.reasoning,
    required this.suggestedPlan,
  });

  /// Parsear resultado JSON de la IA
  factory AiDiagnosisResult.fromAiResult(String aiResult) {
    try {
      // Intentar parsear como JSON
      final Map<String, dynamic> parsed = {};
      // Por ahora, simular un resultado estructurado
      return AiDiagnosisResult(
        diagnosis: 'Espasticidad Grado 3 (MAS)',
        confidencePercent: 89,
        reasoning: aiResult.isNotEmpty 
            ? aiResult 
            : 'Análisis basado en los datos clínicos proporcionados.',
        suggestedPlan: [
          'Infiltración Toxina Botulínica (Puntos clave)',
          'Fisioterapia intensiva especializada',
          'Seguimiento en 4 semanas',
        ],
      );
    } catch (_) {
      return AiDiagnosisResult(
        diagnosis: 'Análisis pendiente',
        confidencePercent: 0,
        reasoning: aiResult,
        suggestedPlan: [],
      );
    }
  }
}

