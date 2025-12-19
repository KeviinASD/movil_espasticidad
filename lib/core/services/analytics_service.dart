import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AnalyticsService {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3030';

  Map<String, String> _buildHeaders(String? token) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Obtener estadísticas generales
  Future<Map<String, dynamic>> getStatistics({
    String? period,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/analytics/statistics')
          .replace(queryParameters: period != null ? {'period': period} : null);
      
      final response = await http.get(
        uri,
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Error al obtener estadísticas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  /// Obtener prevalencia de espasticidad
  Future<Map<String, dynamic>> getPrevalence({
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/analytics/prevalence');
      
      final response = await http.get(
        uri,
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Error al obtener prevalencia: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  /// Obtener desglose por gravedad (MAS)
  Future<Map<String, dynamic>> getSeverityBreakdown({
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/analytics/severity-breakdown');
      
      final response = await http.get(
        uri,
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Error al obtener desglose por gravedad: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  /// Obtener evaluaciones recientes
  Future<List<Map<String, dynamic>>> getRecentEvaluations({
    int limit = 10,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/analytics/recent-evaluations')
          .replace(queryParameters: {'limit': limit.toString()});
      
      final response = await http.get(
        uri,
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Error al obtener evaluaciones recientes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  /// Obtener preferencias de IA
  Future<Map<String, dynamic>> getAiPreferences({
    String? period,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/analytics/ai-preferences')
          .replace(queryParameters: period != null ? {'period': period} : null);
      
      final response = await http.get(
        uri,
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : null;
        final errorMessage = errorBody?['message'] ?? 'Error al obtener preferencias de IA';
        throw Exception('$errorMessage (${response.statusCode})');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Error de conexión al obtener preferencias de IA: ${e.toString()}');
    }
  }

  /// Obtener KPIs
  Future<Map<String, dynamic>> getKpis({
    String? period,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/analytics/kpis')
          .replace(queryParameters: period != null ? {'period': period} : null);
      
      final response = await http.get(
        uri,
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : null;
        final errorMessage = errorBody?['message'] ?? 'Error al obtener KPIs';
        throw Exception('$errorMessage (${response.statusCode})');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Error de conexión al obtener KPIs: ${e.toString()}');
    }
  }
}

