import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/budget_helpers.dart';
import '../core/constants.dart';
import '../providers/budget_store.dart';
import '../widgets/dialogs.dart';
import '../widgets/ledger_tile.dart';
import 'main_shell.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BudgetStore>();
    return AppFrame(
      selectedPage: 0,
      onNavigate: onNavigate,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(31, 17, 31, 18),
            children: [
              const Text(
                'Hi, user!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 22),
              _BudgetSummary(store: store),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Income',
                      value: money(store.totalIncome),
                      foreground: kPurpleLightColor,
                      background: kCardBlackColor,
                    ),
                  ),
                  const SizedBox(width: 30),
                  Expanded(
                    child: _StatCard(
                      label: 'Spent',
                      value: money(store.totalSpent),
                      foreground: Colors.black,
                      background: kPurpleColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              const Text(
                'Recent',
                style: TextStyle(
                  color: kMutedColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 9),
              ...store.expenses.take(5).map(
                    (entry) => LedgerTile(
                      entry: entry,
                      onEdit: () => showEditEntry(context, entry),
                      onDelete: () =>
                          context.read<BudgetStore>().deleteEntry(entry.id),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetSummary extends StatelessWidget {
  const _BudgetSummary({required this.store});

  final BudgetStore store;

  @override
  Widget build(BuildContext context) {
    final remaining = store.remaining;
    final isOverBudget = remaining < 0;
    final percentage = (store.budgetProgress * 100).round();

    final formattedRemaining = isOverBudget
        ? '-${money(remaining.abs(), decimals: true)}'
        : money(remaining, decimals: true);

    const alertRed = Color(0xFFE15B64);

    return Container(
      height: 144,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: kCardBlackColor,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 94,
            width: 94,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 80,
                  width: 80,
                  child: CircularProgressIndicator(
                    value: store.budgetProgress,
                    strokeWidth: 12,
                    backgroundColor: const Color(0xFF383838),
                    color: isOverBudget ? alertRed : kGreenColor,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Left',
                      style: TextStyle(
                        color: kMutedColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOverBudget ? 'Over budget' : 'Remaining this month',
                  style: TextStyle(
                    color: kMutedColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedRemaining,
                  style: TextStyle(
                    color: isOverBudget ? alertRed : Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '/ ${money(store.monthlyBudget, decimals: true)}',
                  style: const TextStyle(
                    color: kMutedColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.foreground,
    required this.background,
  });

  final String label;
  final String value;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.only(left: 17, top: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: foreground,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}