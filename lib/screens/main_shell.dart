import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'add_transaction_screen.dart';
import 'home_screen.dart';
import 'insights_screen.dart';
import 'subscriptions_screen.dart';

class BudgetShell extends StatefulWidget {
  const BudgetShell({super.key});

  @override
  State<BudgetShell> createState() => _BudgetShellState();
}

class _BudgetShellState extends State<BudgetShell> {
  int _page = 0;

  void _goTo(int page) {
    setState(() => _page = page);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onNavigate: _goTo),
      AddTransactionScreen(onNavigate: _goTo),
      SubscriptionsScreen(onNavigate: _goTo),
      InsightsScreen(onNavigate: _goTo),
    ];
    return IndexedStack(
      index: _page,
      children: pages,
    );
  }
}

class AppFrame extends StatelessWidget {
  const AppFrame({
    super.key,
    required this.selectedPage,
    required this.onNavigate,
    required this.child,
  });

  final int selectedPage;
  final ValueChanged<int> onNavigate;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kDeepPurpleColor, kCanvasColor],
            stops: [0.2, 1],
          ),
        ),
        child: SafeArea(child: child),
      ),
      bottomNavigationBar: _BottomBar(
        selectedPage: selectedPage,
        onNavigate: onNavigate,
      ),
    );
  }
}


class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.selectedPage, required this.onNavigate});

  final int selectedPage;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 87,
      color: kCanvasColor,
      padding: const EdgeInsets.fromLTRB(31, 5, 31, 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavIcon(
              icon: Icons.home_outlined,
              active: selectedPage == 0,
              onTap: () => onNavigate(0)),
          _NavIcon(
              icon: Icons.add,
              active: selectedPage == 1,
              isAdd: true,
              onTap: () => onNavigate(1)),
          _NavIcon(
              icon: Icons.sync,
              active: selectedPage == 2,
              onTap: () => onNavigate(2)),
          _NavIcon(
              icon: Icons.bar_chart_rounded,
              active: selectedPage == 3,
              onTap: () => onNavigate(3)),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.active,
    required this.onTap,
    this.isAdd = false,
  });

  final IconData icon;
  final bool active;
  final bool isAdd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (isAdd) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 50,
          width: 50,
          decoration:
              const BoxDecoration(color: kPurpleColor, shape: BoxShape.circle),
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      );
    }
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 30),
      color: active ? Colors.white: kPurpleLightColor,
    );
  }
}