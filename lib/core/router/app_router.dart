import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/users/screens/users_screen.dart';

/// Returns a [CustomTransitionPage] with a fade transition for desktop
/// platforms, or a standard [MaterialPage] for mobile (Android/iOS).
Page<void> _buildPage({required GoRouterState state, required Widget child}) {
  final isDesktop =
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  if (isDesktop) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        );
      },
    );
  }

  // Mobile: default Material slide transition
  return MaterialPage<void>(key: state.pageKey, child: child);
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (BuildContext context, GoRouterState state) {
    final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
    final isGoingToLogin = state.matchedLocation == '/login';

    if (!isLoggedIn && !isGoingToLogin) return '/login';
    if (isLoggedIn && isGoingToLogin) return '/dashboard';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) =>
          _buildPage(state: state, child: const LoginScreen()),
    ),
    GoRoute(
      path: '/dashboard',
      pageBuilder: (context, state) =>
          _buildPage(state: state, child: const DashboardScreen()),
    ),
    GoRoute(
      path: '/users',
      pageBuilder: (context, state) =>
          _buildPage(state: state, child: const UsersScreen()),
    ),
  ],
);
