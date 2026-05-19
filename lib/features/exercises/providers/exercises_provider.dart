import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/cancel_token.dart';
import '../models/admin_exercise.dart';

class ExercisesProvider extends ChangeNotifier {
  final ApiClient _api;
  CancelToken? _cancelToken;

  ExercisesProvider({ApiClient? api}) : _api = api ?? HttpApiClient();

  List<AdminExercise> _exercises = [];
  AdminExercise? _selectedDetail;
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

  // Filtros
  String _searchQuery = '';
  String? _muscleGroupFilter;

  List<AdminExercise> get exercises => _exercises;
  AdminExercise? get selectedDetail => _selectedDetail;
  bool get isLoading => _isLoading;
  bool get isDetailLoading => _isDetailLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get muscleGroupFilter => _muscleGroupFilter;

  bool get hasMore => _hasMorePages;
  bool get isInitialLoad => _isLoading && _exercises.isEmpty;

  /// Lista filtrada por búsqueda de texto y grupo muscular.
  List<AdminExercise> get filtered {
    return _exercises.where((e) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (e.muscleGroup?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);

      final matchesMuscle =
          _muscleGroupFilter == null ||
          (e.muscleGroup?.toLowerCase() == _muscleGroupFilter!.toLowerCase());

      return matchesSearch && matchesMuscle;
    }).toList();
  }

  /// Grupos musculares únicos presentes en la lista cargada.
  List<String> get muscleGroups {
    return _exercises
        .map((e) => e.muscleGroup)
        .whereType<String>()
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  // ---------------------------------------------------------------------------
  // Filters
  // ---------------------------------------------------------------------------

  void setSearch(String q) {
    _searchQuery = q;
  }

  void setMuscleFilter(String? muscle) {
    _muscleGroupFilter = muscle;
  }

  // ---------------------------------------------------------------------------
  // Load list with server-side pagination
  // ---------------------------------------------------------------------------

  Future<void> loadExercises() async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    final token = _cancelToken!;

    _currentPage = 0;
    _exercises = [];
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

  /// Carga la siguiente página del servidor con filtros.
  Future<void> loadMoreExercises() async {
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
    final params = <String, String>{
      'page': _currentPage.toString(),
      'size': _pageSize.toString(),
      if (_searchQuery.isNotEmpty) 'name': _searchQuery,
      if (_muscleGroupFilter != null) 'muscleGroup': _muscleGroupFilter!,
    };

    final response = await _api.get(
      '/api/admin/exercises',
      queryParams: params,
      cancelToken: token,
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final list = body['content'] as List<dynamic>;
      final newItems = list
          .map((e) => AdminExercise.fromJson(e as Map<String, dynamic>))
          .where((e) => !_cachedIds.contains(e.id))
          .toList();

      for (final e in newItems) {
        _cachedIds.add(e.id);
      }
      _exercises = [..._exercises, ...newItems];

      _totalPages = body['totalPages'] as int;
      _totalElements = body['totalElements'] as int;
      _currentPage++;
      _hasMorePages = _currentPage < _totalPages;
    } else {
      _error = 'Error al cargar ejercicios (${response.statusCode})';
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
      final response = await _api.get('/api/admin/exercises/$id');
      if (response.statusCode == 200) {
        _selectedDetail = AdminExercise.fromJson(
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
  // Create
  // ---------------------------------------------------------------------------

  Future<bool> createExercise(Map<String, dynamic> data) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post('/api/admin/exercises', body: data);
      if (response.statusCode == 201) {
        await loadExercises();
        return true;
      } else if (response.statusCode == 409) {
        _error = 'Ya existe un ejercicio con ese nombre';
        return false;
      } else {
        _error = 'Error al crear ejercicio (${response.statusCode})';
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
  // Update
  // ---------------------------------------------------------------------------

  Future<bool> updateExercise(int id, Map<String, dynamic> data) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.put(
        '/api/admin/exercises/$id',
        body: data,
      );
      if (response.statusCode == 200) {
        await loadExercises();
        return true;
      } else if (response.statusCode == 409) {
        _error = 'Ya existe un ejercicio con ese nombre';
        return false;
      } else {
        _error = 'Error al actualizar ejercicio (${response.statusCode})';
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
  // Delete
  // ---------------------------------------------------------------------------

  Future<bool> deleteExercise(int id) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.delete('/api/admin/exercises/$id');
      if (response.statusCode == 204) {
        _exercises.removeWhere((e) => e.id == id);
        _cachedIds.remove(id);
        _totalElements--;
        notifyListeners();
        return true;
      } else {
        _error = 'Error al eliminar ejercicio (${response.statusCode})';
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

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }
}
