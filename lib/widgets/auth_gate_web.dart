import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;

import '../core/backend_config.dart';
import '../providers/budget_store.dart';
import '../screens/main_shell.dart';
import '../screens/onboarding_screen.dart';

@JS('Clerk')
external ClerkJs get clerk;

@JS()
extension type ClerkJs(JSObject _) implements JSObject {
  external JSPromise<JSAny?> load(JSAny? options);
  external bool get isSignedIn;
  external ClerkSession? get session;
  external ClerkUser? get user;
  external JSPromise<JSAny?> signOut();
  external void addListener(JSFunction callback);
}

@JS()
extension type ClerkUser(JSObject _) implements JSObject {
  external String get id;
  external String? get fullName;
  external ClerkEmail? get primaryEmailAddress;
}

@JS()
extension type ClerkEmail(JSObject _) implements JSObject {
  external String? get emailAddress;
}

@JS()
extension type ClerkSession(JSObject _) implements JSObject {
  external JSPromise<JSAny?> getToken(JSAny? options);
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loaded = false;
  bool _signedIn = false;
  bool _redirecting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeClerk());
  }

  Future<void> _initializeClerk() async {
    try {
      await clerk.load({}.jsify()).toDart;
      if (!mounted) return;
      setState(() {
        _loaded = true;
        _signedIn = clerk.isSignedIn;
      });
      if (_signedIn) await _activateUser();
      clerk.addListener(
        (JSAny? _) {
          if (!mounted) return;
          final signedIn = clerk.isSignedIn;
          setState(() => _signedIn = signedIn);
          if (signedIn) unawaited(_activateUser());
        }.toJS,
      );
      if (!_signedIn) {
        _redirectToHostedSignIn();
      } else {
        await _syncSupabaseToken();
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  void _redirectToHostedSignIn() {
    if (_redirecting) return;
    _redirecting = true;
    final returnUrl = Uri.base.replace(fragment: '').toString();
    final hostedUrl = Uri.parse(
      'https://wise-polliwog-39.accounts.dev/sign-in',
    ).replace(queryParameters: {'redirect_url': returnUrl});
    web.window.location.href = hostedUrl.toString();
  }

  Future<void> _activateUser() async {
    final id = clerk.user?.id;
    if (id != null && mounted) {
      await context.read<BudgetStore>().activateUser(id);
    }
  }

  Future<void> _syncSupabaseToken() async {
    if (!BackendConfig.hasSupabase || clerk.session == null) return;
    try {
      final token = await clerk.session!
          .getToken({'template': BackendConfig.supabaseJwtTemplate}.jsify())
          .toDart;
      if (token case JSString token) {
        final client = Supabase.instance.client;
        client.headers = {
          ...client.headers,
          'Authorization': 'Bearer ${token.toDart}',
        };
      }
    } catch (_) {
      // The Supabase JWT template is optional while the Clerk instance is
      // being configured. Keep the signed-in app usable until it exists.
    }
  }

  Future<void> _signOut() async {
    await clerk.signOut().toDart;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text('Clerk failed to load: $_error'));
    }
    if (!_loaded) return const Center(child: CircularProgressIndicator());
      if (_signedIn) {
        final user = clerk.user;
        if (!context.watch<BudgetStore>().onboardingComplete) {
          return OnboardingScreen(suggestedName: user?.fullName);
        }
        return BudgetShell(
          onSignOut: _signOut,
          userName: user?.fullName ?? 'User',
          userEmail: user?.primaryEmailAddress?.emailAddress,
        );
      }
    return const Center(child: CircularProgressIndicator());
  }
}
