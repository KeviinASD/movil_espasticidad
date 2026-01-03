import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/patient_model.dart';

class PatientsService {
  static final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3030';

  /// Obtener todos los pacientes
  static Future<List<PatientModel>> getPatients(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/patients'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PatientModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener pacientes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener un paciente por ID
  static Future<PatientModel> getPatientById(String token, int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/patients/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return PatientModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al obtener paciente: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Crear nuevo paciente
  static Future<PatientModel> createPatient({
    required String token,
    required String fullName,
    required String birthDate,
  }) async {
    try {
      final requestBody = {
        'fullName': fullName.trim(),
        if (birthDate.isNotEmpty) 'birthDate': birthDate, // Solo incluir si no está vacío
      };

      final response = await http.post(
        Uri.parse('$baseUrl/patients'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return PatientModel.fromJson(jsonDecode(response.body));
      } else {
        // Intentar parsear el mensaje de error del servidor
        String errorMessage = 'Error al crear paciente (${response.statusCode})';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map) {
            errorMessage = errorData['message'] ?? 
                          (errorData['errors'] != null 
                            ? errorData['errors'].join(', ') 
                            : errorMessage);
          }
        } catch (_) {
          // Si no se puede parsear, usar el mensaje por defecto
        }
        throw Exception(errorMessage);
      }
    } on http.ClientException {
      throw Exception('Error de conexión: No se pudo conectar al servidor. Verifica tu conexión a internet.');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error inesperado: ${e.toString()}');
    }
  }

  /// Actualizar paciente
  static Future<PatientModel> updatePatient({
    required String token,
    required int id,
    String? fullName,
    String? birthDate,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (fullName != null) body['fullName'] = fullName;
      if (birthDate != null) body['birthDate'] = birthDate;

      final response = await http.patch(
        Uri.parse('$baseUrl/patients/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return PatientModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al actualizar paciente: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Eliminar paciente
  static Future<void> deletePatient(String token, int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/patients/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al eliminar paciente: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
