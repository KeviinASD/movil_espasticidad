import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Servicio de autenticación contra el backend NestJS.
class AuthService {
  /// URL base desde .env (API_BASE_URL) o fallback a localhost.
  static String get baseUrl =>
      (dotenv.env['API_BASE_URL'] ?? 'http://localhost:3030').trim();

  static const String tokenKey = 'acces_token';

  Future<String?> login({
    required String email,
    required String password,
  }) async {
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
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data['acces_token'] as String?;
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(tokenKey, token);
      }
      return token;
    } else {
      try {
        final data = jsonDecode(response.body);
        return Future.error(data['message'] ?? 'Credenciales inválidas (${response.statusCode})');
      } catch (_) {
        return Future.error('Error al iniciar sesión (${response.statusCode})');
      }
    }
  }

  Future<String?> register({
    required String username,
    required String fullName,
    required String email,
    required String password,
  }) async {
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

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data['acces_token'] as String?;
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(tokenKey, token);
      }
      return token;
    } else {
      try {
        final data = jsonDecode(response.body);
        return Future.error(data['message'] ?? 'No se pudo registrar');
      } catch (_) {
        return Future.error('Error al registrar (${response.statusCode})');
      }
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }
}