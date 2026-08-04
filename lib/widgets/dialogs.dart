import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/budget_helpers.dart';
import '../core/constants.dart';
import '../models/budget_models.dart';
import '../providers/budget_store.dart';

/// Standard Dialog for Editing Existing Transactions
Future<void> showEditEntry(BuildContext context, LedgerEntry entry) async {
  final note = TextEditingController(text: entry.title);
  final amount = TextEditingController(text: entry.amount.toString());
  var type = entry.type;
  var category = entry.category;

  if (!transactionCategories(type).contains(category)) {
    category = transactionCategories(type).first;
  }

  await showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: const Color(0xFF302035),
        title: const Text(
          'Edit transaction',
          style: TextStyle(color: Colors.white),
        ),
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: 'RM ',
                prefixStyle: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Type',
                style: TextStyle(color: kMutedColor, fontSize: 14),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _EditTypeButton(
                    label: 'Spent',
                    selected: type == EntryType.expense,
                    onTap: () => setState(() {
                      type = EntryType.expense;
                      category = transactionCategories(type).first;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _EditTypeButton(
                    label: 'Income',
                    selected: type == EntryType.income,
                    onTap: () => setState(() {
                      type = EntryType.income;
                      category = transactionCategories(type).first;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              value: category,
              dropdownColor: const Color(0xFF302035),
              isExpanded: true,
              items: transactionCategories(type)
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => category = value ?? category),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(amount.text.trim());
              if (value != null && value > 0 && note.text.trim().isNotEmpty) {
                context.read<BudgetStore>().updateEntry(
                  entry.copyWith(
                    title: note.text.trim(),
                    amount: value,
                    category: category,
                    type: type,
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

class _EditTypeButton extends StatelessWidget {
  const _EditTypeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? kPurpleColor : kCanvasColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? kPurpleLightColor : Colors.transparent,
          ),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

/// Updated Figma Bottom-Sheet Dialog for Adding & Editing Subscriptions (With Category Selection)
/// Updated Figma Bottom-Sheet Dialog with Input Validation
Future<void> showSubscriptionDialog(
  BuildContext context,
  SubscriptionProfile? current,
) async {
  final nameController = TextEditingController(text: current?.name ?? '');
  final amountController = TextEditingController(
    text: current != null ? current.amount.toStringAsFixed(2) : '',
  );

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  DateTime selectedDate =
      current?.renewalDate ?? today.add(const Duration(days: 7));
  if (selectedDate.isBefore(today)) {
    selectedDate = today;
  }

  const categories = ['Entertainment', 'Software', 'Phone', 'Bills'];
  String selectedCategory = current?.category ?? categories.first;
  if (!categories.contains(selectedCategory)) {
    selectedCategory = categories.first;
  }

  String billingCycle = 'Monthly';
  bool remindMe = true;

  // Validation States
  String? errorMessage;
  bool isNameInvalid = false;
  bool isAmountInvalid = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: kCardBlackColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        current == null
                            ? 'Add subscription'
                            : 'Edit subscription',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Name Field
                  const Text(
                    'Name',
                    style: TextStyle(color: kMutedColor, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (_) {
                      if (isNameInvalid) {
                        setState(() {
                          isNameInvalid = false;
                          errorMessage = null;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'e.g. Netflix, Spotify, Canva',
                      hintStyle: const TextStyle(color: kMutedColor),
                      filled: true,
                      fillColor: kCanvasColor,
                      prefixIcon: const Icon(
                        Icons.apps,
                        color: kPurpleLightColor,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isNameInvalid
                              ? const Color(0xFFE15B64)
                              : kPurpleColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isNameInvalid
                              ? const Color(0xFFE15B64)
                              : kPurpleColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isNameInvalid
                              ? const Color(0xFFE15B64)
                              : kPurpleLightColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Category Selector
                  const Text(
                    'Category',
                    style: TextStyle(color: kMutedColor, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: kPurpleColor,
                        backgroundColor: kCanvasColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : kMutedColor,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? kPurpleLightColor
                                : Colors.transparent,
                          ),
                        ),
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() => selectedCategory = cat);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // Amount Field
                  const Text(
                    'Amount',
                    style: TextStyle(color: kMutedColor, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    onChanged: (_) {
                      if (isAmountInvalid) {
                        setState(() {
                          isAmountInvalid = false;
                          errorMessage = null;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      prefixText: 'RM ',
                      prefixStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      filled: true,
                      fillColor: kCanvasColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isAmountInvalid
                              ? const Color(0xFFE15B64)
                              : kPurpleColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isAmountInvalid
                              ? const Color(0xFFE15B64)
                              : kPurpleColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isAmountInvalid
                              ? const Color(0xFFE15B64)
                              : kPurpleLightColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Billing Cycle Toggle
                  const Text(
                    'Billing Cycle',
                    style: TextStyle(color: kMutedColor, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 50,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: kCanvasColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => billingCycle = 'Monthly'),
                            child: Container(
                              decoration: BoxDecoration(
                                color: billingCycle == 'Monthly'
                                    ? kPurpleColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Monthly',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => billingCycle = 'Yearly'),
                            child: Container(
                              decoration: BoxDecoration(
                                color: billingCycle == 'Yearly'
                                    ? kPurpleColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Yearly',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Next Payment Date Picker
                  const Text(
                    'Next Payment Date',
                    style: TextStyle(color: kMutedColor, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose today or a future date for the next renewal.',
                    style: TextStyle(color: kMutedColor, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: today,
                        lastDate: DateTime(
                          today.year + 10,
                          today.month,
                          today.day,
                        ),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: kCanvasColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kPurpleColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            fullDate(selectedDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: kMutedColor,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Remind Me Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Remind me before renewal',
                        style: TextStyle(
                          color: kPurpleLightColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Switch(
                        value: remindMe,
                        activeThumbColor: Colors.white,
                        activeTrackColor: kPurpleColor,
                        onChanged: (val) => setState(() => remindMe = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Error Message Banner
                  if (errorMessage != null) ...[
                    Center(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFE15B64),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Save Button with Input Validation Logic
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        final textName = nameController.text.trim();
                        final valAmount =
                            double.tryParse(amountController.text.trim()) ??
                            0.0;

                        final nameEmpty = textName.isEmpty;
                        final amountInvalid = valAmount <= 0;
                        final selectedDay = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                        );

                        if (selectedDay.isBefore(today)) {
                          setState(() {
                            errorMessage =
                                'Choose today or a future renewal date';
                          });
                          return;
                        }

                        if (nameEmpty || amountInvalid) {
                          setState(() {
                            isNameInvalid = nameEmpty;
                            isAmountInvalid = amountInvalid;
                            if (nameEmpty && amountInvalid) {
                              errorMessage =
                                  'Please enter both name and amount';
                            } else if (nameEmpty) {
                              errorMessage = 'Please enter a subscription name';
                            } else {
                              errorMessage = 'Please enter a valid amount';
                            }
                          });
                          return;
                        }

                        // Save execution when valid
                        final store = context.read<BudgetStore>();
                        if (current == null) {
                          store.addSubscription(
                            name: textName,
                            amount: valAmount,
                            renewalDate: selectedDate,
                            category: selectedCategory,
                          );
                        } else {
                          store.updateSubscription(
                            current.copyWith(
                              name: textName,
                              amount: valAmount,
                              renewalDate: selectedDate,
                              category: selectedCategory,
                            ),
                          );
                        }
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPurpleColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Save Budget',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  nameController.dispose();
  amountController.dispose();
}
