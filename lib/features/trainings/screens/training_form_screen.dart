import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/admin_layout.dart';
import '../providers/trainings_provider.dart';

/// Pantalla de edición de metadatos de un entrenamiento existente.
/// El admin solo puede editar nombre y notas; los tiempos y el usuario
/// los gestiona la app móvil del usuario.
class TrainingFormScreen extends StatefulWidget {
  final int workoutId;

  const TrainingFormScreen({super.key, required this.workoutId});

  @override
  State<TrainingFormScreen> createState() => _TrainingFormScreenState();
}

class _TrainingFormScreenState extends State<TrainingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<TrainingsProvider>();
    Future.microtask(() async {
      // Si no hay detalle cargado (navegación directa), lo cargamos
      if (provider.selectedDetail == null ||
          provider.selectedDetail!.id != widget.workoutId) {
        await provider.loadDetail(widget.workoutId);
      }
      if (!mounted) return;
      final detail = provider.selectedDetail;
      if (detail != null) {
        _nameController.text = detail.name ?? '';
        _notesController.text = detail.notes ?? '';
      }
      setState(() => _initialized = true);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Editar entrenamiento',
      child: Consumer<TrainingsProvider>(
        builder: (context, provider, _) {
          if (provider.isDetailLoading || !_initialized) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  TextButton.icon(
                    onPressed: () =>
                        context.go('/trainings/${widget.workoutId}'),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppTheme.textSecondary,
                      size: 16,
                    ),
                    label: const Text(
                      'Volver al detalle',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Name field
                  _FieldLabel(text: 'Nombre'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Nombre del entrenamiento',
                      hintStyle: TextStyle(color: AppTheme.textSecondary),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'El nombre es obligatorio'
                        : null,
                  ),
                  const SizedBox(height: 24),

                  // Notes field
                  _FieldLabel(text: 'Notas'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Notas del entrenamiento (opcional)',
                      hintStyle: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error
                  if (provider.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        provider.error!,
                        style: const TextStyle(color: AppTheme.error),
                      ),
                    ),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: provider.isSaving
                          ? null
                          : () => _save(provider),
                      child: provider.isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text('Guardar cambios'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _save(TrainingsProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await provider.updateWorkout(
      widget.workoutId,
      name: _nameController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrenamiento actualizado'),
          backgroundColor: AppTheme.surface,
        ),
      );
      context.go('/trainings/${widget.workoutId}');
    }
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
