import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/models/auth_response_model.dart';

/// Servicio de autenticación contra el backend NestJS.
class AuthService {
  /// URL base desde .env (API_BASE_URL) o fallback a localhost.
  static String get baseUrl =>
      (dotenv.env['API_BASE_URL'] ?? 'http://localhost:3030').trim();

  /// Login y retorna AuthResponse completo
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/login');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim(),
          'password': password.trim(),
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: El servidor no respondió a tiempo. Verifica tu conexión a internet.');
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResponseModel.fromJson(data);
      } else {
        // Intentar parsear el mensaje de error del servidor
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final message = data['message'] ?? 
                         data['error'] ?? 
                         'Error del servidor (${response.statusCode})';
          throw Exception(message);
        } catch (_) {
          // Si no se puede parsear, usar el status code
          String errorMessage = 'Error al iniciar sesión';
          if (response.statusCode == 401 || response.statusCode == 403) {
            errorMessage = 'Credenciales inválidas';
          } else if (response.statusCode == 500) {
            errorMessage = 'Error interno del servidor. Por favor, contacta al administrador.';
          } else if (response.statusCode >= 400) {
            errorMessage = 'Error del servidor (${response.statusCode})';
          }
          throw Exception(errorMessage);
        }
      }
    } on http.ClientException {
      // Errores de red (conexión fallida, DNS, etc.)
      throw Exception('Error de conexión: No se pudo conectar al servidor. Verifica tu conexión a internet y que el servidor esté disponible.');
    } on Exception {
      // Ya es una Exception con mensaje personalizado, relanzarla
      rethrow;
    } catch (e) {
      // Cualquier otro error
      throw Exception('Error inesperado: ${e.toString()}');
    }
  }

  /// Registro de nuevo usuario
  Future<AuthResponseModel> register({
    required String username,
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/register');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username.trim(),
          'fullName': fullName.trim(),
          'email': email.trim(),
          'password': password.trim(),
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResponseModel.fromJson(data);
      } else {
        try {
          final data = jsonDecode(response.body);
          throw Exception(
              data['message'] ?? 'No se pudo registrar (${response.statusCode})');
        } catch (_) {
          throw Exception('Error al registrar (${response.statusCode})');
        }
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  /// Obtener información del usuario actual (requiere token)
  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/me');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('No autorizado (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error al obtener usuario: ${e.toString()}');
    }
  }
}