import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiClient {
  static const String _baseUrl = 'http://localhost:8080';
  static const Duration _timeout = Duration(seconds: 30);

  static void _log(String message) => debugPrint('[ApiClient] $message');

  static Map<String, String> _headers() {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String path) async {
    _log('GET $path');
    final response = await http
        .get(Uri.parse('$_baseUrl$path'), headers: _headers())
        .timeout(_timeout);
    _log('GET $path → ${response.statusCode}');
    return response;
  }

  static Future<http.Response> post(String path, {Object? body}) async {
    _log('POST $path');
    final response = await http
        .post(
          Uri.parse('$_baseUrl$path'),
          headers: _headers(),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
    _log('POST $path → ${response.statusCode}');
    return response;
  }
}
