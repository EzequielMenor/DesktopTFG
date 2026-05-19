import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/cancel_token.dart';
import '../models/admin_stats.dart';

class StatsProvider extends ChangeNotifier {
  final ApiClient _api;
  CancelToken? _cancelToken;

  StatsProvider({ApiClient? api}) : _api = api ?? HttpApiClient();

  AdminStats? _stats;
  bool _isLoading = false;
  String? _error;

  AdminStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadStats() async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    final token = _cancelToken!;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/api/admin/stats', cancelToken: token);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        _stats = AdminStats.fromJson(json);
      } else {
        _error = 'Error al cargar estadísticas (${response.statusCode})';
      }
    } catch (e) {
      if (e is! RequestCancelledException) {
        _error = 'Error de conexión';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }
}
