import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/admin_layout.dart';
import '../providers/exercises_provider.dart';

/// Pantalla de creación y edición de ejercicios.
///
/// Si [exerciseId] es null, se trata de un ejercicio nuevo (POST).
/// Si [exerciseId] no es null, se edita el ejercicio existente (PUT).
class ExerciseFormScreen extends StatefulWidget {
  final int? exerciseId;

  const ExerciseFormScreen({super.key, this.exerciseId});

  @override
  State<ExerciseFormScreen> createState() => _ExerciseFormScreenState();
}

class _ExerciseFormScreenState extends State<ExerciseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _muscleGroupController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _thumbnailUrlController = TextEditingController();
  final _equipmentController = TextEditingController();
  final _secondaryMusclesController = TextEditingController();
  // Aliases se editan como texto separado por comas
  final _aliasesController = TextEditingController();

  bool _initialized = false;

  bool get _isEditing => widget.exerciseId != null;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ExercisesProvider>();
    Future.microtask(() async {
      if (!_isEditing) {
        setState(() => _initialized = true);
        return;
      }

      // Cargamos el detalle si no está ya cargado
      if (provider.selectedDetail == null ||
          provider.selectedDetail!.id != widget.exerciseId) {
        await provider.loadDetail(widget.exerciseId!);
      }
      if (!mounted) return;

      final exercise = provider.selectedDetail;
      if (exercise != null) {
        _nameController.text = exercise.name;
        _muscleGroupController.text = exercise.muscleGroup ?? '';
        _descriptionController.text = exercise.description ?? '';
        _imageUrlController.text = exercise.imageUrl ?? '';
        _videoUrlController.text = exercise.videoUrl ?? '';
        _thumbnailUrlController.text = exercise.thumbnailUrl ?? '';
        _equipmentController.text = exercise.equipment ?? '';
        _secondaryMusclesController.text = exercise.secondaryMuscles ?? '';
        _aliasesController.text = exercise.aliases.join(', ');
      }
      setState(() => _initialized = true);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _muscleGroupController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _videoUrlController.dispose();
    _thumbnailUrlController.dispose();
    _equipmentController.dispose();
    _secondaryMusclesController.dispose();
    _aliasesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: _isEditing ? 'Editar ejercicio' : 'Nuevo ejercicio',
      child: Consumer<ExercisesProvider>(
        builder: (context, provider, _) {
          if (provider.isDetailLoading || !_initialized) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  TextButton.icon(
                    onPressed: () {
                      if (_isEditing) {
                        context.go('/exercises/${widget.exerciseId}');
                      } else {
                        context.go('/exercises');
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppTheme.textSecondary,
                      size: 16,
                    ),
                    label: Text(
                      _isEditing ? 'Volver al detalle' : 'Volver',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nombre (obligatorio)
                  const _FieldLabel(text: 'Nombre *'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Ej. Press de banca',
                      hintStyle: TextStyle(color: AppTheme.textSecondary),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'El nombre es obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Grupo muscular
                  const _FieldLabel(text: 'Grupo muscular'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _muscleGroupController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Ej. Pecho',
                      hintStyle: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Equipamiento
                  const _FieldLabel(text: 'Equipamiento'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _equipmentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Ej. Barra, mancuernas, máquina…',
                      hintStyle: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Músculos secundarios
                  const _FieldLabel(text: 'Músculos secundarios'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _secondaryMusclesController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Ej. Tríceps, hombros',
                      hintStyle: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Descripción
                  const _FieldLabel(text: 'Descripción'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Descripción del ejercicio (opcional)',
                      hintStyle: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // URL imagen
                  const _FieldLabel(text: 'URL de imagen'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _imageUrlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'https://…',
                      hintStyle: TextStyle(color: AppTheme.textSecondary),
                      prefixIcon: Icon(
                        Icons.image_outlined,
                        color: AppTheme.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // URL video
                  const _FieldLabel(text: 'URL de video'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _videoUrlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'https://…',
                      hintStyle: TextStyle(color: AppTheme.textSecondary),
                      prefixIcon: Icon(
                        Icons.play_circle_outline,
                        color: AppTheme.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // URL thumbnail
                  const _FieldLabel(text: 'URL de thumbnail'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _thumbnailUrlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'https://…',
                      hintStyle: TextStyle(color: AppTheme.textSecondary),
                      prefixIcon: Icon(
                        Icons.photo_size_select_actual_outlined,
                        color: AppTheme.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Aliases
                  const _FieldLabel(text: 'Alias (separados por coma)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _aliasesController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Ej. Bench press, Press plano',
                      hintStyle: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error (ej. nombre duplicado)
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
                          : Text(
                              _isEditing
                                  ? 'Guardar cambios'
                                  : 'Crear ejercicio',
                            ),
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

  Future<void> _save(ExercisesProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    // Parsear aliases desde texto separado por comas
    final aliasText = _aliasesController.text.trim();
    final aliases = aliasText.isEmpty
        ? <String>[]
        : aliasText
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();

    final data = {
      'name': _nameController.text.trim(),
      'muscleGroup': _muscleGroupController.text.trim().isEmpty
          ? null
          : _muscleGroupController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'imageUrl': _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim(),
      'videoUrl': _videoUrlController.text.trim().isEmpty
          ? null
          : _videoUrlController.text.trim(),
      'thumbnailUrl': _thumbnailUrlController.text.trim().isEmpty
          ? null
          : _thumbnailUrlController.text.trim(),
      'equipment': _equipmentController.text.trim().isEmpty
          ? null
          : _equipmentController.text.trim(),
      'secondaryMuscles': _secondaryMusclesController.text.trim().isEmpty
          ? null
          : _secondaryMusclesController.text.trim(),
      'aliases': aliases,
    };

    bool ok;
    if (_isEditing) {
      ok = await provider.updateExercise(widget.exerciseId!, data);
    } else {
      ok = await provider.createExercise(data);
    }

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Ejercicio actualizado correctamente'
                : 'Ejercicio creado correctamente',
          ),
          backgroundColor: AppTheme.surface,
        ),
      );
      if (_isEditing) {
        context.go('/exercises/${widget.exerciseId}');
      } else {
        context.go('/exercises');
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

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
