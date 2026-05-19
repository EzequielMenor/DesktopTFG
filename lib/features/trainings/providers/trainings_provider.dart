import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/cancel_token.dart';
import '../models/admin_workout.dart';

class TrainingsProvider extends ChangeNotifier {
  final ApiClient _api;
  CancelToken? _cancelToken;

  TrainingsProvider({ApiClient? api}) : _api = api ?? HttpApiClient();

  List<AdminWorkout> _workouts = [];
  AdminWorkoutDetail? _selectedDetail;
  bool _isLoading = false;
  bool _isDetailLoading = false;
  bool _isSaving = false;
  String? _error;

  // Server-side pagination
  int _currentPage = 0;
  static const int _pageSize = 20;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _hasMorePages = true;
  final Set<int> _cachedIds = {};

  List<AdminWorkout> get workouts => _workouts;
  AdminWorkoutDetail? get selectedDetail => _selectedDetail;
  bool get isLoading => _isLoading;
  bool get isDetailLoading => _isDetailLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  bool get hasMore => _hasMorePages;
  bool get isInitialLoad => _isLoading && _workouts.isEmpty;

  // ---------------------------------------------------------------------------
  // Load list with server-side pagination
  // ---------------------------------------------------------------------------

  Future<void> loadWorkouts() async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    final token = _cancelToken!;

    _currentPage = 0;
    _workouts = [];
    _cachedIds.clear();
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _fetchPage(token);
    } catch (e) {
      if (e is! RequestCancelledException) {
        _error = 'Error de conexión';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga la siguiente página del servidor.
  Future<void> loadMoreWorkouts() async {
    if (_isLoading || !_hasMorePages) return;

    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    final token = _cancelToken!;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _fetchPage(token);
    } catch (e) {
      if (e is! RequestCancelledException) {
        _error = 'Error de conexión';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchPage(CancelToken token) async {
    final response = await _api.get(
      '/api/admin/workouts',
      queryParams: {
        'page': _currentPage.toString(),
        'size': _pageSize.toString(),
      },
      cancelToken: token,
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final list = body['content'] as List<dynamic>;
      final newItems = list
          .map((e) => AdminWorkout.fromJson(e as Map<String, dynamic>))
          .where((w) => !_cachedIds.contains(w.id))
          .toList();

      for (final w in newItems) {
        _cachedIds.add(w.id);
      }
      _workouts = [..._workouts, ...newItems];

      _totalPages = body['totalPages'] as int;
      _totalElements = body['totalElements'] as int;
      _currentPage++;
      _hasMorePages = _currentPage < _totalPages;
    } else {
      _error = 'Error al cargar entrenamientos (${response.statusCode})';
    }
  }

  // ---------------------------------------------------------------------------
  // Load detail
  // ---------------------------------------------------------------------------

  Future<void> loadDetail(int id) async {
    _isDetailLoading = true;
    _selectedDetail = null;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/api/admin/workouts/$id');
      if (response.statusCode == 200) {
        _selectedDetail = AdminWorkoutDetail.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        _error = 'Error al cargar detalle (${response.statusCode})';
      }
    } catch (e) {
      _error = 'Error de conexión';
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Update workout metadata
  // ---------------------------------------------------------------------------

  Future<bool> updateWorkout(int id, {String? name, String? notes}) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final body = <String, String?>{};
      if (name != null) body['name'] = name;
      if (notes != null) body['notes'] = notes;

      final response = await _api.put(
        '/api/admin/workouts/$id',
        body: body,
      );
      if (response.statusCode == 200) {
        await loadWorkouts();
        return true;
      } else {
        _error = 'Error al actualizar (${response.statusCode})';
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Delete workout
  // ---------------------------------------------------------------------------

  Future<bool> deleteWorkout(int id) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.delete('/api/admin/workouts/$id');
      if (response.statusCode == 204) {
        _workouts.removeWhere((w) => w.id == id);
        _cachedIds.remove(id);
        _totalElements--;
        notifyListeners();
        return true;
      } else {
        _error = 'Error al eliminar (${response.statusCode})';
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Supabase Storage — media
  // ---------------------------------------------------------------------------

  static const String _bucket = 'workout-media';

  Future<String?> uploadMedia(
    int workoutId,
    String filename,
    Uint8List bytes,
    String mimeType,
  ) async {
    final path = 'workouts/$workoutId/$filename';
    try {
      await Supabase.instance.client.storage
          .from(_bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          );

      return Supabase.instance.client.storage
          .from(_bucket)
          .getPublicUrl(path);
    } catch (e) {
      debugPrint('[TrainingsProvider] uploadMedia error: $e');
      return null;
    }
  }

  Future<bool> deleteMedia(int workoutId, String filename) async {
    final path = 'workouts/$workoutId/$filename';
    try {
      await Supabase.instance.client.storage.from(_bucket).remove([path]);
      return true;
    } catch (e) {
      debugPrint('[TrainingsProvider] deleteMedia error: $e');
      return false;
    }
  }

  Future<List<FileObject>> listMedia(int workoutId) async {
    try {
      return await Supabase.instance.client.storage
          .from(_bucket)
          .list(path: 'workouts/$workoutId');
    } catch (e) {
      debugPrint('[TrainingsProvider] listMedia error: $e');
      return [];
    }
  }

  String mediaPublicUrl(int workoutId, String filename) {
    return Supabase.instance.client.storage
        .from(_bucket)
        .getPublicUrl('workouts/$workoutId/$filename');
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }
}
