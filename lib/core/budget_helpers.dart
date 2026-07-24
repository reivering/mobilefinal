import 'package:flutter/material.dart';

IconData categoryIcon(String category) {
  switch (category) {
    case 'Food':
      return Icons.restaurant_outlined;
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
