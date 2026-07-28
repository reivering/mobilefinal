import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/budget_helpers.dart';
import '../core/constants.dart';
import '../models/budget_models.dart';
import '../providers/budget_store.dart';
import '../widgets/dialogs.dart';
import 'main_shell.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BudgetStore>();
    final subscriptions = store.subscriptions;

    // Calculations
    final totalRecurring = subscriptions.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );
    final subscriptionRatio = (totalRecurring / store.monthlyBudget).clamp(
      0.0,
      1.0,
    );

    // Date grouping
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final renewingSoon = <SubscriptionProfile>[];
    final renewingLater = <SubscriptionProfile>[];

    for (final sub in subscriptions) {
      final daysLeft = sub.renewalDate.difference(today).inDays;
      if (daysLeft >= 0 && daysLeft <= 9) {
        renewingSoon.add(sub);
      } else {
        renewingLater.add(sub);
      }
    }

    return AppFrame(
      selectedPage: 2,
      onNavigate: onNavigate,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              // Screen Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subscriptions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureButton(
                    onTap: () => showSubscriptionDialog(context, null),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: kPurpleColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Monthly Recurring Overview Card
              Container(
                height: 120,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: kCardBlackColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Monthly recurring',
                            style: TextStyle(
                              color: kMutedColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            money(totalRecurring, decimals: true),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${subscriptions.length} active subscriptions',
                            style: const TextStyle(
                              color: kMutedColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Subscription Donut Ring
                    SizedBox(
                      height: 72,
                      width: 72,
                      child: CircularProgressIndicator(
                        value: subscriptionRatio,
                        strokeWidth: 10,
                        backgroundColor: const Color(0xFF383838),
                        color: kPurpleLightColor,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Group 1: RENEWING SOON (0-9 Days)
              if (renewingSoon.isNotEmpty) ...[
                const Text(
                  'RENEWING SOON',
                  style: TextStyle(
                    color: Color(0xFFE862AC),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                ...renewingSoon.map(
                  (sub) => _SubscriptionCard(
                    subscription: sub,
                    isSoon: true,
                    onTap: () => showSubscriptionDialog(context, sub),
                    onDelete: () => store.deleteSubscription(sub.id),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Group 2: RENEWING LATER THIS MONTH (10+ Days)
              if (renewingLater.isNotEmpty) ...[
                const Text(
                  'RENEWING LATER THIS MONTH',
                  style: TextStyle(
                    color: kMutedColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                ...renewingLater.map(
                  (sub) => _SubscriptionCard(
                    subscription: sub,
                    isSoon: false,
                    onTap: () => showSubscriptionDialog(context, sub),
                    onDelete: () => store.deleteSubscription(sub.id),
                  ),
                ),
              ],

              if (subscriptions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(
                      'No active subscriptions added yet.',
                      style: TextStyle(color: kMutedColor, fontSize: 16),
                    ),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 8),
                  child: Center(
                    child: Text(
                      'Tap to edit · swipe left to cancel',
                      style: TextStyle(color: kMutedColor, fontSize: 13),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class GestureButton extends StatelessWidget {
  const GestureButton({super.key, required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: child,
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.subscription,
    required this.isSoon,
    required this.onTap,
    required this.onDelete,
  });

  final SubscriptionProfile subscription;
  final bool isSoon;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysLeft = subscription.renewalDate.difference(today).inDays;

    final pillBg = isSoon
        ? const Color(0xFFE862AC).withAlpha(40)
        : const Color(0xFF00AE67).withAlpha(40);
    final pillText = isSoon ? const Color(0xFFE862AC) : const Color(0xFF00AE67);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(subscription.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFE15B64),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: 24,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCardBlackColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                // Icon Box
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: kCanvasColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    categoryIcon(subscription.category),
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Name & Price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscription.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${money(subscription.amount, decimals: true)} / month',
                        style: const TextStyle(
                          color: kMutedColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Renewal Countdown Pill & Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: pillBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$daysLeft days',
                        style: TextStyle(
                          color: pillText,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${subscription.renewalDate.day} ${monthName(subscription.renewalDate.month)}',
                      style: const TextStyle(color: kMutedColor, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String monthName(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m - 1];
  }
}
