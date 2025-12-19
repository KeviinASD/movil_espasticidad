import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/appointment_model.dart';

/// Servicio para gestionar citas con el backend
class AppointmentsService {
  static String get baseUrl =>
      (dotenv.env['API_BASE_URL'] ?? 'http://localhost:3030').trim();

  /// Obtener todas las citas
  Future<List<AppointmentModel>> getAll({String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/appointments');
      final response = await http.get(
        uri,
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => AppointmentModel.fromJson(e)).toList();
      } else {
        throw Exception('Error al obtener citas (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  /// Obtener citas por ID de tratamiento de paciente
  Future<List<AppointmentModel>> getByPatientTreatment(
    int patientTreatmentId, {
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/appointments?patientTreatmentId=$patientTreatmentId');
      final response = await http.get(
        uri,
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => AppointmentModel.fromJson(e)).toList();
      } else {
        throw Exception('Error al obtener citas (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  /// Obtener citas por estado
  Future<List<AppointmentModel>> getByStatus(
    AppointmentStatus status, {
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/appointments?status=${status.value}');
      final response = await http.get(
        uri,
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => AppointmentModel.fromJson(e)).toList();
      } else {
        throw Exception('Error al obtener citas (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  /// Obtener citas próximas de un doctor
  /// Retorna solo citas con estado SCHEDULED o IN_PROGRESS
  /// Ordenadas por fecha ascendente (las más cercanas primero)
  Future<List<AppointmentModel>> getUpcomingAppointments({
    required int doctorId,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/appointments/doctor/$doctorId/upcoming');
      final response = await http.get(
        uri,
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => AppointmentModel.fromJson(e)).toList();
      } else {
        throw Exception('Error al obtener citas próximas (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  /// Obtener una cita por ID
  Future<AppointmentModel> getById(int id, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/appointments/$id');
      final response = await http.get(
        uri,
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AppointmentModel.fromJson(data);
      } else {
        throw Exception('Cita no encontrada (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  /// Crear una nueva cita
  Future<AppointmentModel> create({
    required int patientTreatmentId,
    DateTime? appointmentDate,
    AppointmentStatus status = AppointmentStatus.scheduled,
    int progressPercentage = 0,
    String? notes,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/appointments');
      final body = {
        'patientTreatmentId': patientTreatmentId,
        'status': status.value,
        'progressPercentage': progressPercentage,
        if (appointmentDate != null) 'appointmentDate': appointmentDate.toIso8601String(),
        if (notes != null) 'notes': notes,
      };

      final response = await http.post(
        uri,
        headers: _buildHeaders(token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return AppointmentModel.fromJson(data);
      } else {
        try {
          final data = jsonDecode(response.body);
          throw Exception(data['message'] ?? 'Error al crear cita');
        } catch (_) {
          throw Exception('Error al crear cita (${response.statusCode})');
        }
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  /// Actualizar una cita
  Future<AppointmentModel> update(
    int id, {
    DateTime? appointmentDate,
    AppointmentStatus? status,
    int? progressPercentage,
    String? notes,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/appointments/$id');
      final body = <String, dynamic>{};
      
      if (appointmentDate != null) body['appointmentDate'] = appointmentDate.toIso8601String();
      if (status != null) body['status'] = status.value;
      if (progressPercentage != null) body['progressPercentage'] = progressPercentage;
      if (notes != null) body['notes'] = notes;

      final response = await http.patch(
        uri,
        headers: _buildHeaders(token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AppointmentModel.fromJson(data);
      } else {
        throw Exception('Error al actualizar cita (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  /// Eliminar una cita
  Future<void> delete(int id, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/appointments/$id');
      final response = await http.delete(
        uri,
        headers: _buildHeaders(token),
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Error al eliminar cita (${response.statusCode})');
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

