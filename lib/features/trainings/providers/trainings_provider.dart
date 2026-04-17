import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/api_client.dart';
import '../models/admin_workout.dart';

class TrainingsProvider extends ChangeNotifier {
  List<AdminWorkout> _workouts = [];
  List<AdminWorkout> _allWorkouts = []; // Todos los entrenamientos descargados
  AdminWorkoutDetail? _selectedDetail;
  bool _isLoading = false;
  bool _isDetailLoading = false;
  bool _isSaving = false;
  String? _error;

  // Paginación client-side
  int _page = 1;
  static const int _limit = 50;
  int _totalCount = 0;
  bool _isInitialLoad = true;

  List<AdminWorkout> get workouts => _workouts;
  AdminWorkoutDetail? get selectedDetail => _selectedDetail;
  bool get isLoading => _isLoading;
  bool get isInitialLoad => _isInitialLoad;
  bool get isDetailLoading => _isDetailLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  /// Indica si hay más entrenamientos por cargar.
  bool get hasMore => _workouts.length < _totalCount;

  // ---------------------------------------------------------------------------
  // Load list
  // ---------------------------------------------------------------------------

  Future<void> loadWorkouts() async {
    _page = 1;
    _workouts = [];
    _allWorkouts = [];
    _isLoading = true;
    _isInitialLoad = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.get('/api/admin/workouts');
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        _allWorkouts = list
            .map((e) => AdminWorkout.fromJson(e as Map<String, dynamic>))
            .toList();

        _totalCount = _allWorkouts.length;
        _workouts = _allWorkouts.take(_limit).toList();
        _page = 1;
      } else {
        _error = 'Error al cargar entrenamientos (${response.statusCode})';
      }
    } catch (e) {
      _error = 'Error de conexión';
    } finally {
      _isLoading = false;
      _isInitialLoad = false;
      notifyListeners();
    }
  }

  /// Carga los siguientes _limit entrenamientos y los appendea a la lista.
  Future<void> loadMoreWorkouts() async {
    if (_isLoading || !hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Usar los datos ya descargados en _allWorkouts
      final start = _page * _limit;

      if (start < _allWorkouts.length) {
        final newItems = _allWorkouts.skip(start).take(_limit).toList();
        _workouts = [..._workouts, ...newItems];
        _page++;
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
      final response = await ApiClient.get('/api/admin/workouts/$id');
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

  /// Actualiza name y/o notes de un entrenamiento.
  /// Devuelve true si tuvo éxito.
  Future<bool> updateWorkout(int id, {String? name, String? notes}) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final body = <String, String?>{};
      if (name != null) body['name'] = name;
      if (notes != null) body['notes'] = notes;

      final response = await ApiClient.put(
        '/api/admin/workouts/$id',
        body: body,
      );
      if (response.statusCode == 200) {
        // Refresca la lista en background
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

  /// Elimina un entrenamiento. Devuelve true si tuvo éxito.
  Future<bool> deleteWorkout(int id) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.delete('/api/admin/workouts/$id');
      if (response.statusCode == 204) {
        _workouts.removeWhere((w) => w.id == id);
        _allWorkouts.removeWhere((w) => w.id == id);
        _totalCount--;
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

  /// Sube un archivo al bucket de Supabase Storage en la ruta workouts/{id}/{filename}.
  /// Devuelve la URL pública del archivo, o null si falla.
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

      final url = Supabase.instance.client.storage
          .from(_bucket)
          .getPublicUrl(path);
      return url;
    } catch (e) {
      debugPrint('[TrainingsProvider] uploadMedia error: $e');
      return null;
    }
  }

  /// Elimina un archivo del bucket de Supabase Storage.
  /// Devuelve true si tuvo éxito.
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

  /// Lista los archivos almacenados en Supabase Storage para un workout.
  /// Devuelve lista de FileObject o lista vacía si falla / no existe.
  Future<List<FileObject>> listMedia(int workoutId) async {
    try {
      final files = await Supabase.instance.client.storage
          .from(_bucket)
          .list(path: 'workouts/$workoutId');
      return files;
    } catch (e) {
      debugPrint('[TrainingsProvider] listMedia error: $e');
      return [];
    }
  }

  /// Genera la URL pública de un archivo en Supabase Storage.
  String mediaPublicUrl(int workoutId, String filename) {
    return Supabase.instance.client.storage
        .from(_bucket)
        .getPublicUrl('workouts/$workoutId/$filename');
  }
}
