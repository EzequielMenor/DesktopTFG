/// Modelo de un ejercicio en la vista de administración.
class AdminExercise {
  final int id;
  final String name;
  final String? muscleGroup;
  final String? description;
  final String? imageUrl;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? equipment;
  final String? secondaryMuscles;
  final List<String> aliases;
  final String? createdAt;

  const AdminExercise({
    required this.id,
    required this.name,
    this.muscleGroup,
    this.description,
    this.imageUrl,
    this.videoUrl,
    this.thumbnailUrl,
    this.equipment,
    this.secondaryMuscles,
    this.aliases = const [],
    this.createdAt,
  });

  factory AdminExercise.fromJson(Map<String, dynamic> json) {
    final rawAliases = json['aliases'];
    List<String> aliases = const [];
    if (rawAliases is List) {
      aliases = rawAliases.map((e) => e.toString()).toList();
    }

    return AdminExercise(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      muscleGroup: json['muscleGroup'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      equipment: json['equipment'] as String?,
      secondaryMuscles: json['secondaryMuscles'] as String?,
      aliases: aliases,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'muscleGroup': muscleGroup,
      'description': description,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'equipment': equipment,
      'secondaryMuscles': secondaryMuscles,
      'aliases': aliases,
    };
  }
}
