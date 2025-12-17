import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/appointment_answer_model.dart';

/// Servicio para gestionar respuestas de citas
class AppointmentAnswersService {
  static String get baseUrl =>
      (dotenv.env['API_BASE_URL'] ?? 'http://localhost:3030').trim();

  /// Obtener respuestas por ID de cita
  Future<List<AppointmentAnswerModel>> getByAppointment(
    int appointmentId, {
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/appointment-answers?appointmentId=$appointmentId');
      final response = await http.get(
        uri,
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => AppointmentAnswerModel.fromJson(e)).toList();
      } else {
        throw Exception('Error al obtener respuestas (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  /// Crear una nueva respuesta
  Future<AppointmentAnswerModel> create({
    required int appointmentId,
    required int questionId,
    required double numericValue,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/appointment-answers');
      final body = {
        'appointmentId': appointmentId,
        'questionId': questionId,
        'numericValue': numericValue,
      };

      final response = await http.post(
        uri,
        headers: _buildHeaders(token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return AppointmentAnswerModel.fromJson(data);
      } else {
        try {
          final data = jsonDecode(response.body);
          throw Exception(data['message'] ?? 'Error al crear respuesta');
        } catch (_) {
          throw Exception('Error al crear respuesta (${response.statusCode})');
        }
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  /// Crear múltiples respuestas a la vez
  Future<List<AppointmentAnswerModel>> createMultiple({
    required int appointmentId,
    required List<Map<String, dynamic>> answers,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/appointment-answers/bulk');
      final body = {
        'appointmentId': appointmentId,
        'answers': answers,
      };

      final response = await http.post(
        uri,
        headers: _buildHeaders(token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => AppointmentAnswerModel.fromJson(e)).toList();
      } else {
        try {
          final data = jsonDecode(response.body);
          throw Exception(data['message'] ?? 'Error al crear respuestas');
        } catch (_) {
          throw Exception('Error al crear respuestas (${response.statusCode})');
        }
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  /// Actualizar una respuesta
  Future<AppointmentAnswerModel> update(
    int id, {
    double? numericValue,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/appointment-answers/$id');
      final body = <String, dynamic>{};

      if (numericValue != null) body['numericValue'] = numericValue;

      final response = await http.patch(
        uri,
        headers: _buildHeaders(token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AppointmentAnswerModel.fromJson(data);
      } else {
        throw Exception('Error al actualizar respuesta (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  /// Eliminar una respuesta
  Future<void> delete(int id, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/appointment-answers/$id');
      final response = await http.delete(
        uri,
        headers: _buildHeaders(token),
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Error al eliminar respuesta (${response.statusCode})');
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

