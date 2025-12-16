import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/patient_treatment_model.dart';

class PatientTreatmentsService {
  static final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3030';

  /// Obtener todos los tratamientos (con filtros opcionales)
  static Future<List<PatientTreatmentModel>> getPatientTreatments({
    required String token,
    int? patientId,
    int? doctorId,
  }) async {
    try {
      // Construir URL con query parameters
      final queryParams = <String, String>{};
      if (patientId != null) queryParams['patientId'] = patientId.toString();
      if (doctorId != null) queryParams['doctorId'] = doctorId.toString();

      final uri = Uri.parse('$baseUrl/patient-treatments').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PatientTreatmentModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener tratamientos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener tratamiento por ID
  static Future<PatientTreatmentModel> getPatientTreatmentById(
    String token,
    int id,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/patient-treatments/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return PatientTreatmentModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al obtener tratamiento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Crear nuevo tratamiento de paciente
  static Future<PatientTreatmentModel> createPatientTreatment({
    required String token,
    required int patientId,
    required int doctorId,
    required int treatmentId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/patient-treatments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'patientId': patientId,
          'doctorId': doctorId,
          'treatmentId': treatmentId,
          'startDate': startDate,
          'endDate': endDate,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return PatientTreatmentModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al crear tratamiento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Actualizar tratamiento de paciente
  static Future<PatientTreatmentModel> updatePatientTreatment({
    required String token,
    required int id,
    int? patientId,
    int? doctorId,
    int? treatmentId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (patientId != null) body['patientId'] = patientId;
      if (doctorId != null) body['doctorId'] = doctorId;
      if (treatmentId != null) body['treatmentId'] = treatmentId;
      if (startDate != null) body['startDate'] = startDate;
      if (endDate != null) body['endDate'] = endDate;

      final response = await http.patch(
        Uri.parse('$baseUrl/patient-treatments/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return PatientTreatmentModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al actualizar tratamiento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Eliminar tratamiento de paciente
  static Future<void> deletePatientTreatment(String token, int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/patient-treatments/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al eliminar tratamiento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
