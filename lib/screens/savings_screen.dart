import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/budget_helpers.dart';
import '../core/constants.dart';
import '../models/budget_models.dart';
import '../providers/budget_store.dart';
import 'main_shell.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BudgetStore>();
    final history = store.monthlySavings.entries
        .where((item) => item.value > 0)
        .toList();
    final current = store.currentSavings;

    return AppFrame(
      selectedPage: 5,
      onNavigate: onNavigate,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 22, 28, 28),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Savings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton.filled(
                    onPressed: () => _showAddSavings(context),
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: kPurpleColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: kCardBlackColor,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _monthName(DateTime.now()),
                      style: const TextStyle(
                        color: kMutedColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                store.monthlySavingsGoal > 0
                                    ? money(
                                        store.monthlySavingsGoal,
                                        decimals: true,
                                      )
                                    : 'Not set',
                                style: const TextStyle(
                                  color: kPurpleLightColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Text(
                                'monthly goal',
                                style: TextStyle(
                                  color: kMutedColor,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                money(current, decimals: true),
                                style: const TextStyle(
                                  color: kGreenColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Text(
                                'transferred',
                                style: TextStyle(
                                  color: kMutedColor,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Monthly history',
                style: TextStyle(
                  color: kMutedColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (history.isNotEmpty)
                ...history.map(
                  (item) => _MonthRow(month: item.key, amount: item.value),
                ),
              if (history.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Monthly history will appear after your first savings transfer.',
                    style: TextStyle(color: kMutedColor, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 18),
              if (store.savingsRecords.isNotEmpty) ...[
                const Text(
                  'Recent transfers',
                  style: TextStyle(
                    color: kMutedColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ...store.savingsRecords
                    .take(8)
                    .map(
                      (record) => _SavingsRecordTile(
                        record: record,
                        onEdit: () => _showSavingsTransfer(context, record),
                      ),
                    ),
              ] else
                const Text(
                  'No savings transfers yet. Tap + when you move money into savings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kMutedColor, fontSize: 13),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddSavings(BuildContext context) async {
    return _showSavingsTransfer(context);
  }

  Future<void> _showSavingsTransfer(
    BuildContext context, [
    SavingsRecord? current,
  ]) async {
    final amount = TextEditingController(
      text: current?.amount.toStringAsFixed(2) ?? '',
    );
    final note = TextEditingController(
      text: current?.note ?? 'Savings transfer',
    );
    DateTime date = current?.date ?? DateTime.now();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCardBlackColor,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                current == null
                    ? 'Add savings transfer'
                    : 'Edit savings transfer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'RM ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: note,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Note'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.calendar_today_outlined,
                  color: kPurpleLightColor,
                ),
                title: Text(
                  relativeDate(date),
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) setState(() => date = picked);
                },
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  final value = double.tryParse(amount.text.trim());
                  if (value == null || value <= 0 || note.text.trim().isEmpty) {
                    return;
                  }
                  final store = context.read<BudgetStore>();
                  if (value > store.totalIncome) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Savings cannot exceed your cash inflow.',
                        ),
                      ),
                    );
                    return;
                  }
                  final saved = current == null
                      ? store.addSavings(
                          amount: value,
                          note: note.text.trim(),
                          date: date,
                        )
                      : store.updateSavings(
                          current.copyWith(
                            amount: value,
                            note: note.text.trim(),
                            date: date,
                          ),
                        );
                  if (!saved) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Savings cannot exceed your cash inflow.',
                        ),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(sheetContext);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: kPurpleColor,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Save transfer'),
              ),
            ],
          ),
        ),
      ),
    );
    amount.dispose();
    note.dispose();
  }

  String _monthName(DateTime date) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][date.month - 1];
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({required this.month, required this.amount});

  final DateTime month;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBlackColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0x2437C98A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.savings_outlined, color: kGreenColor),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_monthName(month)} ${month.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '+${money(amount, decimals: true)}',
            style: const TextStyle(
              color: kGreenColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(DateTime date) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][date.month - 1];
}

class _SavingsRecordTile extends StatelessWidget {
  const _SavingsRecordTile({required this.record, required this.onEdit});
  final SavingsRecord record;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Dismissible(
    key: Key(record.id),
    direction: DismissDirection.endToStart,
    onDismissed: (_) => context.read<BudgetStore>().deleteSavings(record.id),
    background: Container(
      margin: const EdgeInsets.only(bottom: 8),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFE15B64),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.delete_outline, color: Colors.white),
    ),
    child: InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: kCardBlackColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.savings_outlined, color: kGreenColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.note,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    relativeDate(record.date),
                    style: const TextStyle(color: kMutedColor, fontSize: 13),
                  ),
                ],
              ),
            ),
            Text(
              '+${money(record.amount, decimals: true)}',
              style: const TextStyle(
                color: kGreenColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.edit_outlined, color: kMutedColor, size: 18),
          ],
        ),
      ),
    ),
  );
}
