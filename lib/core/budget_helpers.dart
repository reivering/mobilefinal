import 'package:flutter/material.dart';
import 'constants.dart';

const _shortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

const _fullMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

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

Color getCategoryColor(String category) {
  switch (category) {
    case 'Bills':
      return const Color(0xFF845EC2);
    case 'Transport':
      return const Color(0xFF00C9A7);
    case 'Rent':
      return const Color(0xFFF2A33A);
    case 'Entertainment':
      return const Color(0xFF4B8FEA);
    case 'Health':
      return const Color(0xFFE15B64);
    case 'Subscription':
      return const Color(0xFFE862AC);
    case 'Food':
      return const Color(0xFF00AE67);
    case 'Phone':
      return const Color(0xFFFFC75F);
    default:
      return kPurpleLightColor;
  }
}

String money(double value, {bool decimals = false}) {
  final showDecimals = decimals || value % 1 != 0;
  return 'RM ${value.toStringAsFixed(showDecimals ? 2 : 0)}';
}

String relativeDate(DateTime date) {
  final now = DateTime.now();

  // Field comparison avoids DateTime object equality bugs
  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    return 'today';
  }

  return '${date.day} ${_shortMonths[date.month - 1]}';
}

String fullDate(DateTime date) {
  return '${date.day} ${_fullMonths[date.month - 1]} ${date.year}';
}