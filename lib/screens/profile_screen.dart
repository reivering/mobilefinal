import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../providers/budget_store.dart';
import 'main_shell.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.onNavigate,
    required this.onSignOut,
    required this.userName,
    this.userEmail,
  });

  final ValueChanged<int> onNavigate;
  final Future<void> Function()? onSignOut;
  final String userName;
  final String? userEmail;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BudgetStore>();
    final displayName = userName.trim().isEmpty ? 'User' : userName.trim();
    final initials = displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return AppFrame(
      selectedPage: 4,
      onNavigate: onNavigate,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(31, 25, 31, 32),
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: kCardBlackColor,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: kPurpleColor,
                      child: Text(
                        initials.isEmpty ? 'U' : initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userEmail?.trim().isNotEmpty == true
                                ? userEmail!.trim()
                                : 'Signed in with Clerk',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: kMutedColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Monthly savings goal  ·  ${store.monthlySavingsGoal > 0 ? 'RM ${store.monthlySavingsGoal.toStringAsFixed(2)}' : 'Not set'}',
                style: const TextStyle(color: kMutedColor, fontSize: 14),
              ),
              const SizedBox(height: 18),
              _ProfileAction(
                icon: Icons.account_circle_outlined,
                label: 'Account details',
                subtitle: 'Your personal budget profile',
                onTap: () => _editProfile(context, displayName),
              ),
              const SizedBox(height: 12),
              _ProfileAction(
                icon: Icons.logout_rounded,
                label: 'Log out',
                subtitle: 'Sign out of this device',
                destructive: true,
                onTap: onSignOut == null ? null : () => _confirmSignOut(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editProfile(BuildContext context, String currentName) async {
    final store = context.read<BudgetStore>();
    final name = TextEditingController(text: currentName == 'User' ? '' : currentName);
    final budget = TextEditingController(text: store.monthlyBudget.toStringAsFixed(2));
    final savings = TextEditingController(text: store.monthlySavingsGoal.toStringAsFixed(2));
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCardBlackColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(sheetContext).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit profile', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            TextField(controller: name, autofocus: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Display name', hintText: 'Your name')),
            const SizedBox(height: 14),
            TextField(controller: budget, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Monthly budget', prefixText: 'RM ')),
            const SizedBox(height: 14),
            TextField(controller: savings, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Monthly savings goal', prefixText: 'RM ')),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(budget.text.trim());
                final savingsValue = double.tryParse(savings.text.trim());
                if (value == null || value <= 0 || savingsValue == null || savingsValue < 0) return;
                store.updateProfile(name: name.text, budget: value, savingsGoal: savingsValue);
                Navigator.pop(sheetContext);
              },
              style: FilledButton.styleFrom(backgroundColor: kPurpleColor, minimumSize: const Size.fromHeight(52)),
              child: const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    budget.dispose();
    savings.dispose();
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can sign back in anytime.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log out')),
        ],
      ),
    );
    if (shouldSignOut == true && context.mounted) await onSignOut!();
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFE26B76) : Colors.white;
    return Material(
      color: kCardBlackColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Icon(icon, color: destructive ? color : kPurpleLightColor, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: const TextStyle(color: kMutedColor, fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: .7)),
            ],
          ),
        ),
      ),
    );
  }
}
