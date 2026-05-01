import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/admin_layout.dart';
import '../models/admin_exercise.dart';
import '../providers/exercises_provider.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<ExercisesProvider>();
    Future.microtask(() => provider.loadExercises());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Ejercicios',
      child: Consumer<ExercisesProvider>(
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
              // Header row: count + "Nuevo" button
              Row(
                children: [
                  Text(
                    '${provider.filtered.length} ejercicios${provider.hasMore ? " (de ~${provider.exercises.length}+ cargados)" : ""}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/exercises/new'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Nuevo ejercicio'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(160, 40),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Filter row: search + muscle group dropdown
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Buscar por nombre o músculo…',
                        hintStyle: TextStyle(color: AppTheme.textSecondary),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppTheme.textSecondary,
                          size: 18,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      onChanged: provider.setSearch,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _MuscleGroupDropdown(provider: provider),
                ],
              ),
              const SizedBox(height: 24),

              // Table
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
                              'Grupo muscular',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Equipamiento',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
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
                      itemCount: provider.filtered.length,
                      itemBuilder: (context, index) {
                        final e = provider.filtered[index];
                        return _ExerciseListTile(
                          exercise: e,
                          onDetail: () => context.push('/exercises/${e.id}'),
                          onEdit: () => context.push('/exercises/${e.id}/edit'),
                          onDelete: () => _confirmDelete(context, e, provider),
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
                                onPressed: provider.loadMoreExercises,
                                icon: const Icon(
                                  Icons.expand_more,
                                  color: AppTheme.primary,
                                ),
                                label: Text(
                                  'Cargar más (${provider.filtered.length} de ~${provider.exercises.length}+)',
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
    AdminExercise e,
    ExercisesProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Eliminar ejercicio',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Eliminar "${e.name}"? Esta acción no se puede deshacer.',
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
      await provider.deleteExercise(e.id);
    }
  }
}

// ---------------------------------------------------------------------------
// Muscle group dropdown
// ---------------------------------------------------------------------------

class _MuscleGroupDropdown extends StatelessWidget {
  final ExercisesProvider provider;
  const _MuscleGroupDropdown({required this.provider});

  @override
  Widget build(BuildContext context) {
    final groups = provider.muscleGroups;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF444444)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: provider.muscleGroupFilter,
          hint: const Text(
            'Todos los músculos',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          dropdownColor: AppTheme.surface,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'Todos los músculos',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ...groups.map(
              (g) => DropdownMenuItem<String?>(value: g, child: Text(g)),
            ),
          ],
          onChanged: provider.setMuscleFilter,
        ),
      ),
    );
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

// ---------------------------------------------------------------------------
// Exercise list tile (replaces DataTable rows for virtualization)
// ---------------------------------------------------------------------------

class _ExerciseListTile extends StatelessWidget {
  final AdminExercise exercise;
  final VoidCallback onDetail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExerciseListTile({
    required this.exercise,
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
                exercise.name,
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                exercise.muscleGroup ?? '—',
                style: const TextStyle(color: AppTheme.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                exercise.equipment ?? '—',
                style: const TextStyle(color: AppTheme.textSecondary),
                overflow: TextOverflow.ellipsis,
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
}
