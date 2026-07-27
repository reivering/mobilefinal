import 'package:flutter/material.dart';

import 'core/constants.dart';
import 'screens/main_shell.dart';

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
        scaffoldBackgroundColor: kCanvasColor,
        colorScheme: const ColorScheme.dark(
          primary: kPurpleLightColor,
          surface: kCardBlackColor,
        ),
      ),
      home: const BudgetShell(),
    );
  }
}
