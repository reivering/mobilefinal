import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:budget_tracker/core/budget_helpers.dart';
import 'package:budget_tracker/models/budget_models.dart';
import 'package:budget_tracker/providers/budget_store.dart';
import 'package:budget_tracker/widgets/dialogs.dart';

void main() {
  test('income transactions expose income categories for editing', () {
    expect(transactionCategories(EntryType.income), contains('Salary'));
    expect(transactionCategories(EntryType.income), isNot(contains('Food')));
  });

  test('expense transactions expose expense categories for editing', () {
    expect(transactionCategories(EntryType.expense), contains('Food'));
    expect(transactionCategories(EntryType.expense), isNot(contains('Salary')));
  });

  test('money always makes the currency clear', () {
    expect(money(10, decimals: true), 'RM 10.00');
    expect(money(0, decimals: true), 'RM 0.00');
  });

  testWidgets('editing an income keeps its income type and category', (
    tester,
  ) async {
    final store = BudgetStore();
    store.addEntry(
      title: 'Monthly income',
      amount: 1000,
      category: 'Salary',
      date: DateTime.now(),
      type: EntryType.income,
    );
    final entry = store.entries.single;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: store,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showEditEntry(context, entry),
                child: const Text('Edit'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Salary'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(store.entries.single.type, EntryType.income);
    expect(store.entries.single.category, 'Salary');
  });
}
