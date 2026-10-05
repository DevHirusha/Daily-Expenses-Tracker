import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'Shared_expenses_dashboard.dart';
import 'add_expense.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String email;
  final String token;

  const HomeScreen({super.key, required this.email, required this.token});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _budgets = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    try {
      final budgets = await ApiService.getBudgets(token: widget.token);
      if (!mounted) return;
      setState(() {
        _budgets = budgets;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _totalBudget => _budgets.fold<double>(
        0,
        (sum, budget) => sum + ((budget['amount'] as num?)?.toDouble() ?? 0),
      );

  String get _firstName {
    final value = widget.email.split('@').first.replaceAll(RegExp(r'[._-]'), ' ');
    return value.isEmpty ? 'there' : value[0].toUpperCase() + value.substring(1);
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openAddExpense() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddExpenseScreen(token: widget.token)),
    );
    _loadBudgets();
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalBudget;
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECFA),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddExpense,
        backgroundColor: const Color(0xFFF47C20),
        foregroundColor: Colors.white,
        tooltip: 'Add expense',
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadBudgets,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 88),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(name: _firstName, onLogout: _logout),
                const SizedBox(height: 12),
                _BudgetHero(
                  total: total,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 8),
                const _TodayCard(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.add,
                        label: 'Quick expense',
                        onTap: _openAddExpense,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.people_alt_outlined,
                        label: 'Shared budgets',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SharedExpensesScreen(token: widget.token),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Expanded(
                      child: _QuickAction(icon: Icons.bar_chart_rounded, label: 'Find gigs'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const _CategoryCard(),
                const SizedBox(height: 8),
                _QuickAdd(onTap: _openAddExpense),
                const SizedBox(height: 8),
                const _RecentCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  final VoidCallback onLogout;

  const _Header({required this.name, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Good morning, $name',
            style: const TextStyle(
              color: Color(0xFF172C57),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: onLogout,
          icon: const Icon(Icons.notifications_none, color: Color(0xFF172C57), size: 19),
          tooltip: 'Notifications',
        ),
        IconButton(
          onPressed: onLogout,
          icon: const Icon(Icons.logout, color: Color(0xFF172C57), size: 18),
          tooltip: 'Logout',
        ),
      ],
    );
  }
}

class _BudgetHero extends StatelessWidget {
  final double total;
  final bool isLoading;

  const _BudgetHero({required this.total, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        color: const Color(0xFF1D3D73),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Family budget · This month', style: TextStyle(color: Colors.white70, fontSize: 9)),
          const SizedBox(height: 4),
          Text(
            isLoading ? 'Loading...' : 'Rs ${total.toStringAsFixed(0)} left',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              value: 0,
              minHeight: 4,
              backgroundColor: Color(0xFFDDE3F3),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF47C20)),
            ),
          ),
          const SizedBox(height: 6),
          Text('Rs 0 used of Rs ${total.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70, fontSize: 9)),
          const SizedBox(height: 2),
          const Text('This month', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's spending", style: TextStyle(color: Color(0xFF7890B8), fontSize: 8)),
          SizedBox(height: 3),
          Text('Rs 0', style: TextStyle(color: Color(0xFF172C57), fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickAction({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF1E5),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 3),
          child: Column(
            children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: const Color(0xFFFFD7B5),
                child: Icon(icon, color: const Color(0xFFF47C20), size: 13),
              ),
              const SizedBox(height: 5),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF172C57), fontSize: 8, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'By category',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Container(height: 5, color: const Color(0xFFF47C20))),
              Expanded(child: Container(height: 5, color: const Color(0xFF172C57))),
              Expanded(child: Container(height: 5, color: const Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 5),
          const _CategoryLine(color: Color(0xFFF47C20), name: 'Food', percent: '55%'),
          const _CategoryLine(color: Color(0xFF172C57), name: 'Transport', percent: '20%'),
          const _CategoryLine(color: Color(0xFF64748B), name: 'Bills', percent: '25%'),
        ],
      ),
    );
  }
}

class _CategoryLine extends StatelessWidget {
  final Color color;
  final String name;
  final String percent;

  const _CategoryLine({required this.color, required this.name, required this.percent});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Expanded(child: Text(name, style: const TextStyle(color: Color(0xFF172C57), fontSize: 8))),
          Text(percent, style: const TextStyle(color: Color(0xFF172C57), fontSize: 8, fontWeight: FontWeight.bold)),
        ],
      );
}

class _QuickAdd extends StatelessWidget {
  final VoidCallback onTap;
  const _QuickAdd({required this.onTap});

  @override
  Widget build(BuildContext context) => _SectionCard(
        title: 'Quick add',
        child: Row(
          children: [
            _ChipButton(icon: Icons.restaurant, label: 'Food', onTap: onTap),
            _ChipButton(icon: Icons.directions_bus, label: 'Transport', onTap: onTap),
            _ChipButton(icon: Icons.receipt_long, label: 'Bills', onTap: onTap),
            const Spacer(),
            IconButton(onPressed: onTap, icon: const Icon(Icons.chevron_right, size: 16), color: const Color(0xFF7890B8), tooltip: 'Add expense'),
          ],
        ),
      );
}

class _ChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ChipButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 5),
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 10),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF172C57),
            side: const BorderSide(color: Color(0xFFF47C20)),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(fontSize: 8),
          ),
        ),
      );
}

class _RecentCard extends StatelessWidget {
  const _RecentCard();

  @override
  Widget build(BuildContext context) => _SectionCard(
        title: 'Recent',
        child: Column(
          children: const [
            _RecentLine(icon: Icons.restaurant, title: 'Lunch', category: 'Food', amount: '-450'),
            _RecentLine(icon: Icons.directions_bus, title: 'Bus fare', category: 'Transport', amount: '-80'),
            _RecentLine(icon: Icons.wifi, title: 'Data plan', category: 'Bills', amount: '-1,200'),
          ],
        ),
      );
}

class _RecentLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String category;
  final String amount;

  const _RecentLine({required this.icon, required this.title, required this.category, required this.amount});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            CircleAvatar(radius: 12, backgroundColor: const Color(0xFFE8ECFA), child: Icon(icon, size: 13, color: const Color(0xFF5A8DEE))),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Color(0xFF172C57), fontSize: 9, fontWeight: FontWeight.w600)),
              Text(category, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8)),
            ])),
            Text(amount, style: const TextStyle(color: Color(0xFF172C57), fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
      );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Color(0xFF172C57), fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 7),
          child,
        ]),
      );
}
