import 'package:flutter/material.dart';
import '../core/budget_helpers.dart';
import '../core/constants.dart';
import '../models/budget_models.dart';

class LedgerTile extends StatelessWidget {
  const LedgerTile({
    super.key,
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
                Text(
                  entry.title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${entry.category} · ${relativeDate(entry.date)}',
                  style: const TextStyle(
                    color: kMutedColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${entry.type == EntryType.income ? '+' : '-'}${money(entry.amount, decimals: true)}',
            style: TextStyle(
              color: entry.type == EntryType.income
                  ? kGreenColor
                  : Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: kMutedColor, size: 20),
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
