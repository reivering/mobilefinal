import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Relative imports based on your folder structure
import '../core/budget_helpers.dart';
import '../core/constants.dart';
import '../providers/budget_store.dart';
import '../widgets/donut_painter.dart'; // For DonutPainter
import 'main_shell.dart'; // For AppFrame wrapper

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BudgetStore>();
    final totals = store.currentMonthSpendingByCategory;
    final categories = totals.keys.toList();
    const chartColors = [
      Color(0xFF00C9A7),
      Color(0xFFFFB547),
      Color(0xFF5B8DEF),
      Color(0xFFE862AC),
      Color(0xFFE15B64),
      Color(0xFFB084F5),
      Color(0xFFF4D35E),
      Color(0xFF4DD4FF),
    ];
    final colors = List.generate(
      categories.length,
      (index) => chartColors[index % chartColors.length],
    );

    String topCategory = 'None';
    if (totals.isNotEmpty) {
      topCategory = totals.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }
    return AppFrame(
      selectedPage: 3,
      onNavigate: onNavigate,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(31, 17, 31, 18),
            children: [
              const Text(
                'Insights',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: kCardBlackColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Text(
                      '${DateTime.now().month == 1
                          ? 'January'
                          : DateTime.now().month == 2
                          ? 'February'
                          : DateTime.now().month == 3
                          ? 'March'
                          : DateTime.now().month == 4
                          ? 'April'
                          : DateTime.now().month == 5
                          ? 'May'
                          : DateTime.now().month == 6
                          ? 'June'
                          : DateTime.now().month == 7
                          ? 'July'
                          : DateTime.now().month == 8
                          ? 'August'
                          : DateTime.now().month == 9
                          ? 'September'
                          : DateTime.now().month == 10
                          ? 'October'
                          : DateTime.now().month == 11
                          ? 'November'
                          : 'December'} ${DateTime.now().year}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Inflow  ${money(store.currentMonthIncome, decimals: true)}',
                          style: const TextStyle(
                            color: kGreenColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Outflow  ${money(store.currentMonthOutflow, decimals: true)}',
                          style: const TextStyle(
                            color: Color(0xFFFFB547),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 180,
                      child: CustomPaint(
                        painter: DonutPainter(
                          values: totals.values.toList(),
                          colors: colors,
                        ),
                        child: Center(
                          child: Text(
                            money(store.currentMonthOutflow, decimals: true),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < categories.length; i++)
                      _LegendRow(
                        color: colors[i],
                        label: categories[i],
                        value: money(
                          totals[categories[i]] ?? 0.0,
                          decimals: true,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Takeaway',
                style: TextStyle(
                  color: kMutedColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                totals.isEmpty
                    ? 'No expenses logged for this period yet. Add transactions to generate spending insights!'
                    : '$topCategory is your largest spending category this month.',
                style: const TextStyle(color: Colors.white, height: 1.45),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => _showLimitDialog(context, store),
                icon: const Icon(Icons.tune_rounded),
                label: Text(
                  'Set monthly limit  ·  ${money(store.monthlyBudget, decimals: true)}',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLimitDialog(BuildContext context, BudgetStore store) async {
    final controller = TextEditingController(
      text: store.monthlyBudget.toStringAsFixed(2),
    );
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kCardBlackColor,
        title: const Text(
          'Set monthly limit',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Spending limit',
            prefixText: 'RM ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              if (value == null || value <= 0) return;
              store.updateProfile(
                name: store.profileName ?? 'User',
                budget: value,
                savingsGoal: store.monthlySavingsGoal,
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Save limit'),
          ),
        ],
      ),
    );
    controller.dispose();
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            height: 11,
            width: 11,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: kMutedColor)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
