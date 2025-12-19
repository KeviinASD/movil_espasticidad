import 'dart:convert';
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
      // Parsear el JSON que viene del backend
      final Map<String, dynamic> parsed = jsonDecode(aiResult);
      
      // Parsear confidence (puede venir como int, double, o string)
      int confidence = 85;
      final confidenceValue = parsed['confidence'];
      if (confidenceValue != null) {
        if (confidenceValue is int) {
          confidence = confidenceValue;
        } else if (confidenceValue is double) {
          confidence = confidenceValue.toInt();
        } else if (confidenceValue is String) {
          confidence = int.tryParse(confidenceValue) ?? 85;
        }
      }
      
      return AiDiagnosisResult(
        diagnosis: parsed['diagnosis'] as String? ?? 'Espasticidad Grado 3 (MAS)',
        confidencePercent: confidence,
        reasoning: parsed['reasoning'] as String? ?? 
                  'Análisis basado en los datos clínicos proporcionados.',
        suggestedPlan: parsed['suggestedPlan'] != null
            ? List<String>.from(parsed['suggestedPlan'] as List)
            : [
                'Infiltración Toxina Botulínica (Puntos clave)',
                'Fisioterapia intensiva especializada',
                'Seguimiento en 4 semanas',
              ],
      );
    } catch (e) {
      // Si falla el parseo, intentar extraer información del string
      print('Error parseando aiResult: $e');
      print('aiResult recibido: $aiResult');
      
      return AiDiagnosisResult(
        diagnosis: 'Análisis pendiente',
        confidencePercent: 0,
        reasoning: aiResult.isNotEmpty 
            ? aiResult 
            : 'Error al parsear el resultado del análisis.',
        suggestedPlan: [],
      );
    }
  }
}

