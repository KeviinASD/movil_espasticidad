import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/diagnosis_model.dart';

/// Servicio para gestionar diagnósticos
class DiagnosesService {
  static String get baseUrl =>
      (dotenv.env['API_BASE_URL'] ?? 'http://localhost:3030').trim();

  /// Obtener diagnósticos por cita
  Future<List<DiagnosisModel>> getByAppointment(
    int appointmentId, {
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/diagnoses?appointmentId=$appointmentId');
      final response = await http.get(
        uri,
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => DiagnosisModel.fromJson(e)).toList();
      } else {
        throw Exception('Error al obtener diagnósticos (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  /// Crear un nuevo diagnóstico
  Future<DiagnosisModel> create({
    required int appointmentId,
    required bool hasSpasticity,
    String? diagnosisSummary,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/diagnoses');
      final body = {
        'appointmentId': appointmentId,
        'hasSpasticity': hasSpasticity,
        if (diagnosisSummary != null) 'diagnosisSummary': diagnosisSummary,
      };

      final response = await http.post(
        uri,
        headers: _buildHeaders(token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return DiagnosisModel.fromJson(data);
      } else {
        try {
          final data = jsonDecode(response.body);
          throw Exception(data['message'] ?? 'Error al crear diagnóstico');
        } catch (_) {
          throw Exception('Error al crear diagnóstico (${response.statusCode})');
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

