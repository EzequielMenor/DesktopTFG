import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

/// Cache de sesión para evitar llamada redundante a /api/admin/stats en cada login.
class SessionCache {
  static const String _key = 'auth_session';

  static Future<void> save({
    required String email,
    required String role,
    required DateTime expiresAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode({
      'email': email,
      'role': role,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
    }));
  }

  static Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        data['expiresAt'] as int,
      );
      if (DateTime.now().isAfter(expiresAt)) {
        await clear();
        return null;
      }
      return data;
    } catch (_) {
      await clear();
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static bool isValid(Map<String, dynamic> session) {
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      session['expiresAt'] as int,
    );
    return DateTime.now().isBefore(expiresAt);
  }
}

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String? _cachedEmail;
  String? _cachedRole;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get cachedEmail => _cachedEmail;
  String? get cachedRole => _cachedRole;

  bool get isLoggedIn =>
      Supabase.instance.client.auth.currentSession != null;

  String? get currentUserEmail =>
      Supabase.instance.client.auth.currentUser?.email;

  /// Intenta restaurar sesión desde caché local al iniciar la app.
  /// Retorna true si hay sesión válida y el usuario puede saltarse el login.
  Future<bool> tryRestoreSession() async {
    final cached = await SessionCache.load();
    if (cached == null) return false;

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return false;

    _cachedEmail = cached['email'] as String?;
    _cachedRole = cached['role'] as String?;
    notifyListeners();
    return true;
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authResult = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Extraer rol del token JWT si disponible, sino fallback a "admin"
      String role = 'admin';
      final session = authResult.session;
      if (session != null) {
        final tokenParts = session.accessToken.split('.');
        if (tokenParts.length >= 2) {
          try {
            // Base64 decode del payload
            String payload = tokenParts[1];
            // Add padding if needed
            while (payload.length % 4 != 0) {
              payload += '=';
            }
            final decoded = utf8.decode(base64Decode(payload));
            final claims = jsonDecode(decoded) as Map<String, dynamic>;
            role = claims['role'] as String? ?? 'admin';
          } catch (_) {
            // Fallback to admin if token parsing fails
          }
        }
      }

      // Guardar sesión en caché local
      final expiresAt = DateTime.now().add(const Duration(hours: 24));
      await SessionCache.save(
        email: email,
        role: role,
        expiresAt: expiresAt,
      );

      _cachedEmail = email;
      _cachedRole = role;
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Error de conexión con el servidor';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await SessionCache.clear();
    _cachedEmail = null;
    _cachedRole = null;
    await Supabase.instance.client.auth.signOut();
    notifyListeners();
  }
}
