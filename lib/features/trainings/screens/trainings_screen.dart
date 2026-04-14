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
    Future.microtask(() => context.read<TrainingsProvider>().loadWorkouts());
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Entrenamientos',
      child: Consumer<TrainingsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
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
                '${provider.workouts.length} entrenamientos',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFF2A2A2A),
                    ),
                    dataRowColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return AppTheme.primaryOverlay;
                      }
                      return AppTheme.surface;
                    }),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Nombre',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Usuario',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Fecha',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Ejercicios',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          'Volumen (kg)',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          'Acciones',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                    rows: provider.workouts
                        .map((w) => _buildRow(context, w, provider))
                        .toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  DataRow _buildRow(
    BuildContext context,
    AdminWorkout w,
    TrainingsProvider provider,
  ) {
    return DataRow(
      cells: [
        DataCell(
          Text(w.name ?? '—', style: const TextStyle(color: Colors.white)),
        ),
        DataCell(
          Text(
            w.userEmail ?? '—',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        DataCell(
          Text(
            _formatDate(w.startTime),
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        DataCell(
          Text(
            '${w.exerciseCount}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        DataCell(
          Text(
            w.totalVolume != null ? w.totalVolume!.toStringAsFixed(1) : '—',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionButton(
                icon: Icons.visibility_outlined,
                tooltip: 'Ver detalle',
                onTap: () => context.push('/trainings/${w.id}'),
              ),
              const SizedBox(width: 4),
              _ActionButton(
                icon: Icons.edit_outlined,
                tooltip: 'Editar',
                onTap: () => context.push('/trainings/${w.id}/edit'),
              ),
              const SizedBox(width: 4),
              _ActionButton(
                icon: Icons.delete_outline,
                tooltip: 'Eliminar',
                color: AppTheme.error,
                onTap: () => _confirmDelete(context, w, provider),
              ),
            ],
          ),
        ),
      ],
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

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final date = DateTime.parse(iso);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (_) {
      return iso;
    }
  }
}

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
