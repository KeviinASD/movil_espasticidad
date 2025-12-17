import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/ai_tool_model.dart';

/// Servicio para gestionar herramientas de IA
class AiToolsService {
  static String get baseUrl =>
      (dotenv.env['API_BASE_URL'] ?? 'http://localhost:3030').trim();

  /// Obtener todas las herramientas de IA
  Future<List<AiToolModel>> getAll({String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/ai-tools');
      final response = await http.get(
        uri,
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => AiToolModel.fromJson(e)).toList();
      } else {
        throw Exception('Error al obtener herramientas IA (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  /// Obtener una herramienta por ID
  Future<AiToolModel> getById(int id, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/ai-tools/$id');
      final response = await http.get(
        uri,
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AiToolModel.fromJson(data);
      } else {
        throw Exception('Herramienta no encontrada (${response.statusCode})');
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

