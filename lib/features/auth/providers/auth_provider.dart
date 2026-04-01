import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/api_client.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isLoggedIn =>
      Supabase.instance.client.auth.currentSession != null;

  String? get currentUserEmail =>
      Supabase.instance.client.auth.currentUser?.email;

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Verificar que tiene rol admin
      final response = await ApiClient.get('/api/admin/stats');
      if (response.statusCode == 403) {
        await Supabase.instance.client.auth.signOut();
        _errorMessage = 'Sin permisos de administrador';
        return false;
      }
      if (response.statusCode != 200) {
        await Supabase.instance.client.auth.signOut();
        _errorMessage = 'Error al verificar permisos';
        return false;
      }

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
    await Supabase.instance.client.auth.signOut();
    notifyListeners();
  }
}
