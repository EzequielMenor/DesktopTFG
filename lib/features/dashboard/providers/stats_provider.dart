import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../models/admin_stats.dart';

class StatsProvider extends ChangeNotifier {
  AdminStats? _stats;
  bool _isLoading = false;
  String? _error;

  AdminStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.get('/api/admin/stats');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        _stats = AdminStats.fromJson(json);
      } else {
        _error = 'Error al cargar estadísticas (${response.statusCode})';
      }
    } catch (e) {
      _error = 'Error de conexión';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
