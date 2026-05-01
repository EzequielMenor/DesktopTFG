import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/admin_layout.dart';
import '../providers/trainings_provider.dart';

class TrainingDetailScreen extends StatefulWidget {
  final int workoutId;

  const TrainingDetailScreen({super.key, required this.workoutId});

  @override
  State<TrainingDetailScreen> createState() => _TrainingDetailScreenState();
}

class _TrainingDetailScreenState extends State<TrainingDetailScreen> {
  List<FileObject> _mediaFiles = [];
  bool _mediaLoading = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<TrainingsProvider>();
    Future.microtask(() async {
      await provider.loadDetail(widget.workoutId);
      await _loadMedia(provider);
    });
  }

  Future<void> _loadMedia(TrainingsProvider provider) async {
    if (!mounted) return;
    setState(() => _mediaLoading = true);
    final files = await provider.listMedia(widget.workoutId);
    if (mounted) {
      setState(() {
        _mediaFiles = files;
        _mediaLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Detalle del entrenamiento',
      child: Consumer<TrainingsProvider>(
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

          final detail = provider.selectedDetail;
          if (detail == null) {
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
                    onPressed: () => context.go('/trainings'),
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
                        context.push('/trainings/${detail.id}/edit'),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editar'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 40),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Info card
              _InfoCard(detail: detail),
              const SizedBox(height: 32),

              // Exercises
              _SectionTitle(title: 'Ejercicios (${detail.exercises.length})'),
              const SizedBox(height: 12),
              if (detail.exercises.isEmpty)
                const Text(
                  'Sin ejercicios registrados.',
                  style: TextStyle(color: AppTheme.textSecondary),
                )
              else
                _ExercisesTable(exercises: detail.exercises),
              const SizedBox(height: 32),

              // Media
              Row(
                children: [
                  _SectionTitle(title: 'Multimedia'),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _uploadMedia(provider),
                    icon: const Icon(
                      Icons.upload,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                    label: const Text(
                      'Subir archivo',
                      style: TextStyle(color: AppTheme.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _mediaLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : _mediaFiles.isEmpty
                  ? const Text(
                      'Sin archivos multimedia.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    )
                  : _MediaGrid(
                      files: _mediaFiles,
                      workoutId: widget.workoutId,
                      provider: provider,
                      onDeleted: () => _loadMedia(provider),
                    ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _uploadMedia(TrainingsProvider provider) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mov'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    final ext = file.extension?.toLowerCase() ?? '';
    final mimeType = _mimeType(ext);
    final filename = file.name;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Subiendo archivo…'),
        backgroundColor: AppTheme.surface,
      ),
    );

    await provider.uploadMedia(
      widget.workoutId,
      filename,
      file.bytes!,
      mimeType,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      await _loadMedia(provider);
    }
  }

  String _mimeType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      default:
        return 'application/octet-stream';
    }
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  final dynamic detail;
  const _InfoCard({required this.detail});

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
            detail.name ?? 'Sin nombre',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Usuario', value: detail.userEmail ?? '—'),
          _InfoRow(label: 'Inicio', value: _fmt(detail.startTime)),
          _InfoRow(label: 'Fin', value: _fmt(detail.endTime)),
          _InfoRow(
            label: 'Volumen',
            value: detail.totalVolume != null
                ? '${detail.totalVolume!.toStringAsFixed(1)} kg'
                : '—',
          ),
          if (detail.notes != null && detail.notes!.isNotEmpty)
            _InfoRow(label: 'Notas', value: detail.notes!),
        ],
      ),
    );
  }

  String _fmt(String? iso) {
    if (iso == null) return '—';
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
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
            width: 90,
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

class _ExercisesTable extends StatelessWidget {
  final List<dynamic> exercises;
  const _ExercisesTable({required this.exercises});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFF2A2A2A)),
        columns: const [
          DataColumn(
            label: Text(
              'Orden',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          DataColumn(
            label: Text(
              'Ejercicio',
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
              'Notas',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
        rows: exercises.map((e) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  '${e.exerciseOrder ?? '—'}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              DataCell(
                Text(
                  e.exerciseName ?? '—',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              DataCell(
                Text(
                  e.muscleGroup ?? '—',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              DataCell(
                Text(
                  e.notes ?? '—',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MediaGrid extends StatelessWidget {
  final List<FileObject> files;
  final int workoutId;
  final TrainingsProvider provider;
  final VoidCallback onDeleted;

  const _MediaGrid({
    required this.files,
    required this.workoutId,
    required this.provider,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: files.map((f) {
        final url = provider.mediaPublicUrl(workoutId, f.name);
        final isImage = _isImage(f.name);
        return _MediaTile(
          filename: f.name,
          url: url,
          isImage: isImage,
          onDelete: () async {
            final ok = await provider.deleteMedia(workoutId, f.name);
            if (ok) onDeleted();
          },
        );
      }).toList(),
    );
  }

  bool _isImage(String name) {
    final ext = name.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }
}

class _MediaTile extends StatelessWidget {
  final String filename;
  final String url;
  final bool isImage;
  final VoidCallback onDelete;

  const _MediaTile({
    required this.filename,
    required this.url,
    required this.isImage,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: isImage
                ? Image.network(
                    url,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(
                          height: 110,
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                  )
                : const SizedBox(
                    height: 110,
                    child: Center(
                      child: Icon(
                        Icons.videocam_outlined,
                        color: AppTheme.textSecondary,
                        size: 36,
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    filename,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: onDelete,
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: AppTheme.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
