
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/budget_models.dart';

class BudgetStore extends ChangeNotifier {
  Box<dynamic>? _box;
  String _scope = 'guest';
  String? _profileName;

  double _monthlyBudget = 800;
  double _monthlySavingsGoal = 0;
  bool _onboardingComplete = false;
  final List<LedgerEntry> _entries = [];
  final List<SubscriptionProfile> _subscriptions = [];
  final List<SavingsRecord> _savings = [];

  double get monthlyBudget => _monthlyBudget;
  double get monthlySavingsGoal => _monthlySavingsGoal;
  bool get onboardingComplete => _onboardingComplete;
  String? get profileName => _profileName;

  List<LedgerEntry> get entries =>
      List.unmodifiable(_entries..sort((a, b) => b.date.compareTo(a.date)));
  List<LedgerEntry> get expenses =>
      entries.where((entry) => entry.type == EntryType.expense).toList();
  List<SubscriptionProfile> get subscriptions => List.unmodifiable(_subscriptions);
  List<SavingsRecord> get savingsRecords =>
      List.unmodifiable(_savings..sort((a, b) => b.date.compareTo(a.date)));

  double get totalSpent =>
      expenses.fold(0.0, (sum, entry) => sum + entry.amount) +
      subscriptions.fold(0.0, (sum, subscription) => sum + subscription.amount);
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
    for (final subscription in subscriptions) {
      totals.update(subscription.category, (value) => value + subscription.amount,
          ifAbsent: () => subscription.amount);
    }
    return totals;
  }

  Map<DateTime, double> get monthlySavings {
    final now = DateTime.now();
    final result = <DateTime, double>{};
    for (var offset = 0; offset < 6; offset++) {
      final month = DateTime(now.year, now.month - offset);
      result[month] = savingsRecords
          .where((record) => _sameMonth(record.date, month))
          .fold(0.0, (sum, record) => sum + record.amount);
    }
    return result;
  }

  double get currentSavings => monthlySavings.values.first;

  bool _sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

  void addSavings({
    required double amount,
    required String note,
    required DateTime date,
  }) {
    _savings.add(SavingsRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      amount: amount,
      note: note,
      date: date,
    ));
    _persist();
    notifyListeners();
  }

  void deleteSavings(String id) {
    _savings.removeWhere((record) => record.id == id);
    _persist();
    notifyListeners();
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
    // Drop the old demo records once. New installs and existing demo installs
    // both start with a genuinely empty, user-owned budget.
    if (_box?.get('schemaVersion') == null) {
      await _box?.delete('entries');
      await _box?.delete('subscriptions');
      await _box?.put('schemaVersion', 2);
    }
    _restore();
  }

  Future<void> activateUser(String userId) async {
    final nextScope = userId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    if (_scope == nextScope && _box?.get('activeScope') == nextScope) return;
    _scope = nextScope;
    _entries.clear();
    _subscriptions.clear();
    _savings.clear();
    _profileName = null;
    _monthlyBudget = 800;
    _monthlySavingsGoal = 0;
    _onboardingComplete = false;
    _restore();
    await _box?.put('activeScope', _scope);
    notifyListeners();
  }

  void updateProfile({
    required String name,
    required double budget,
    double? savingsGoal,
  }) {
    _profileName = name.trim().isEmpty ? null : name.trim();
    _monthlyBudget = budget > 0 ? budget : 800;
    if (savingsGoal != null && savingsGoal >= 0) {
      _monthlySavingsGoal = savingsGoal;
    }
    _persist();
    notifyListeners();
  }

  void completeOnboarding({
    required String name,
    required double income,
    required double savingsGoal,
    required double spendingBudget,
  }) {
    _profileName = name.trim();
    _monthlyBudget = spendingBudget;
    _monthlySavingsGoal = savingsGoal;
    _onboardingComplete = true;
    _entries.removeWhere((entry) => entry.id == 'onboarding-income');
    _entries.add(
      LedgerEntry(
        id: 'onboarding-income',
        title: 'Monthly income',
        amount: income,
        category: 'Salary',
        date: DateTime.now(),
        type: EntryType.income,
      ),
    );
    _savings.removeWhere((record) => record.id == 'onboarding-savings');
    if (savingsGoal > 0) {
      _savings.add(
        SavingsRecord(
          id: 'onboarding-savings',
          amount: savingsGoal,
          note: 'Initial savings',
          date: DateTime.now(),
        ),
      );
    }
    _persist();
    notifyListeners();
  }

  String get _entriesKey => 'entries:$_scope';
  String get _subscriptionsKey => 'subscriptions:$_scope';
  String get _profileNameKey => 'profileName:$_scope';
  String get _monthlyBudgetKey => 'monthlyBudget:$_scope';

  void _restore() {
    final savedEntries = _box?.get(_entriesKey);
    if (savedEntries is List && savedEntries.isNotEmpty) {
      _entries
        ..clear()
        ..addAll(
          savedEntries
              .whereType<Map>()
              .map((item) => _entryFromMap(Map<String, dynamic>.from(item))),
        );
    }

    final savedSubscriptions = _box?.get(_subscriptionsKey);
    if (savedSubscriptions is List && savedSubscriptions.isNotEmpty) {
      _subscriptions
        ..clear()
        ..addAll(
          savedSubscriptions
              .whereType<Map>()
              .map((item) => _subscriptionFromMap(Map<String, dynamic>.from(item))),
        );
    }

    final savedSavings = _box?.get('savings:$_scope');
    if (savedSavings is List && savedSavings.isNotEmpty) {
      _savings
        ..clear()
        ..addAll(
          savedSavings
              .whereType<Map>()
              .map((item) => _savingsFromMap(Map<String, dynamic>.from(item))),
        );
    }

    _profileName = _box?.get(_profileNameKey) as String?;
    final savedBudget = _box?.get(_monthlyBudgetKey);
    if (savedBudget is num && savedBudget > 0) {
      _monthlyBudget = savedBudget.toDouble();
    }
    final savedSavingsGoal = _box?.get('savingsGoal:$_scope');
    if (savedSavingsGoal is num && savedSavingsGoal >= 0) {
      _monthlySavingsGoal = savedSavingsGoal.toDouble();
    }
    _onboardingComplete = _box?.get('onboardingComplete:$_scope') == true;
    // Migrate the amount entered during onboarding into an actual savings
    // record so it remains visible after switching to explicit transfers.
    if (_onboardingComplete && _savings.isEmpty && _monthlySavingsGoal > 0) {
      _savings.add(
        SavingsRecord(
          id: 'onboarding-savings',
          amount: _monthlySavingsGoal,
          note: 'Initial savings',
          date: DateTime.now(),
        ),
      );
      _persist();
    }
  }

  void _persist() {
    final box = _box;
    if (box == null) return;
    box.put(_entriesKey, _entries.map(_entryToMap).toList());
    box.put(_subscriptionsKey, _subscriptions.map(_subscriptionToMap).toList());
    box.put(_profileNameKey, _profileName);
    box.put(_monthlyBudgetKey, _monthlyBudget);
    box.put('savings:$_scope', _savings.map(_savingsToMap).toList());
    box.put('savingsGoal:$_scope', _monthlySavingsGoal);
    box.put('onboardingComplete:$_scope', _onboardingComplete);
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

  Map<String, dynamic> _savingsToMap(SavingsRecord record) => {
        'id': record.id,
        'amount': record.amount,
        'note': record.note,
        'date': record.date.toIso8601String(),
      };

  SavingsRecord _savingsFromMap(Map<String, dynamic> item) => SavingsRecord(
        id: item['id'] as String,
        amount: (item['amount'] as num).toDouble(),
        note: item['note'] as String,
        date: DateTime.parse(item['date'] as String),
      );
}
