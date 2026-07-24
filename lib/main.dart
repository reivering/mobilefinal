import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/budget_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final store = BudgetStore();
  await store.initialize();

  runApp(
    ChangeNotifierProvider.value(
      value: store,
      child: const BudgetTrackerApp(),
    ),
  );
}
