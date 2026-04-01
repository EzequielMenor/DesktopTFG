class AdminStats {
  final int totalUsers;
  final int totalWorkouts;
  final int totalExercises;
  final int activeLastWeek;

  AdminStats({
    required this.totalUsers,
    required this.totalWorkouts,
    required this.totalExercises,
    required this.activeLastWeek,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['totalUsers'] as int,
      totalWorkouts: json['totalWorkouts'] as int,
      totalExercises: json['totalExercises'] as int,
      activeLastWeek: json['activeLastWeek'] as int,
    );
  }
}
