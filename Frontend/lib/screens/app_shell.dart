import 'package:flutter/material.dart';
import 'Shared_expenses_dashboard.dart';
import 'budget_dashboard_screen.dart';
import 'find_gigs_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class AppShell extends StatefulWidget {
  final String email;
  final String token;
  final int initialIndex;

  const AppShell({
    super.key,
    required this.email,
    required this.token,
    this.initialIndex = 0,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _selectedIndex = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        email: widget.email,
        token: widget.token,
        onNavigate: _select,
      ),
      BudgetDashboardScreen(token: widget.token),
      SharedExpensesScreen(token: widget.token, onNavigate: _select),
      FindGigsScreen(token: widget.token),
      SettingsScreen(email: widget.email),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFE8ECFA),
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF294D8C),
            borderRadius: BorderRadius.circular(34),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home, label: 'Home', selected: _selectedIndex == 0, onTap: () => _select(0)),
              _NavItem(icon: Icons.account_balance_wallet, label: 'Budget dashboard', selected: _selectedIndex == 1, onTap: () => _select(1)),
              _NavItem(icon: Icons.people_alt, label: 'Shared budget', selected: _selectedIndex == 2, onTap: () => _select(2)),
              _NavItem(icon: Icons.work, label: 'Find gigs', selected: _selectedIndex == 3, onTap: () => _select(3)),
              _NavItem(icon: Icons.wb_sunny_outlined, label: 'Settings', selected: _selectedIndex == 4, onTap: () => _select(4)),
            ],
          ),
        ),
      ),
    );
  }

  void _select(int index) => setState(() => _selectedIndex = index);
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFFF8A20) : const Color(0xFFAAB9D4);
    return Semantics(
      button: true,
      label: label,
      selected: selected,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: SizedBox(
          width: 52,
          height: 54,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 5),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: selected ? 24 : 0,
                height: 3,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
