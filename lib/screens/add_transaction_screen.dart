import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Relative imports based on your folder structure
import '../core/budget_helpers.dart';
import '../core/constants.dart';
import '../models/budget_models.dart';
import '../providers/budget_store.dart';
import 'main_shell.dart'; // For AppFrame wrapper

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
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  List<String> get _categories => transactionCategories(_type);

  void _setType(EntryType type) {
    setState(() {
      _type = type;
      _category = _categories.first;
    });
  }

  void _save() {
    final value = double.tryParse(_amount.text.trim());
    if (value == null || value <= 0 || _note.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('add valid amount and note first')),
      );
      return;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(_date.year, _date.month, _date.day);
    if (selectedDay.isAfter(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transactions cannot be in the future.')),
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
    setState(() {
      _amount.clear();
      _note.clear();
      _type = EntryType.expense;
      _category = 'Food';
      _date = DateTime.now();
    });
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
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Add transaction',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SegmentedChoice(selected: _type, onSelected: _setType),
              const SizedBox(height: 10),
              Container(
                height: 145,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: kCardBlackColor,
                  borderRadius: BorderRadius.circular(23),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Amount',
                      style: TextStyle(color: kMutedColor, fontSize: 18),
                    ),
                    TextField(
                      controller: _amount,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 29,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        prefixText: 'RM ',
                        prefixStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 29,
                          fontWeight: FontWeight.w700,
                        ),
                        hintText: '0.00',
                        hintStyle: TextStyle(color: Colors.white38),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Category',
                style: TextStyle(
                  color: kMutedColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
              _DarkInput(
                label: 'Note',
                controller: _note,
                hint: 'What was it for?',
              ),
              const SizedBox(height: 14),
              _DatePicker(
                date: _date,
                onSelected: (date) => setState(() => _date = date),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: kPurpleColor,
                  minimumSize: const Size.fromHeight(56),
                ),
                child: const Text(
                  'Save transaction',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
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
            onTap: () => onSelected(EntryType.expense),
          ),
          _Segment(
            text: 'Income',
            active: selected == EntryType.income,
            onTap: () => onSelected(EntryType.income),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.text,
    required this.active,
    required this.onTap,
  });

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
            color: active ? kPurpleColor : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: active ? Colors.white : kMutedColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
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
                color: selected ? kPurpleColor : kCardBlackColor,
                border: Border.all(
                  color: selected ? kPurpleLightColor : Colors.transparent,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(categoryIcon(label), color: Colors.white, size: 30),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : kMutedColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
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
        Text(
          label,
          style: const TextStyle(
            color: kMutedColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: kMutedColor),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF6E3787)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: kPurpleLightColor,
                width: 1.5,
              ),
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
        const Text(
          'Date',
          style: TextStyle(
            color: kMutedColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final selected = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2020),
              lastDate: today,
            );
            if (selected != null && context.mounted) {
              onSelected(selected);
            }
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
                Text(
                  fullDate(date),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const Spacer(),
                const Icon(Icons.calendar_month_outlined, color: kMutedColor),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
