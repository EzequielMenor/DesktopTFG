import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../models/user_profile.dart';

class UsersProvider extends ChangeNotifier {
  List<UserProfile> _users = [];
  bool _isLoading = false;
  String? _error;

  List<UserProfile> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.get('/api/admin/users');
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        _users = list
            .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _error = 'Error al cargar usuarios (${response.statusCode})';
      }
    } catch (e) {
      _error = 'Error de conexión';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
