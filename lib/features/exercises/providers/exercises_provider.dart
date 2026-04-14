import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../models/admin_exercise.dart';

class ExercisesProvider extends ChangeNotifier {
  List<AdminExercise> _exercises = [];
  AdminExercise? _selectedDetail;
  bool _isLoading = false;
  bool _isDetailLoading = false;
  bool _isSaving = false;
  String? _error;

  // Filtros client-side
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
    notifyListeners();
  }

  void setMuscleFilter(String? muscle) {
    _muscleGroupFilter = muscle;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Load list
  // ---------------------------------------------------------------------------

  Future<void> loadExercises() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.get('/api/admin/exercises');
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        _exercises = list
            .map((e) => AdminExercise.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _error = 'Error al cargar ejercicios (${response.statusCode})';
      }
    } catch (e) {
      _error = 'Error de conexión';
    } finally {
      _isLoading = false;
      notifyListeners();
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
      final response = await ApiClient.get('/api/admin/exercises/$id');
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

  /// Crea un nuevo ejercicio. Devuelve true si tuvo éxito.
  /// Devuelve el mensaje de error en [error] si el backend rechaza (ej. 409 nombre duplicado).
  Future<bool> createExercise(Map<String, dynamic> data) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.post('/api/admin/exercises', body: data);
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

  /// Actualiza un ejercicio existente. Devuelve true si tuvo éxito.
  Future<bool> updateExercise(int id, Map<String, dynamic> data) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.put(
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

  /// Elimina un ejercicio. Devuelve true si tuvo éxito.
  Future<bool> deleteExercise(int id) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.delete('/api/admin/exercises/$id');
      if (response.statusCode == 204) {
        _exercises.removeWhere((e) => e.id == id);
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
}
