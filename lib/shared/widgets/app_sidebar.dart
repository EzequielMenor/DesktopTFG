import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/providers/auth_provider.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      width: 190,
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          _SidebarItem(
            label: 'Dashboard',
            icon: Icons.dashboard_outlined,
            route: '/dashboard',
            isActive: location == '/dashboard',
          ),
          _SidebarItem(
            label: 'Usuarios',
            icon: Icons.people_outline,
            route: '/users',
            isActive: location == '/users',
          ),
          const Spacer(),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: const Text(
        '⚡ GYM ADMIN',
        style: TextStyle(
          color: AppTheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 15,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final email = context.watch<AuthProvider>().currentUserEmail ?? '';
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Color(0xFF333333)),
          const SizedBox(height: 8),
          Text(
            email,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              await context.read<AuthProvider>().signOut();
              if (context.mounted) context.go('/login');
            },
            child: const Row(
              children: [
                Icon(Icons.logout, size: 14, color: AppTheme.textSecondary),
                SizedBox(width: 6),
                Text(
                  'Cerrar sesión',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final String route;
  final bool isActive;

  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.route,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryOverlay : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isActive ? AppTheme.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? AppTheme.primary : AppTheme.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
