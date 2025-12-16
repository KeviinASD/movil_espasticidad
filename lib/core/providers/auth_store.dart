import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';

/// Estado global de autenticación usando Provider
class AuthStore extends ChangeNotifier {
  final StorageService _storageService = StorageService();

  UserModel? _currentUser;
  String? _token;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  // Getters
  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  // Nombre del doctor para mostrar en UI
  String get doctorName {
    if (_currentUser == null) return 'Usuario';
    return _currentUser!.fullName ?? _currentUser!.username;
  }

  // Iniciales para avatar
  String get initials {
    if (_currentUser == null) return 'U';
    final name = _currentUser!.fullName ?? _currentUser!.username;
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  /// Inicializar - Cargar datos guardados
  Future<void> initialize() async {
    _setLoading(true);
    try {
      final hasSession = await _storageService.hasActiveSession();
      if (hasSession) {
        _token = await _storageService.getToken();
        final userData = await _storageService.getUserData();
        if (userData != null) {
          final userJson = jsonDecode(userData) as Map<String, dynamic>;
          _currentUser = UserModel.fromJson(userJson);
          _isAuthenticated = true;
        }
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      await logout(); // Limpiar si hay error
    } finally {
      _setLoading(false);
    }
  }

  /// Login - Guardar usuario y token
  Future<void> login({
    required UserModel user,
    required String token,
  }) async {
    _setLoading(true);
    try {
      // Guardar en storage seguro
      await _storageService.saveToken(token);
      await _storageService.saveUserData(jsonEncode(user.toJson()));

      // Actualizar estado
      _currentUser = user;
      _token = token;
      _isAuthenticated = true;

      notifyListeners();
    } catch (e) {
      debugPrint('Error saving login data: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout - Limpiar todo
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _storageService.clearAll();
      _currentUser = null;
      _token = null;
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error during logout: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Actualizar información del usuario
  void updateUser(UserModel user) {
    _currentUser = user;
    _storageService.saveUserData(jsonEncode(user.toJson()));
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
