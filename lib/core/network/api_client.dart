import 'dart:convert';
import 'dart:async' show TimeoutException;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_exception.dart';
import 'cancel_token.dart';

/// Cliente HTTP para la app de administración desktop/web.
///
/// Resolución de BACKEND_URL (en orden de prioridad):
///   1. `--dart-define=BACKEND_URL=http://...` (override explícito)
///   2. Web  → http://localhost:8080  (mismo origen, CORS manejado por browser)
///   3. Desktop nativo (macOS/Windows/Linux) → http://localhost:8080
///
/// Para entornos distintos de localhost:
///   flutter run --dart-define=BACKEND_URL=http://192.168.1.100:8080
abstract class ApiClient {
  Future<http.Response> get(
    String path, {
    Map<String, String>? queryParams,
    CancelToken? cancelToken,
  });

  Future<http.Response> post(String path, {Object? body, CancelToken? cancelToken});

  Future<http.Response> put(String path, {Object? body, CancelToken? cancelToken});

  Future<http.Response> delete(String path, {CancelToken? cancelToken});

  String decodeUtf8Body(http.Response response);
}

class HttpApiClient implements ApiClient {
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
    CancelToken? cancelToken,
  ) async {
    int attempt = 0;
    while (attempt < _maxRetries) {
      try {
        _log('$method $path (attempt ${attempt + 1}/$_maxRetries)');
        cancelToken?.throwIfCancelled();
        final response = await request();
        cancelToken?.throwIfCancelled();
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
      } on RequestCancelledException {
        rethrow;
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

  @override
  Future<http.Response> get(
    String path, {
    Map<String, String>? queryParams,
    CancelToken? cancelToken,
  }) async {
    final response = await _executeWithRetry(
      () async {
        var uri = Uri.parse('$_baseUrl$path');
        if (queryParams != null) {
          uri = uri.replace(queryParameters: queryParams);
        }
        return http.get(uri, headers: _headers()).timeout(_standardTimeout);
      },
      'GET',
      path,
      cancelToken,
    );
    _mapError(response);
    return response;
  }

  @override
  Future<http.Response> post(
    String path, {
    Object? body,
    CancelToken? cancelToken,
  }) async {
    final response = await _executeWithRetry(
      () => http
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: _headers(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_standardTimeout),
      'POST',
      path,
      cancelToken,
    );
    _mapError(response);
    return response;
  }

  @override
  Future<http.Response> put(
    String path, {
    Object? body,
    CancelToken? cancelToken,
  }) async {
    final response = await _executeWithRetry(
      () => http
          .put(
            Uri.parse('$_baseUrl$path'),
            headers: _headers(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_standardTimeout),
      'PUT',
      path,
      cancelToken,
    );
    _mapError(response);
    return response;
  }

  @override
  Future<http.Response> delete(
    String path, {
    CancelToken? cancelToken,
  }) async {
    final response = await _executeWithRetry(
      () => http
          .delete(Uri.parse('$_baseUrl$path'), headers: _headers())
          .timeout(_standardTimeout),
      'DELETE',
      path,
      cancelToken,
    );
    _mapError(response);
    return response;
  }

  @override
  String decodeUtf8Body(http.Response response) {
    try {
      return utf8.decode(response.bodyBytes);
    } catch (_) {
      throw const ServerErrorException(500, 'Invalid UTF-8 response body');
    }
  }

  void _mapError(http.Response response) {
    final status = response.statusCode;
    if (status >= 200 && status < 300) return;

    if (status == 403) throw const ForbiddenException();
    if (status == 404) throw const NotFoundException();
    if (status >= 500) throw ServerErrorException(status);
    if (status == 408) throw const ApiTimeoutException();

    throw GenericApiException('Request failed with status code $status', statusCode: status);
  }
}

class ApiClientLegacy {
  static final ApiClient _instance = HttpApiClient();

  static Future<http.Response> get(
    String path, {
    Map<String, String>? queryParams,
    CancelToken? cancelToken,
  }) {
    debugPrint('[ApiClient] DEPRECATED static call: ApiClientLegacy.get($path)');
    return _instance.get(path, queryParams: queryParams, cancelToken: cancelToken);
  }

  static Future<http.Response> post(
    String path, {
    Object? body,
    CancelToken? cancelToken,
  }) {
    debugPrint('[ApiClient] DEPRECATED static call: ApiClientLegacy.post($path)');
    return _instance.post(path, body: body, cancelToken: cancelToken);
  }

  static Future<http.Response> put(
    String path, {
    Object? body,
    CancelToken? cancelToken,
  }) {
    debugPrint('[ApiClient] DEPRECATED static call: ApiClientLegacy.put($path)');
    return _instance.put(path, body: body, cancelToken: cancelToken);
  }

  static Future<http.Response> delete(
    String path, {
    CancelToken? cancelToken,
  }) {
    debugPrint('[ApiClient] DEPRECATED static call: ApiClientLegacy.delete($path)');
    return _instance.delete(path, cancelToken: cancelToken);
  }
}
