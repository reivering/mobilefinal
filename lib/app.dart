import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/backend_config.dart';
import 'core/constants.dart';
import 'screens/main_shell.dart';
import 'widgets/auth_gate.dart';

class BudgetTrackerApp extends StatelessWidget {
  const BudgetTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      fontFamily: 'DM Sans',
      scaffoldBackgroundColor: kCanvasColor,
      colorScheme: const ColorScheme.dark(
        primary: kPurpleLightColor,
        surface: kCardBlackColor,
      ),
    );

    final app = MaterialApp(
      title: 'Budget tracker',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: !kIsWeb && !BackendConfig.hasClerk
          ? const _BackendSetupScreen()
          : const AuthGate(child: BudgetShell()),
    );

    return app;
  }
}

class _BackendSetupScreen extends StatelessWidget {
  const _BackendSetupScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCanvasColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Backend setup needed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Run the app with CLERK_PUBLISHABLE_KEY. Add SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY when your Supabase project is ready.',
                  style: TextStyle(
                    color: kMutedColor,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
