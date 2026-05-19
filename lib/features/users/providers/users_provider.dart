import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/cancel_token.dart';
import '../models/user_profile.dart';

class UsersProvider extends ChangeNotifier {
  final ApiClient _api;
  CancelToken? _cancelToken;

  UsersProvider({ApiClient? api}) : _api = api ?? HttpApiClient();

  List<UserProfile> _users = [];
  bool _isLoading = false;
  String? _error;

  List<UserProfile> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUsers() async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    final token = _cancelToken!;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/api/admin/users', cancelToken: token);
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        _users = list
            .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _error = 'Error al cargar usuarios (${response.statusCode})';
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
