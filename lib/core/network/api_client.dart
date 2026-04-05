import 'dart:convert';
import 'dart:async' show TimeoutException;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cliente HTTP para la app de administración desktop/web.
///
/// Resolución de BACKEND_URL (en orden de prioridad):
///   1. `--dart-define=BACKEND_URL=http://...` (override explícito)
///   2. Web  → http://localhost:8080  (mismo origen, CORS manejado por browser)
///   3. Desktop nativo (macOS/Windows/Linux) → http://localhost:8080
///
/// Para entornos distintos de localhost:
///   flutter run --dart-define=BACKEND_URL=http://192.168.1.100:8080
class ApiClient {
  static const String _envUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: '',
  );

  // Timeouts
  static const Duration _standardTimeout = Duration(seconds: 30);

  // Reintentos
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(milliseconds: 500);

  // ---------------------------------------------------------------------------
  // URL resolution
  // ---------------------------------------------------------------------------

  static String get _baseUrl {
    if (_envUrl.isNotEmpty) {
      _log('Using BACKEND_URL from environment: $_envUrl');
      return _envUrl;
    }
    // Web builds (Chrome, canvaskit) — el browser hace la request al mismo host
    // donde está servida la app; localhost funciona en dev.
    if (kIsWeb) return 'http://localhost:8080';

    // Nativo: macOS, Windows, Linux — el backend corre en la misma máquina.
    return 'http://localhost:8080';
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  static void _log(String message) => debugPrint('[ApiClient] $message');

  static Map<String, String> _headers() {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Ejecuta una request con reintentos y exponential backoff.
  static Future<http.Response> _executeWithRetry(
    Future<http.Response> Function() request,
    String method,
    String path,
  ) async {
    int attempt = 0;
    while (attempt < _maxRetries) {
      try {
        _log('$method $path (attempt ${attempt + 1}/$_maxRetries)');
        final response = await request();
        _log('$method $path → ${response.statusCode}');
        return response;
      } on TimeoutException {
        attempt++;
        if (attempt >= _maxRetries) {
          _log('❌ $method $path - timeout after $attempt attempts');
          rethrow;
        }
        final delay = _baseRetryDelay * (1 << (attempt - 1));
        _log('⏳ $method $path timeout — retrying in ${delay.inMilliseconds}ms');
        await Future.delayed(delay);
      } catch (e) {
        attempt++;
        if (attempt >= _maxRetries) {
          _log('❌ $method $path - Exception: $e');
          rethrow;
        }
        _log('⚠️  $method $path error (attempt $attempt) — retrying: $e');
        await Future.delayed(_baseRetryDelay * (1 << (attempt - 1)));
      }
    }
    throw Exception('Failed after $_maxRetries attempts');
  }

  // ---------------------------------------------------------------------------
  // Public HTTP methods
  // ---------------------------------------------------------------------------

  static Future<http.Response> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    return _executeWithRetry(
      () async {
        var uri = Uri.parse('$_baseUrl$path');
        if (queryParams != null) {
          uri = uri.replace(queryParameters: queryParams);
        }
        return http.get(uri, headers: _headers()).timeout(_standardTimeout);
      },
      'GET',
      path,
    );
  }

  static Future<http.Response> post(String path, {Object? body}) async {
    return _executeWithRetry(
      () => http
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: _headers(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_standardTimeout),
      'POST',
      path,
    );
  }

  static Future<http.Response> put(String path, {Object? body}) async {
    return _executeWithRetry(
      () => http
          .put(
            Uri.parse('$_baseUrl$path'),
            headers: _headers(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_standardTimeout),
      'PUT',
      path,
    );
  }

  static Future<http.Response> delete(String path) async {
    return _executeWithRetry(
      () => http
          .delete(Uri.parse('$_baseUrl$path'), headers: _headers())
          .timeout(_standardTimeout),
      'DELETE',
      path,
    );
  }
}
