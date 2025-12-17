import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/question_model.dart';

/// Servicio para gestionar preguntas cuantitativas
class QuestionsService {
  static String get baseUrl =>
      (dotenv.env['API_BASE_URL'] ?? 'http://localhost:3030').trim();

  /// Obtener todas las preguntas
  Future<List<QuestionModel>> getAll({String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/questions');
      final response = await http.get(
        uri,
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => QuestionModel.fromJson(e)).toList();
      } else {
        throw Exception('Error al obtener preguntas (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  /// Obtener una pregunta por ID
  Future<QuestionModel> getById(int id, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/questions/$id');
      final response = await http.get(
        uri,
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return QuestionModel.fromJson(data);
      } else {
        throw Exception('Pregunta no encontrada (${response.statusCode})');
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

