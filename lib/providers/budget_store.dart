
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/budget_models.dart';

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
  double get remaining => (monthlyBudget - totalSpent).toDouble();
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
