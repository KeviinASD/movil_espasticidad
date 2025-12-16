import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio para almacenamiento seguro de datos sensibles
class StorageService {
  static const _storage = FlutterSecureStorage();

  // Keys
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';

  /// Guardar token de acceso
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Obtener token de acceso
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Guardar datos del usuario (JSON string)
  Future<void> saveUserData(String userData) async {
    await _storage.write(key: _userDataKey, value: userData);
  }

  /// Obtener datos del usuario
  Future<String?> getUserData() async {
    return await _storage.read(key: _userDataKey);
  }

  /// Verificar si hay sesión activa
  Future<bool> hasActiveSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Limpiar toda la información (logout)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
