import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/admin_layout.dart';
import '../models/admin_workout.dart';
import '../providers/trainings_provider.dart';

class TrainingsScreen extends StatefulWidget {
  const TrainingsScreen({super.key});

  @override
  State<TrainingsScreen> createState() => _TrainingsScreenState();
}

class _TrainingsScreenState extends State<TrainingsScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<TrainingsProvider>();
    Future.microtask(() => provider.loadWorkouts());
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Entrenamientos',
      child: Consumer<TrainingsProvider>(
        builder: (context, provider, _) {
          if (provider.isInitialLoad) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }
          if (provider.error != null) {
            return Center(
              child: Text(
                provider.error!,
                style: const TextStyle(color: AppTheme.error),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${provider.workouts.length} entrenamientos${provider.hasMore ? " (de ~${provider.workouts.length}+ cargados)" : ""}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Tabla virtualizada
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Header de columnas
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Nombre',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Usuario',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Fecha',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text(
                              'Ejerc.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              'Volumen (kg)',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          SizedBox(
                            width: 140,
                            child: Text(
                              'Acciones',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Lista con shrinkWrap para evitar altura infinita
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.workouts.length,
                      itemBuilder: (context, index) {
                        final w = provider.workouts[index];
                        return _WorkoutListTile(
                          workout: w,
                          onDetail: () => context.push('/trainings/${w.id}'),
                          onEdit: () => context.push('/trainings/${w.id}/edit'),
                          onDelete: () => _confirmDelete(context, w, provider),
                        );
                      },
                    ),
                    // Botón "Cargar más"
                    if (provider.hasMore)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: provider.isLoading
                            ? const CircularProgressIndicator(
                                color: AppTheme.primary,
                              )
                            : OutlinedButton.icon(
                                onPressed: provider.loadMoreWorkouts,
                                icon: const Icon(
                                  Icons.expand_more,
                                  color: AppTheme.primary,
                                ),
                                label: Text(
                                  'Cargar más (${provider.workouts.length} de ~${provider.workouts.length}+)',
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppTheme.primary,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AdminWorkout w,
    TrainingsProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Eliminar entrenamiento',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Eliminar "${w.name ?? 'este entrenamiento'}"? Esta acción no se puede deshacer.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await provider.deleteWorkout(w.id);
    }
  }
}

// ---------------------------------------------------------------------------
// Workout list tile (replaces DataTable rows for virtualization)
// ---------------------------------------------------------------------------

class _WorkoutListTile extends StatelessWidget {
  final AdminWorkout workout;
  final VoidCallback onDetail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WorkoutListTile({
    required this.workout,
    required this.onDetail,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      hoverColor: AppTheme.primaryOverlay,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                workout.name ?? '—',
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                workout.userEmail ?? '—',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _formatDate(workout.startTime),
                style: const TextStyle(color: AppTheme.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                '${workout.exerciseCount}',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              width: 100,
              child: Text(
                workout.totalVolume != null
                    ? workout.totalVolume!.toStringAsFixed(1)
                    : '—',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.right,
              ),
            ),
            SizedBox(
              width: 140,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionButton(
                    icon: Icons.visibility_outlined,
                    tooltip: 'Ver detalle',
                    onTap: onDetail,
                  ),
                  const SizedBox(width: 4),
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Editar',
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 4),
                  _ActionButton(
                    icon: Icons.delete_outline,
                    tooltip: 'Eliminar',
                    color: AppTheme.error,
                    onTap: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final date = DateTime.parse(iso);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (_) {
      return iso;
    }
  }
}

// ---------------------------------------------------------------------------
// Action button
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color = AppTheme.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
