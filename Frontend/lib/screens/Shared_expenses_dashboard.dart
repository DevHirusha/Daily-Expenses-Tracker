import 'package:flutter/material.dart';
import 'member.dart';
import 'add_expense.dart';
import 'shared_owned_budget_profile.dart';
import 'shared_with_me.dart';
import 'shared_budget_summary.dart';
import '../services/api_service.dart';

class SharedExpensesScreen extends StatefulWidget {
  final String token;
  final ValueChanged<int>? onNavigate;

  const SharedExpensesScreen({super.key, required this.token, this.onNavigate});

  @override
  State<SharedExpensesScreen> createState() => _SharedExpensesScreenState();
}

class _SharedExpensesScreenState extends State<SharedExpensesScreen> {
  bool showOwned = true;
  List<Map<String, dynamic>> budgets = const [];
  bool isLoading = true;
  double ownedTotal = 0;
  double sharedTotal = 0;
  double actualSharedTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    try {
      final loaded = await ApiService.getBudgets(token: widget.token);
      final owned = loaded.where((budget) => budget['owner'] == true).toList();
      final ownedAmount = owned.fold<double>(
        0,
        (sum, budget) => sum + ((budget['amount'] as num?)?.toDouble() ?? 0),
      );
      final sharedAmount = loaded
          .where((budget) => budget['owner'] != true)
          .fold<double>(
            0,
            (sum, budget) =>
                sum + ((budget['payableAmount'] as num?)?.toDouble() ?? 0),
          );
      final settlementLists = await Future.wait(
        owned.map(
          (budget) => ApiService.getBudgetSettlements(
            token: widget.token,
            budgetId: (budget['id'] as num).toInt(),
          ),
        ),
      );
      final actualSharedAmount = settlementLists
          .expand((settlements) => settlements)
          .where((settlement) => settlement['currentUser'] != true)
          .fold<double>(
            0,
            (sum, settlement) =>
                sum + ((settlement['amount'] as num?)?.toDouble() ?? 0),
          );
      if (!mounted) return;
      setState(() {
        budgets = loaded;
        ownedTotal = ownedAmount;
        sharedTotal = sharedAmount;
        actualSharedTotal = actualSharedAmount;
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
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              widget.onNavigate?.call(0);
            }
          },
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
              _SummaryCard(
                total: total,
                ownedTotal: ownedTotal,
                sharedTotal: sharedTotal,
                actualSharedTotal: actualSharedTotal,
              ),
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
                  _ActionTile(
                    icon: Icons.bar_chart_rounded,
                    label: 'Summary',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SharedBudgetSummaryScreen(
                          token: widget.token,
                        ),
                      ),
                    ),
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
  final double ownedTotal;
  final double sharedTotal;
  final double actualSharedTotal;

  const _SummaryCard({
    required this.total,
    required this.ownedTotal,
    required this.sharedTotal,
    required this.actualSharedTotal,
  });

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
          Text(
            'Rs ${total.toStringAsFixed(0)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          _SummaryProgressBar(
            ownedTotal: ownedTotal,
            sharedTotal: sharedTotal,
            actualSharedTotal: actualSharedTotal,
          ),
          const SizedBox(height: 10),
          Text(
            'Owned Rs ${ownedTotal.toStringAsFixed(0)} • Shared with me Rs ${sharedTotal.toStringAsFixed(0)}',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SummaryProgressBar extends StatelessWidget {
  final double ownedTotal;
  final double sharedTotal;
  final double actualSharedTotal;

  const _SummaryProgressBar({
    required this.ownedTotal,
    required this.sharedTotal,
    required this.actualSharedTotal,
  });

  @override
  Widget build(BuildContext context) {
    final combined = ownedTotal + sharedTotal;
    if (combined == 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(height: 12, color: const Color(0xFFDDE3F3)),
      );
    }
    final ownedWidth = combined == 0 ? 0.0 : ownedTotal / combined;
    final sharedWidth = combined == 0 ? 0.0 : sharedTotal / combined;
    final actualWidth = ownedTotal == 0
        ? 0.0
        : (actualSharedTotal / ownedTotal).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 12,
        child: Row(
          children: [
            Flexible(
              flex: (ownedWidth * 1000).round(),
              child: Stack(
                children: [
                  Container(color: const Color(0xFFB83A2F)),
                  FractionallySizedBox(
                    widthFactor: actualWidth,
                    child: Container(color: const Color(0xFF7D211D)),
                  ),
                ],
              ),
            ),
            Flexible(
              flex: (sharedWidth * 1000).round(),
              child: Container(color: const Color(0xFFF47C20)),
            ),
          ],
        ),
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
