import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCanvasColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const ClerkAuthentication(),
            ),
          ),
        ),
      ),
    );
  }
}
