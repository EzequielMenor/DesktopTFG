/// Modelo de un entrenamiento en la vista de lista del panel de administración.
class AdminWorkout {
  final int id;
  final String? name;
  final String? userEmail;
  final String? startTime;
  final String? endTime;
  final String? notes;
  final double? totalVolume;
  final int exerciseCount;

  const AdminWorkout({
    required this.id,
    this.name,
    this.userEmail,
    this.startTime,
    this.endTime,
    this.notes,
    this.totalVolume,
    required this.exerciseCount,
  });

  factory AdminWorkout.fromJson(Map<String, dynamic> json) {
    return AdminWorkout(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String?,
      userEmail: json['userEmail'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      notes: json['notes'] as String?,
      totalVolume: json['totalVolume'] != null
          ? (json['totalVolume'] as num).toDouble()
          : null,
      exerciseCount: (json['exerciseCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Un ejercicio dentro del detalle del entrenamiento.
class WorkoutExerciseItem {
  final int id;
  final int? exerciseOrder;
  final String? notes;
  final String? exerciseName;
  final String? muscleGroup;

  const WorkoutExerciseItem({
    required this.id,
    this.exerciseOrder,
    this.notes,
    this.exerciseName,
    this.muscleGroup,
  });

  factory WorkoutExerciseItem.fromJson(Map<String, dynamic> json) {
    final exercise = json['exercise'] as Map<String, dynamic>?;
    return WorkoutExerciseItem(
      id: (json['id'] as num).toInt(),
      exerciseOrder: (json['exerciseOrder'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      exerciseName: exercise?['name'] as String?,
      muscleGroup: exercise?['muscleGroup'] as String?,
    );
  }
}

/// Modelo de detalle de un entrenamiento (incluye lista de ejercicios).
class AdminWorkoutDetail extends AdminWorkout {
  final List<WorkoutExerciseItem> exercises;

  const AdminWorkoutDetail({
    required super.id,
    super.name,
    super.userEmail,
    super.startTime,
    super.endTime,
    super.notes,
    super.totalVolume,
    required super.exerciseCount,
    required this.exercises,
  });

  factory AdminWorkoutDetail.fromJson(Map<String, dynamic> json) {
    final base = AdminWorkout.fromJson(json);
    final rawExercises = json['exercises'] as List<dynamic>? ?? [];
    return AdminWorkoutDetail(
      id: base.id,
      name: base.name,
      userEmail: base.userEmail,
      startTime: base.startTime,
      endTime: base.endTime,
      notes: base.notes,
      totalVolume: base.totalVolume,
      exerciseCount: base.exerciseCount,
      exercises: rawExercises
          .map((e) => WorkoutExerciseItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
