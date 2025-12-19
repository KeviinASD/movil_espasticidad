import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/ai_evaluation_model.dart';

/// Servicio para gestionar evaluaciones de IA
class AiEvaluationsService {
  static String get baseUrl =>
      (dotenv.env['API_BASE_URL'] ?? 'http://localhost:3030').trim();

  /// Obtener evaluaciones por cita
  Future<List<AiEvaluationModel>> getByAppointment(
    int appointmentId, {
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/ai-evaluations?appointmentId=$appointmentId');
      final response = await http.get(
        uri,
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => AiEvaluationModel.fromJson(e)).toList();
      } else {
        throw Exception('Error al obtener evaluaciones (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  /// Crear una nueva evaluación de IA
  Future<AiEvaluationModel> create({
    required int appointmentId,
    required int aiToolId,
    required String aiResult,
    bool isSelected = false,
    String? justification,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/ai-evaluations');
      final body = {
        'appointmentId': appointmentId,
        'aiToolId': aiToolId,
        'aiResult': aiResult,
        'isSelected': isSelected,
        if (justification != null) 'justification': justification,
      };

      final response = await http.post(
        uri,
        headers: _buildHeaders(token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return AiEvaluationModel.fromJson(data);
      } else {
        try {
          final data = jsonDecode(response.body);
          throw Exception(data['message'] ?? 'Error al crear evaluación');
        } catch (_) {
          throw Exception('Error al crear evaluación (${response.statusCode})');
        }
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  /// Actualizar una evaluación (seleccionar/justificar)
  Future<AiEvaluationModel> update(
    int id, {
    bool? isSelected,
    String? justification,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/ai-evaluations/$id');
      final body = <String, dynamic>{};

      if (isSelected != null) body['isSelected'] = isSelected;
      if (justification != null) body['justification'] = justification;

      final response = await http.patch(
        uri,
        headers: _buildHeaders(token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AiEvaluationModel.fromJson(data);
      } else {
        throw Exception('Error al actualizar evaluación (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  /// Seleccionar una evaluación específica y deseleccionar las demás
  Future<AiEvaluationModel> selectEvaluation(
    int evaluationId, {
    String? justification,
    String? token,
  }) async {
    return update(
      evaluationId,
      isSelected: true,
      justification: justification,
      token: token,
    );
  }

  /// Generar evaluación usando Copilot Medical API
  Future<AiEvaluationModel> generateWithCopilot({
    required int appointmentId,
    required int aiToolId,
    required String findings,
    String? masScale,
    String? medications,
    int? patientAge,
    String? patientCondition,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/ai-evaluations/generate');
      final body = <String, dynamic>{
        'appointmentId': appointmentId,
        'aiToolId': aiToolId,
        'findings': findings.trim(),
      };
      
      // Solo agregar campos opcionales si tienen valor
      if (masScale != null && masScale.trim().isNotEmpty) {
        body['masScale'] = masScale.trim();
      }
      if (medications != null && medications.trim().isNotEmpty) {
        body['medications'] = medications.trim();
      }
      if (patientAge != null && patientAge > 0) {
        body['patientAge'] = patientAge;
      }
      if (patientCondition != null && patientCondition.trim().isNotEmpty) {
        body['patientCondition'] = patientCondition.trim();
      }

      final response = await http.post(
        uri,
        headers: _buildHeaders(token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return AiEvaluationModel.fromJson(data);
      } else {
        try {
          final data = jsonDecode(response.body);
          
          // Extraer mensaje de error
          String errorMessage = 'Error al generar evaluación con IA';
          
          if (data is Map) {
            // Si hay un mensaje directo
            if (data['message'] != null) {
              errorMessage = data['message'].toString();
            }
            // Si hay un array de errores
            else if (data['errors'] != null && data['errors'] is List) {
              final errors = data['errors'] as List;
              errorMessage = errors.join('\n');
            }
            // Si hay un error
            else if (data['error'] != null) {
              errorMessage = data['error'].toString();
            }
          }
          
          throw Exception(errorMessage);
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception('Error al generar evaluación (${response.statusCode}): ${response.body}');
        }
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  Map<String, String> _buildHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}

