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
    Future.microtask(() => context.read<ExercisesProvider>().loadExercises());
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
              // Header row: count + "Nuevo" button
              Row(
                children: [
                  Text(
                    '${provider.filtered.length} ejercicios',
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
                          'Grupo muscular',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Equipamiento',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Acciones',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                    rows: provider.filtered
                        .map((e) => _buildRow(context, e, provider))
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
    AdminExercise e,
    ExercisesProvider provider,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(e.name, style: const TextStyle(color: Colors.white))),
        DataCell(
          Text(
            e.muscleGroup ?? '—',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        DataCell(
          Text(
            e.equipment ?? '—',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionButton(
                icon: Icons.visibility_outlined,
                tooltip: 'Ver detalle',
                onTap: () => context.push('/exercises/${e.id}'),
              ),
              const SizedBox(width: 4),
              _ActionButton(
                icon: Icons.edit_outlined,
                tooltip: 'Editar',
                onTap: () => context.push('/exercises/${e.id}/edit'),
              ),
              const SizedBox(width: 4),
              _ActionButton(
                icon: Icons.delete_outline,
                tooltip: 'Eliminar',
                color: AppTheme.error,
                onTap: () => _confirmDelete(context, e, provider),
              ),
            ],
          ),
        ),
      ],
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
