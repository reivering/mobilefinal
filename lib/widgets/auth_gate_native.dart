import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/backend_config.dart';
import '../providers/budget_store.dart';
import '../screens/auth_screen.dart';
import '../screens/main_shell.dart';
import '../screens/onboarding_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClerkAuth(
      config: ClerkAuthConfig(
        publishableKey: BackendConfig.clerkPublishableKey,
      ),
      child: ClerkErrorListener(
        child: ClerkAuthBuilder(
          signedInBuilder: (context, authState) =>
              _NativeAuthenticatedApp(authState: authState, child: child),
          signedOutBuilder: (context, authState) => const AuthScreen(),
          builder: (context, authState) =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
        ),
      ),
    );
  }
}

class _NativeAuthenticatedApp extends StatelessWidget {
  const _NativeAuthenticatedApp({required this.authState, required this.child});

  final ClerkAuthState authState;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<clerk.SessionToken>(
      future: BackendConfig.hasSupabase
          ? authState.sessionToken(
              templateName: BackendConfig.supabaseJwtTemplate,
            )
          : null,
      builder: (context, snapshot) {
        final token = snapshot.data?.jwt;
        if (token != null) {
          final client = Supabase.instance.client;
          client.headers = {
            ...client.headers,
            'Authorization': 'Bearer $token',
          };
        }
        final user = authState.user;
        if (user != null) {
          context.read<BudgetStore>().activateUser(user.id);
        }
        if (!context.watch<BudgetStore>().onboardingComplete) {
          return OnboardingScreen(suggestedName: user?.name);
        }
        return BudgetShell(
          onSignOut: authState.signOut,
          userName: user?.name ?? 'User',
          userEmail: user?.email,
        );
      },
    );
  }
}
