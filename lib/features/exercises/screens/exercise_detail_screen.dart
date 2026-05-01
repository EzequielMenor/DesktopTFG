import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/admin_layout.dart';
import '../models/admin_exercise.dart';
import '../providers/exercises_provider.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final int exerciseId;

  const ExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<ExercisesProvider>();
    Future.microtask(() => provider.loadDetail(widget.exerciseId));
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Detalle del ejercicio',
      child: Consumer<ExercisesProvider>(
        builder: (context, provider, _) {
          if (provider.isDetailLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (provider.error != null && provider.selectedDetail == null) {
            return Center(
              child: Text(
                provider.error!,
                style: const TextStyle(color: AppTheme.error),
              ),
            );
          }

          final exercise = provider.selectedDetail;
          if (exercise == null) {
            return const Center(
              child: Text(
                'Sin datos',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back + Edit buttons
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => context.go('/exercises'),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppTheme.textSecondary,
                      size: 16,
                    ),
                    label: const Text(
                      'Volver',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.push('/exercises/${exercise.id}/edit'),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editar'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 40),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Main layout: image + info card side by side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image preview
                  if (exercise.imageUrl != null &&
                      exercise.imageUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          exercise.imageUrl!,
                          width: 220,
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 220,
                                height: 180,
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: AppTheme.textSecondary,
                                    size: 40,
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ),

                  // Info card
                  Expanded(child: _InfoCard(exercise: exercise)),
                ],
              ),
              const SizedBox(height: 24),

              // Media links section
              if (_hasMedia(exercise)) ...[
                const _SectionTitle(title: 'Multimedia'),
                const SizedBox(height: 12),
                _MediaLinks(exercise: exercise),
                const SizedBox(height: 24),
              ],

              // Aliases section
              if (exercise.aliases.isNotEmpty) ...[
                const _SectionTitle(title: 'Alias'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: exercise.aliases
                      .map(
                        (a) => Chip(
                          label: Text(
                            a,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: const Color(0xFF2A2A2A),
                          side: const BorderSide(color: Color(0xFF444444)),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  bool _hasMedia(AdminExercise e) =>
      (e.videoUrl != null && e.videoUrl!.isNotEmpty) ||
      (e.thumbnailUrl != null && e.thumbnailUrl!.isNotEmpty);
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  final AdminExercise exercise;
  const _InfoCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Grupo muscular', value: exercise.muscleGroup ?? '—'),
          _InfoRow(label: 'Equipamiento', value: exercise.equipment ?? '—'),
          _InfoRow(
            label: 'Músculos secundarios',
            value: exercise.secondaryMuscles ?? '—',
          ),
          if (exercise.description != null && exercise.description!.isNotEmpty)
            _InfoRow(label: 'Descripción', value: exercise.description!),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }
}

class _MediaLinks extends StatelessWidget {
  final AdminExercise exercise;
  const _MediaLinks({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty)
          _LinkButton(
            icon: Icons.play_circle_outline,
            label: 'Ver video',
            url: exercise.videoUrl!,
          ),
        if (exercise.videoUrl != null &&
            exercise.videoUrl!.isNotEmpty &&
            exercise.thumbnailUrl != null &&
            exercise.thumbnailUrl!.isNotEmpty)
          const SizedBox(width: 12),
        if (exercise.thumbnailUrl != null && exercise.thumbnailUrl!.isNotEmpty)
          _LinkButton(
            icon: Icons.image_outlined,
            label: 'Ver thumbnail',
            url: exercise.thumbnailUrl!,
          ),
      ],
    );
  }
}

class _LinkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;

  const _LinkButton({
    required this.icon,
    required this.label,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        Clipboard.setData(ClipboardData(text: url));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('URL copiada: $url'),
            backgroundColor: AppTheme.surface,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      icon: Icon(icon, size: 16, color: AppTheme.primary),
      label: Text(label, style: const TextStyle(color: AppTheme.primary)),
    );
  }
}
