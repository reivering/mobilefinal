import 'package:flutter/material.dart';

import 'screens/budget_screens.dart';

const _canvas = Color(0xFF160A1B);
const _purpleLight = Color(0xFF964FB6);
const _cardBlack = Color(0xFF111111);

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
