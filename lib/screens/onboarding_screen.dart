import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../providers/budget_store.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.suggestedName});

  final String? suggestedName;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final TextEditingController _name;
  late final TextEditingController _income;
  late final TextEditingController _savings;
  late final TextEditingController _spending;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: widget.suggestedName == 'User' ? '' : widget.suggestedName,
    );
    _income = TextEditingController();
    _savings = TextEditingController();
    _spending = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _income.dispose();
    _savings.dispose();
    _spending.dispose();
    super.dispose();
  }

  void _finish() {
    final income = double.tryParse(_income.text.trim());
    final savings = double.tryParse(_savings.text.trim()) ?? 0;
    final spending = double.tryParse(_spending.text.trim());
    if (_name.text.trim().isEmpty ||
        income == null ||
        income <= 0 ||
        savings < 0 ||
        spending == null ||
        spending <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete each field with a valid amount.'),
        ),
      );
      return;
    }
    if (savings > income || spending > income || savings + spending > income) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Savings and spending cannot exceed your income.'),
        ),
      );
      return;
    }
    context.read<BudgetStore>().completeOnboarding(
      name: _name.text,
      income: income,
      savingsGoal: savings,
      spendingBudget: spending,
    );
  }

  void _suggestSpendingBudget(String value) {
    final income = double.tryParse(value);
    final savings = double.tryParse(_savings.text) ?? 0;
    if (income != null && income > savings) {
      _spending.text = (income - savings).toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCanvasColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 42, 28, 36),
              children: [
                const Text(
                  'Make your money feel clearer.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Answer four quick questions and we’ll set up your first budget.',
                  style: TextStyle(
                    color: kMutedColor,
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 32),
                _FieldLabel(label: 'What should we call you?'),
                _Input(
                  controller: _name,
                  hint: 'e.g. Alex',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 18),
                _FieldLabel(label: 'Average monthly take-home income'),
                _Input(
                  controller: _income,
                  hint: '0.00',
                  icon: Icons.payments_outlined,
                  currency: true,
                  onChanged: _suggestSpendingBudget,
                ),
                const SizedBox(height: 18),
                _FieldLabel(label: 'How much do you want to save each month?'),
                _Input(
                  controller: _savings,
                  hint: '0.00',
                  icon: Icons.savings_outlined,
                  currency: true,
                  onChanged: (_) => _suggestSpendingBudget(_income.text),
                ),
                const SizedBox(height: 18),
                _FieldLabel(label: 'Monthly spending limit'),
                _Input(
                  controller: _spending,
                  hint: '0.00',
                  icon: Icons.account_balance_wallet_outlined,
                  currency: true,
                ),
                const SizedBox(height: 26),
                FilledButton(
                  onPressed: _finish,
                  style: FilledButton.styleFrom(
                    backgroundColor: kPurpleColor,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Build my budget',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'You can change these settings later from Profile.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kMutedColor, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      label,
      style: const TextStyle(
        color: kMutedColor,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.hint,
    required this.icon,
    this.currency = false,
    this.onChanged,
  });
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool currency;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    keyboardType: icon == Icons.person_outline
        ? TextInputType.name
        : const TextInputType.numberWithOptions(decimal: true),
    style: const TextStyle(color: Colors.white, fontSize: 16),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: kMutedColor),
      prefixIcon: Icon(icon, color: kPurpleLightColor),
      prefixText: currency ? 'RM ' : null,
      prefixStyle: currency ? const TextStyle(color: Colors.white) : null,
      filled: true,
      fillColor: kCardBlackColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: kPurpleLightColor, width: 1.5),
      ),
    ),
  );
}
