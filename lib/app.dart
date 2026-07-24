import 'package:flutter/material.dart';

import 'screens/budget_screens.dart';

const _canvas = Color(0xFF160A1B);
const _deepPurple = Color(0xFF2B1B37);
const _purple = Color(0xFF783A99);
const _purpleLight = Color(0xFF964FB6);
const _muted = Color(0xFFAEAEB2);
const _cardBlack = Color(0xFF111111);
const _green = Color(0xFF00AE67);

class BudgetTrackerApp extends StatelessWidget {
  const BudgetTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'DM Sans',
        scaffoldBackgroundColor: _canvas,
        colorScheme: const ColorScheme.dark(
          primary: _purpleLight,
          surface: _cardBlack,
        ),
      ),
      home: const BudgetShell(),
    );
  }
}
