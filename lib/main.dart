import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/dashboard/providers/stats_provider.dart';
import 'features/exercises/providers/exercises_provider.dart';
import 'features/trainings/providers/trainings_provider.dart';
import 'features/users/providers/users_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xiggoajtomuwtbarjtvj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhpZ2dvYWp0b211d3RiYXJqdHZqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxNDExODUsImV4cCI6MjA4NTcxNzE4NX0.SXg1cMSbqGHJ4fwSe5q9a_QQLQlYjsLcGLWLZauppbg',
  );

  // Shared instance of ApiClient for dependency injection
  final apiClient = HttpApiClient();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (ctx) => StatsProvider(api: ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => UsersProvider(api: ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => TrainingsProvider(api: ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => ExercisesProvider(api: ctx.read<ApiClient>()),
        ),
      ],
      child: const GymAdminApp(),
    ),
  );
}

class GymAdminApp extends StatelessWidget {
  const GymAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GYM ADMIN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
