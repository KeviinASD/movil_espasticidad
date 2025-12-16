import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/treatment_model.dart';

class TreatmentsService {
  static final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3030';

  /// Obtener todos los tratamientos
  static Future<List<TreatmentModel>> getTreatments(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/treatments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TreatmentModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener tratamientos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener tratamiento por ID
  static Future<TreatmentModel> getTreatmentById(String token, int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/treatments/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return TreatmentModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al obtener tratamiento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
