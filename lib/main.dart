import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

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

const _canvas = Color(0xFF160A1B);
const _deepPurple = Color(0xFF2B1B37);
const _purple = Color(0xFF783A99);
const _purpleLight = Color(0xFF964FB6);
const _muted = Color(0xFFAEAEB2);
const _cardBlack = Color(0xFF111111);
const _green = Color(0xFF00AE67);

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

enum EntryType { income, expense }

class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.type,
  });

  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final EntryType type;

  LedgerEntry copyWith({
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    EntryType? type,
  }) {
    return LedgerEntry(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      type: type ?? this.type,
    );
  }
}

class SubscriptionProfile {
  const SubscriptionProfile({
    required this.id,
    required this.name,
    required this.amount,
    required this.renewalDate,
    required this.category,
  });

  final String id;
  final String name;
  final double amount;
  final DateTime renewalDate;
  final String category;

  SubscriptionProfile copyWith({
    String? name,
    double? amount,
    DateTime? renewalDate,
    String? category,
  }) {
    return SubscriptionProfile(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      renewalDate: renewalDate ?? this.renewalDate,
      category: category ?? this.category,
    );
  }
}

class BudgetStore extends ChangeNotifier {
  Box<dynamic>? _box;

  final double monthlyBudget = 800;
  final List<LedgerEntry> _entries = [
    LedgerEntry(
      id: 'income',
      title: 'Part-time job',
      amount: 1200,
      category: 'Part-time',
      date: DateTime(2026, 7, 20),
      type: EntryType.income,
    ),
    LedgerEntry(
      id: 'mamak',
      title: 'Mamak',
      amount: 12,
      category: 'Food',
      date: DateTime(2026, 7, 23),
      type: EntryType.expense,
    ),
    LedgerEntry(
      id: 'electric',
      title: 'Electric Bill',
      amount: 150,
      category: 'Bills',
      date: DateTime(2026, 7, 22),
      type: EntryType.expense,
    ),
    LedgerEntry(
      id: 'dinner',
      title: 'Dinner',
      amount: 52,
      category: 'Food',
      date: DateTime(2026, 7, 22),
      type: EntryType.expense,
    ),
    LedgerEntry(
      id: 'lunch',
      title: 'Lunch',
      amount: 20,
      category: 'Food',
      date: DateTime(2026, 7, 22),
      type: EntryType.expense,
    ),
    LedgerEntry(
      id: 'phone',
      title: 'Phone bills',
      amount: 50,
      category: 'Phone',
      date: DateTime(2026, 7, 21),
      type: EntryType.expense,
    ),
    LedgerEntry(
      id: 'other',
      title: 'Groceries',
      amount: 96,
      category: 'Food',
      date: DateTime(2026, 7, 19),
      type: EntryType.expense,
    ),
  ];

  final List<SubscriptionProfile> _subscriptions = [
    SubscriptionProfile(
      id: 'spotify',
      name: 'Spotify',
      amount: 16.90,
      renewalDate: DateTime(2026, 8, 2),
      category: 'Entertainment',
    ),
    SubscriptionProfile(
      id: 'adobe',
      name: 'Adobe Creative Cloud',
      amount: 31.80,
      renewalDate: DateTime(2026, 8, 8),
      category: 'Software',
    ),
  ];

  List<LedgerEntry> get entries =>
      List.unmodifiable(_entries..sort((a, b) => b.date.compareTo(a.date)));
  List<LedgerEntry> get expenses =>
      entries.where((entry) => entry.type == EntryType.expense).toList();
  List<SubscriptionProfile> get subscriptions => List.unmodifiable(_subscriptions);

  double get totalSpent =>
      expenses.fold(0.0, (sum, entry) => sum + entry.amount);
  double get totalIncome => entries
      .where((entry) => entry.type == EntryType.income)
      .fold(0.0, (sum, entry) => sum + entry.amount);
  double get remaining => math.max(0.0, monthlyBudget - totalSpent).toDouble();
  double get budgetProgress =>
      (remaining / monthlyBudget).clamp(0.0, 1.0).toDouble();

  Map<String, double> get spendingByCategory {
    final totals = <String, double>{};
    for (final entry in expenses) {
      totals.update(entry.category, (value) => value + entry.amount,
          ifAbsent: () => entry.amount);
    }
    return totals;
  }

  void addEntry({
    required String title,
    required double amount,
    required String category,
    required DateTime date,
    required EntryType type,
  }) {
    _entries.add(
      LedgerEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        amount: amount,
        category: category,
        date: date,
        type: type,
      ),
    );
    _persist();
    notifyListeners();
  }

  void updateEntry(LedgerEntry replacement) {
    final index = _entries.indexWhere((entry) => entry.id == replacement.id);
    if (index != -1) {
      _entries[index] = replacement;
      _persist();
      notifyListeners();
    }
  }

  void deleteEntry(String id) {
    _entries.removeWhere((entry) => entry.id == id);
    _persist();
    notifyListeners();
  }

  void addSubscription({
    required String name,
    required double amount,
    required DateTime renewalDate,
    required String category,
  }) {
    _subscriptions.add(
      SubscriptionProfile(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        amount: amount,
        renewalDate: renewalDate,
        category: category,
      ),
    );
    _persist();
    notifyListeners();
  }

  void updateSubscription(SubscriptionProfile replacement) {
    final index =
        _subscriptions.indexWhere((subscription) => subscription.id == replacement.id);
    if (index != -1) {
      _subscriptions[index] = replacement;
      _persist();
      notifyListeners();
    }
  }

  void deleteSubscription(String id) {
    _subscriptions.removeWhere((subscription) => subscription.id == id);
    _persist();
    notifyListeners();
  }

  Future<void> initialize() async {
    _box = await Hive.openBox<dynamic>('budget_tracker');
    _restore();
  }

  void _restore() {
    final savedEntries = _box?.get('entries');
    if (savedEntries is List && savedEntries.isNotEmpty) {
      _entries
        ..clear()
        ..addAll(
          savedEntries
              .whereType<Map>()
              .map((item) => _entryFromMap(Map<String, dynamic>.from(item))),
        );
    }

    final savedSubscriptions = _box?.get('subscriptions');
    if (savedSubscriptions is List && savedSubscriptions.isNotEmpty) {
      _subscriptions
        ..clear()
        ..addAll(
          savedSubscriptions
              .whereType<Map>()
              .map((item) => _subscriptionFromMap(Map<String, dynamic>.from(item))),
        );
    }

    _persist();
  }

  void _persist() {
    final box = _box;
    if (box == null) return;
    box.put('entries', _entries.map(_entryToMap).toList());
    box.put('subscriptions', _subscriptions.map(_subscriptionToMap).toList());
  }

  Map<String, dynamic> _entryToMap(LedgerEntry entry) => {
        'id': entry.id,
        'title': entry.title,
        'amount': entry.amount,
        'category': entry.category,
        'date': entry.date.toIso8601String(),
        'type': entry.type.name,
      };

  LedgerEntry _entryFromMap(Map<String, dynamic> item) => LedgerEntry(
        id: item['id'] as String,
        title: item['title'] as String,
        amount: (item['amount'] as num).toDouble(),
        category: item['category'] as String,
        date: DateTime.parse(item['date'] as String),
        type: item['type'] == EntryType.income.name
            ? EntryType.income
            : EntryType.expense,
      );

  Map<String, dynamic> _subscriptionToMap(SubscriptionProfile subscription) => {
        'id': subscription.id,
        'name': subscription.name,
        'amount': subscription.amount,
        'renewalDate': subscription.renewalDate.toIso8601String(),
        'category': subscription.category,
      };

  SubscriptionProfile _subscriptionFromMap(Map<String, dynamic> item) =>
      SubscriptionProfile(
        id: item['id'] as String,
        name: item['name'] as String,
        amount: (item['amount'] as num).toDouble(),
        renewalDate: DateTime.parse(item['renewalDate'] as String),
        category: item['category'] as String,
      );
}

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
              const Text(
                'Recent',
                style: TextStyle(
                  color: _muted,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 9),
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

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final totals = context.watch<BudgetStore>().spendingByCategory;
    final palette = [_purpleLight, const Color(0xFF00AE67), const Color(0xFFF2A33A),
      const Color(0xFF4B8FEA), const Color(0xFFE15B64)];
    return AppFrame(
      selectedPage: 3,
      onNavigate: onNavigate,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(31, 17, 31, 18),
            children: [
              const Text('Insights',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: _cardBlack,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const Text('July 2026',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 180,
                      child: CustomPaint(
                        painter: _DonutPainter(
                          values: totals.values.toList(),
                          colors: palette,
                        ),
                        child: Center(
                          child: Text(
                            money(context.read<BudgetStore>().totalSpent),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...totals.entries.toList().asMap().entries.map(
                          (item) => _LegendRow(
                            color: palette[item.key % palette.length],
                            label: item.value.key,
                            value: money(item.value.value),
                          ),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Takeaway',
                  style: TextStyle(
                      color: _muted, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 7),
              const Text(
                'Food is your largest spending category this month. Set a weekly food limit to protect your remaining budget.',
                style: TextStyle(color: Colors.white, height: 1.45),
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

IconData categoryIcon(String category) {
  switch (category) {
    case 'Food':
      return Icons.restaurant;
    case 'Bills':
      return Icons.receipt_long_outlined;
    case 'Phone':
      return Icons.smartphone_outlined;
    case 'Transport':
      return Icons.train_outlined;
    case 'Rent':
      return Icons.home_outlined;
    case 'Entertainment':
      return Icons.confirmation_number_outlined;
    case 'Health':
      return Icons.medical_services_outlined;
    case 'Savings':
      return Icons.savings_outlined;
    case 'Salary':
      return Icons.credit_card_outlined;
    case 'Investment':
      return Icons.trending_up;
    case 'Part-time':
      return Icons.schedule_outlined;
    case 'Software':
      return Icons.code_outlined;
    case 'Subscription':
      return Icons.sync;
    default:
      return Icons.account_balance_wallet_outlined;
  }
}

String money(double value, {bool decimals = false}) {
  final showDecimals = decimals || value % 1 != 0;
  return 'RM ' + value.toStringAsFixed(showDecimals ? 2 : 0);
}

String relativeDate(DateTime date) {
  const today = DateTime(2026, 7, 23);
  if (date.year == today.year && date.month == today.month && date.day == today.day) {
    return 'today';
  }
  return date.day.toString() + ' July';
}

String fullDate(DateTime date) {
  const months = [
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
  ];
  return date.day.toString() + ' ' + months[date.month - 1] + ' ' + date.year.toString();
}
