import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/budget_helpers.dart';
import '../core/constants.dart';
import '../models/budget_models.dart';
import '../providers/budget_store.dart';
import '../widgets/dialogs.dart';
import '../widgets/ledger_tile.dart';
import 'main_shell.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onNavigate,
    this.userName = 'User',
  });

  final ValueChanged<int> onNavigate;
  final String userName;

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
              Text(
                'Hi, ${userName.trim().isEmpty ? 'user' : userName.trim()}!',
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
                      label: 'Cash inflow',
                      value: money(store.totalIncome, decimals: true),
                      foreground: kPurpleLightColor,
                      background: kCardBlackColor,
                    ),
                  ),
                  const SizedBox(width: 30),
                  Expanded(
                    child: _StatCard(
                      label: 'Spent',
                      value: money(store.totalSpent, decimals: true),
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
              ...store.entries
                  .take(5)
                  .map(
                    (entry) => LedgerTile(
                      entry: entry,
                      onEdit: () => showEditEntry(context, entry),
                      onDelete: () =>
                          context.read<BudgetStore>().deleteEntry(entry.id),
                    ),
                  ),
              if (store.subscriptions.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  'Recurring deductions',
                  style: TextStyle(
                    color: kMutedColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                ...store.subscriptions
                    .take(5)
                    .map(
                      (subscription) => _SubscriptionRecentTile(
                        subscription: subscription,
                        onTap: () => onNavigate(2),
                      ),
                    ),
              ],
              if (store.entries.isEmpty && store.subscriptions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        color: kPurpleLightColor,
                        size: 42,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Your budget is ready for its first entry.',
                        style: TextStyle(color: kMutedColor),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => onNavigate(1),
                        icon: const Icon(Icons.add),
                        label: const Text('Add transaction'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionRecentTile extends StatelessWidget {
  const _SubscriptionRecentTile({
    required this.subscription,
    required this.onTap,
  });

  final SubscriptionProfile subscription;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 62,
        child: Row(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF6E3787),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                categoryIcon(subscription.category),
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subscription.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Subscription · ${relativeDate(subscription.renewalDate)}',
                    style: const TextStyle(
                      color: kMutedColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '-${money(subscription.amount, decimals: true)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: kMutedColor,
              size: 21,
            ),
          ],
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
                      style: TextStyle(color: kMutedColor, fontSize: 14),
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
