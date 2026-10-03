import 'package:flutter/material.dart';
import 'member.dart';
import 'add_expense.dart';
import 'shared_owned_budget_profile.dart';
import 'shared_with_me.dart';
import '../services/api_service.dart';

class SharedExpensesScreen extends StatefulWidget {
  final String token;

  const SharedExpensesScreen({super.key, required this.token});

  @override
  State<SharedExpensesScreen> createState() => _SharedExpensesScreenState();
}

class _SharedExpensesScreenState extends State<SharedExpensesScreen> {
  bool showOwned = true;
  List<Map<String, dynamic>> budgets = const [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    try {
      final loaded = await ApiService.getBudgets(token: widget.token);
      if (!mounted) return;
      setState(() {
        budgets = loaded;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleBudgets = budgets
        .where((budget) => budget['owner'] == showOwned)
        .toList();
    final total = visibleBudgets.fold<double>(
      0,
      (sum, budget) => sum + (budget['amount'] as num? ?? 0).toDouble(),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFE8ECFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8ECFA),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF172C57)),
          tooltip: 'Back',
        ),
        title: const Text(
          'Shared budgets',
          style: TextStyle(
            color: Color(0xFF172C57),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF172C57)),
            tooltip: 'Shared budget settings',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryCard(total: total),
              const SizedBox(height: 20),
              Row(
                children: [
                  _ActionTile(
                    icon: Icons.add,
                    label: 'Add expense',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddExpenseScreen(token: widget.token),
                      ),
                    ).then((_) => _loadBudgets()),
                  ),
                  const SizedBox(width: 10),
                  _ActionTile(
                    icon: Icons.people_alt_outlined,
                    label: 'Members',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MembersScreen(token: widget.token),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const _ActionTile(
                    icon: Icons.bar_chart_rounded,
                    label: 'Summary',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Shared list',
                style: TextStyle(
                  color: Color(0xFF172C57),
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 42,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9DFF2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    _Tab(
                      label: 'Owned',
                      selected: showOwned,
                      onTap: () => setState(() => showOwned = true),
                    ),
                    _Tab(
                      label: 'Shared with me',
                      selected: !showOwned,
                      onTap: () => setState(() => showOwned = false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (visibleBudgets.isEmpty)
                const _EmptyBudgets()
              else
                ...visibleBudgets.map(
                  (budget) => _BudgetTile(
                    title: budget['name']?.toString() ?? 'Budget',
                    amount: 'Rs 0 of Rs ${budget['amount']}',
                    progress: 0,
                    onTap: () {
                      final screen = showOwned
                          ? SharedOwnedBudgetProfileScreen(
                              token: widget.token,
                              budget: budget,
                            )
                          : SharedWithMeScreen(
                              token: widget.token,
                              budget: budget,
                            );
                      Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => screen),
                      ).then((changed) {
                        if (changed == true) _loadBudgets();
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double total;

  const _SummaryCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D3D73),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Combined this month',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          const Text(
            'Rs 0',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: const LinearProgressIndicator(
              value: 0,
              minHeight: 10,
              backgroundColor: Color(0xFFDDE3F3),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF47C20)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'of Rs ${total.toStringAsFixed(0)} • 0% used',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EmptyBudgets extends StatelessWidget {
  const _EmptyBudgets();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 36),
    child: Center(
      child: Text('No budgets yet', style: TextStyle(color: Color(0xFF94A3B8))),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionTile({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: const Color(0xFFFFE1C7),
                  child: Icon(icon, color: const Color(0xFFF47C20)),
                ),
                const SizedBox(height: 9),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF172C57),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? const Color(0xFF172C57)
                  : const Color(0xFF64748B),
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _BudgetTile extends StatelessWidget {
  final String title;
  final String amount;
  final double progress;
  final VoidCallback onTap;

  const _BudgetTile({
    required this.title,
    required this.amount,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      backgroundColor: const Color(0xFFDDE3F3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFF47C20),
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF172C57),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      amount,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}
