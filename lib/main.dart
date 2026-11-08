import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'data/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase if credentials are provided; otherwise runs in high-fidelity mock mode
  await SupabaseConfig.initialize();

  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (_) {}

  runApp(
    ProviderScope(
      overrides: [
        if (prefs != null)
          themeModeProvider.overrideWith((ref) => ThemeNotifier(prefs)),
      ],
      child: const CasamaApp(),
    ),
  );
}

class CasamaApp extends ConsumerWidget {
  const CasamaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Casama',
      debugShowCheckedModeBanner: false,
      theme: CasamaTheme.lightTheme,
      darkTheme: CasamaTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
