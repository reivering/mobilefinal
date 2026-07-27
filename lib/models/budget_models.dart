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

class SavingsRecord {
  const SavingsRecord({
    required this.id,
    required this.amount,
    required this.note,
    required this.date,
  });

  final String id;
  final double amount;
  final String note;
  final DateTime date;
}
