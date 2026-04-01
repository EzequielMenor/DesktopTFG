import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/admin_layout.dart';
import '../providers/users_provider.dart';
import '../models/user_profile.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<UsersProvider>().loadUsers(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Usuarios registrados',
      child: Consumer<UsersProvider>(
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
                '${provider.users.length} usuarios',
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
                      label: Text('Usuario',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                    DataColumn(
                      label: Text('Email',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                    DataColumn(
                      label: Text('Rol',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                    DataColumn(
                      label: Text('Registro',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  ],
                  rows: provider.users
                      .map((user) => _buildRow(user))
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  DataRow _buildRow(UserProfile user) {
    return DataRow(cells: [
      DataCell(
        Text(
          user.username ?? '—',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      DataCell(
        Text(
          user.email,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
      DataCell(_RoleChip(role: user.role)),
      DataCell(
        Text(
          _formatDate(user.createdAt),
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
      ),
    ]);
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final date = DateTime.parse(iso);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return iso;
    }
  }
}

class _RoleChip extends StatelessWidget {
  final String role;

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin ? AppTheme.primaryOverlay : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: isAdmin ? AppTheme.primary : AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: isAdmin ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
