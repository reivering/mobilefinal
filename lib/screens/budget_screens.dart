import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/budget_helpers.dart';
import '../models/budget_models.dart';
import '../providers/budget_store.dart';

const _canvas = Color(0xFF160A1B);
const _deepPurple = Color(0xFF2B1B37);
const _purple = Color(0xFF783A99);
const _purpleLight = Color(0xFF964FB6);
const _muted = Color(0xFFAEAEB2);
const _cardBlack = Color(0xFF111111);
const _green = Color(0xFF00AE67);

class BudgetShell extends StatefulWidget {
  const BudgetShell({super.key});

  @override
  State<BudgetShell> createState() => _BudgetShellState();
}

class _BudgetShellState extends State<BudgetShell> {
  int _page = 0;

  void _goTo(int page) {
    setState(() => _page = page);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onNavigate: _goTo),
      AddTransactionScreen(onNavigate: _goTo),
      SubscriptionsScreen(onNavigate: _goTo),
      InsightsScreen(onNavigate: _goTo),
    ];
    return pages[_page];
  }
}

class AppFrame extends StatelessWidget {
  const AppFrame({
    super.key,
    required this.selectedPage,
    required this.onNavigate,
    required this.child,
  });

  final int selectedPage;
  final ValueChanged<int> onNavigate;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_deepPurple, _canvas],
            stops: [0.2, 1],
          ),
        ),
        child: SafeArea(child: child),
      ),
      bottomNavigationBar: _BottomBar(
        selectedPage: selectedPage,
        onNavigate: onNavigate,
      ),
    );
  }
}

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
                      foreground: _purpleLight,
                      background: _cardBlack,
                    ),
                  ),
                  const SizedBox(width: 30),
                  Expanded(
                    child: _StatCard(
                      label: 'Spent',
                      value: money(store.totalSpent),
                      foreground: Colors.black,
                      background: _purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  const Text(
                    'Recent',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TransactionHistoryScreen(),
                      ),
                    ),
                    child: const Text('View all'),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              ...store.expenses.take(5).map(
                    (entry) => _LedgerTile(
                      entry: entry,
                      onEdit: () => _showEditEntry(context, entry),
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

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _category = 'All';
  DateTime? _date;

  bool _sameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BudgetStore>();
    final categories = [
      'All',
      ...store.expenses.map((entry) => entry.category).toSet(),
    ];
    final entries = store.expenses.where((entry) {
      final categoryMatches = _category == 'All' || entry.category == _category;
      final dateMatches = _date == null || _sameDate(entry.date, _date!);
      return categoryMatches && dateMatches;
    }).toList();

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_deepPurple, _canvas],
            stops: [0.2, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(31, 9, 31, 24),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'All transactions',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _category,
                    dropdownColor: const Color(0xFF302035),
                    decoration: InputDecoration(
                      labelText: 'Category',
                      filled: true,
                      fillColor: _cardBlack,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: categories
                        .map((category) => DropdownMenuItem(
                            value: category, child: Text(category)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _category = value ?? 'All'),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: _date ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (selected != null) setState(() => _date = selected);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: _cardBlack,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _date == null
                                ? 'All dates'
                                : fullDate(_date!),
                            style: const TextStyle(color: Colors.white),
                          ),
                          const Spacer(),
                          const Icon(Icons.calendar_month_outlined,
                              color: _muted),
                        ],
                      ),
                    ),
                  ),
                  if (_category != 'All' || _date != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(() {
                          _category = 'All';
                          _date = null;
                        }),
                        child: const Text('Clear filters'),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (entries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: Center(
                        child: Text('No transactions found.',
                            style: TextStyle(color: _muted)),
                      ),
                    ),
                  ...entries.map(
                    (entry) => _LedgerTile(
                      entry: entry,
                      onEdit: () => _showEditEntry(context, entry),
                      onDelete: () =>
                          context.read<BudgetStore>().deleteEntry(entry.id),
                    ),
                  ),
                ],
              ),
            ),
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
    final percentage = (store.budgetProgress * 100).round();
    return Container(
      height: 144,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: _cardBlack,
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
                    color: _green,
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
                    const Text(
                      'Left',
                      style: TextStyle(color: _muted, fontSize: 14),
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
                const Text(
                  'Remaining this month',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  money(store.remaining, decimals: true),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '/ ' + money(store.monthlyBudget, decimals: true),
                  style: const TextStyle(
                    color: _muted,
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
          Text(label,
              style: TextStyle(
                  color: foreground, fontSize: 18, fontWeight: FontWeight.w700)),
          Text(value,
              style: TextStyle(
                  color: foreground, fontSize: 22, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final LedgerEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      margin: const EdgeInsets.only(bottom: 1),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF6E3787),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(color: Color(0x40000000), blurRadius: 8),
              ],
            ),
            child: Icon(
              categoryIcon(entry.category),
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
                Text(entry.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    )),
                Text(
                  entry.category + ' · ' + relativeDate(entry.date),
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '-'+ money(entry.amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: _muted, size: 20),
            color: const Color(0xFF302035),
            onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  EntryType _type = EntryType.expense;
  String _category = 'Food';
  DateTime _date = DateTime(2026, 7, 23);

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  List<String> get _categories => _type == EntryType.expense
      ? const ['Food', 'Bills', 'Phone', 'Transport', 'Rent', 'Entertainment', 'Health', 'Subscription']
      : const ['Savings', 'Salary', 'Investment', 'Part-time'];

  void _setType(EntryType type) {
    setState(() {
      _type = type;
      _category = _categories.first;
    });
  }

  void _save() {
    final value = double.tryParse(_amount.text);
    if (value == null || value <= 0 || _note.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an amount and note first.')),
      );
      return;
    }
    context.read<BudgetStore>().addEntry(
          title: _note.text.trim(),
          amount: value,
          category: _category,
          date: _date,
          type: _type,
        );
    widget.onNavigate(0);
  }

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      selectedPage: 1,
      onNavigate: widget.onNavigate,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(31, 9, 31, 18),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => widget.onNavigate(0),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Text('Add transaction',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              _SegmentedChoice(
                selected: _type,
                onSelected: _setType,
              ),
              const SizedBox(height: 10),
              Container(
                height: 145,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: _cardBlack,
                  borderRadius: BorderRadius.circular(23),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Amount',
                        style: TextStyle(color: _muted, fontSize: 18)),
                    TextField(
                      controller: _amount,
                      textAlign: TextAlign.center,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 29,
                          fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'RM 0.00',
                        hintStyle: TextStyle(color: Colors.white38),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text('Category',
                  style: TextStyle(
                      color: _muted, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 12,
                children: _categories
                    .map(
                      (category) => _CategoryButton(
                        label: category,
                        selected: _category == category,
                        onTap: () => setState(() => _category = category),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 18),
              _DarkInput(label: 'Note', controller: _note, hint: 'What was it for?'),
              const SizedBox(height: 14),
              _DatePicker(
                date: _date,
                onSelected: (date) => setState(() => _date = date),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _purple,
                  minimumSize: const Size.fromHeight(56),
                ),
                child: const Text('Save transaction',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentedChoice extends StatelessWidget {
  const _SegmentedChoice({required this.selected, required this.onSelected});

  final EntryType selected;
  final ValueChanged<EntryType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF351B40),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _Segment(
              text: 'Spent',
              active: selected == EntryType.expense,
              onTap: () => onSelected(EntryType.expense)),
          _Segment(
              text: 'Income',
              active: selected == EntryType.income,
              onTap: () => onSelected(EntryType.income)),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.text, required this.active, required this.onTap});

  final String text;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? _purple : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(text,
              style: TextStyle(
                  color: active ? Colors.white : _muted,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 75,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 75,
              width: 75,
              decoration: BoxDecoration(
                color: selected ? _purple : _cardBlack,
                border: Border.all(
                    color: selected ? _purpleLight : Colors.transparent),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(categoryIcon(label), color: Colors.white, size: 30),
            ),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: selected ? Colors.white : _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _DarkInput extends StatelessWidget {
  const _DarkInput({
    required this.label,
    required this.controller,
    required this.hint,
  });

  final String label;
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: _muted, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _muted),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF6E3787)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _purpleLight, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _DatePicker extends StatelessWidget {
  const _DatePicker({required this.date, required this.onSelected});

  final DateTime date;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date',
            style: TextStyle(
                color: _muted, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 7),
        InkWell(
          onTap: () async {
            final selected = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
            );
            if (selected != null) onSelected(selected);
          },
          borderRadius: BorderRadius.circular(13),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF6E3787)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(fullDate(date),
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
                const Spacer(),
                const Icon(Icons.calendar_month_outlined, color: _muted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final subscriptions = context.watch<BudgetStore>().subscriptions;
    return AppFrame(
      selectedPage: 2,
      onNavigate: onNavigate,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(31, 17, 31, 18),
            children: [
              const Text('Subscriptions',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text(
                'Keep fixed costs visible before they renew.',
                style: TextStyle(color: _muted, fontSize: 15),
              ),
              const SizedBox(height: 20),
              ...subscriptions.map(
                (subscription) => _SubscriptionTile(
                  subscription: subscription,
                  onEdit: () => _showSubscriptionDialog(context, subscription),
                  onDelete: () => context
                      .read<BudgetStore>()
                      .deleteSubscription(subscription.id),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showSubscriptionDialog(context, null),
                icon: const Icon(Icons.add),
                label: const Text('Add subscription'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: _purpleLight),
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionTile extends StatelessWidget {
  const _SubscriptionTile({
    required this.subscription,
    required this.onEdit,
    required this.onDelete,
  });

  final SubscriptionProfile subscription;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBlack,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _purple,
            child: Icon(categoryIcon(subscription.category), color: Colors.white),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subscription.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                Text('Renews ' + fullDate(subscription.renewalDate),
                    style: const TextStyle(color: _muted, fontSize: 13)),
              ],
            ),
          ),
          Text(money(subscription.amount, decimals: true),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: _muted),
            color: const Color(0xFF302035),
            onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BudgetStore>();
    final allTotals = store.spendingByCategory;
    final totals = _selectedCategory == 'All'
        ? allTotals
        : {
            if (allTotals.containsKey(_selectedCategory))
              _selectedCategory: allTotals[_selectedCategory]!,
          };
    final palette = [
      const Color(0xFF14B8A6),
      const Color(0xFFEC4899),
      const Color(0xFF6366F1),
      const Color(0xFFF59E0B),
      const Color(0xFFFACC15),
      const Color(0xFF3B82F6),
    ];
    final filters = [
      'All',
      ...allTotals.keys.take(3),
    ];

    return AppFrame(
      selectedPage: 3,
      onNavigate: widget.onNavigate,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(31, 9, 31, 18),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => widget.onNavigate(0),
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Text('Insights',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 228,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: BoxDecoration(
                  color: _cardBlack,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  children: [
                    PopupMenuButton<String>(
                      onSelected: (_) {},
                      color: const Color(0xFF302035),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'Jul 2026', child: Text('Jul 2026')),
                      ],
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Jul 2026',
                              style: TextStyle(
                                  color: _muted,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                          SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down, color: _muted),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          SizedBox(
                            height: 120,
                            width: 120,
                            child: CustomPaint(
                              painter: _DonutPainter(
                                values: totals.values.toList(),
                                colors: palette,
                              ),
                              child: Center(
                                child: Text(
                                  money(totals.values
                                      .fold(0.0, (sum, value) => sum + value)),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ListView(
                              shrinkWrap: true,
                              children: totals.entries.toList().asMap().entries
                                  .map(
                                    (item) => _LegendRow(
                                      color: palette[item.key % palette.length],
                                      label: item.value.key,
                                      value: money(item.value.value),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text('Category',
                  style: TextStyle(
                      color: _muted, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 12,
                children: filters
                    .map(
                      (category) => _CategoryButton(
                        label: category,
                        selected: _selectedCategory == category,
                        onTap: () =>
                            setState(() => _selectedCategory = category),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              const Text('Monthly spending',
                  style: TextStyle(
                      color: _muted, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 7),
              Text(
                _selectedCategory == 'All'
                    ? 'Choose a category above to focus the chart, or use the ledger filters to inspect specific dates.'
                    : 'Showing your $_selectedCategory spending for July 2026.',
                style: const TextStyle(color: Colors.white, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label, required this.value});

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
          Text(label, style: const TextStyle(color: _muted)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.values, required this.colors});

  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(0.0, (sum, value) => sum + value);
    if (total == 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 25
      ..strokeCap = StrokeCap.butt;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: math.min(size.width, size.height) / 2 - 17,
    );
    var start = -math.pi / 2;
    for (var index = 0; index < values.length; index++) {
      final sweep = (values[index] / total) * math.pi * 2;
      paint.color = colors[index % colors.length];
      canvas.drawArc(rect, start + 0.025, sweep - 0.05, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.selectedPage, required this.onNavigate});

  final int selectedPage;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 87,
      color: _canvas,
      padding: const EdgeInsets.fromLTRB(31, 5, 31, 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavIcon(
              icon: Icons.home_outlined,
              active: selectedPage == 0,
              onTap: () => onNavigate(0)),
          _NavIcon(
              icon: Icons.add,
              active: selectedPage == 1,
              isAdd: true,
              onTap: () => onNavigate(1)),
          _NavIcon(
              icon: Icons.sync,
              active: selectedPage == 2,
              onTap: () => onNavigate(2)),
          _NavIcon(
              icon: Icons.bar_chart_rounded,
              active: selectedPage == 3,
              onTap: () => onNavigate(3)),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.active,
    required this.onTap,
    this.isAdd = false,
  });

  final IconData icon;
  final bool active;
  final bool isAdd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (isAdd) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 50,
          width: 50,
          decoration:
              const BoxDecoration(color: _purple, shape: BoxShape.circle),
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      );
    }
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 30),
      color: active ? _purpleLight : Colors.white,
    );
  }
}

Future<void> _showEditEntry(BuildContext context, LedgerEntry entry) async {
  final note = TextEditingController(text: entry.title);
  final amount = TextEditingController(text: entry.amount.toString());
  var category = entry.category;
  await showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: const Color(0xFF302035),
        title: const Text('Edit transaction',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: note,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Note'),
            ),
            TextField(
              controller: amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            DropdownButton<String>(
              value: category,
              dropdownColor: const Color(0xFF302035),
              isExpanded: true,
              items: const ['Food', 'Bills', 'Phone', 'Transport', 'Rent', 'Health']
                  .map((item) =>
                      DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: (value) => setState(() => category = value ?? category),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(amount.text);
              if (value != null && value > 0 && note.text.trim().isNotEmpty) {
                context.read<BudgetStore>().updateEntry(
                      entry.copyWith(
                        title: note.text.trim(),
                        amount: value,
                        category: category,
                      ),
                    );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  note.dispose();
  amount.dispose();
}

Future<void> _showSubscriptionDialog(
  BuildContext context,
  SubscriptionProfile? current,
) async {
  final name = TextEditingController(text: current?.name ?? '');
  final amount = TextEditingController(
      text: current == null ? '' : current.amount.toStringAsFixed(2));
  var category = current?.category ?? 'Entertainment';
  var date = current?.renewalDate ?? DateTime.now().add(const Duration(days: 30));
  await showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: const Color(0xFF302035),
        title: Text(current == null ? 'Add subscription' : 'Edit subscription',
            style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Name')),
            TextField(
                controller: amount,
                style: const TextStyle(color: Colors.white),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Monthly amount')),
            DropdownButton<String>(
              value: category,
              dropdownColor: const Color(0xFF302035),
              isExpanded: true,
              items: const ['Entertainment', 'Software', 'Phone', 'Bills']
                  .map((item) =>
                      DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: (value) => setState(() => category = value ?? category),
            ),
            TextButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: dialogContext,
                  initialDate: date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null) setState(() => date = picked);
              },
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text('Renewal: ' + fullDate(date)),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(amount.text);
              if (value != null && value > 0 && name.text.trim().isNotEmpty) {
                final store = context.read<BudgetStore>();
                if (current == null) {
                  store.addSubscription(
                    name: name.text.trim(),
                    amount: value,
                    renewalDate: date,
                    category: category,
                  );
                } else {
                  store.updateSubscription(current.copyWith(
                    name: name.text.trim(),
                    amount: value,
                    renewalDate: date,
                    category: category,
                  ));
                }
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  name.dispose();
  amount.dispose();
}


