import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'Shared_expenses_dashboard.dart';
import 'find_gigs_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String email;
  final String token;
  final ValueChanged<int>? onNavigate;

  const HomeScreen({
    super.key,
    required this.email,
    required this.token,
    this.onNavigate,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _budgets = const [];
  List<_HomeCategorySummary> _todayCategories = const [];
  double _todaySpent = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    try {
      final budgets = await ApiService.getBudgets(token: widget.token);
      var todayCategories = _defaultHomeCategories();
      var todaySpent = 0.0;
      final ownedBudgets = budgets
          .where((item) => item['owner'] == true)
          .toList();
      if (ownedBudgets.isNotEmpty) {
        final budgetId = (ownedBudgets.first['id'] as num).toInt();
        final today = DateTime.now();
        final categories = await ApiService.getBudgetCategories(
          token: widget.token,
          budgetId: budgetId,
        );
        final expenses = await ApiService.getExpenses(
          token: widget.token,
          budgetId: budgetId,
          start: today,
          end: today,
        );
        final spendingByCategory = <int, double>{};
        for (final expense in expenses) {
          final categoryId = (expense['categoryId'] as num?)?.toInt();
          if (categoryId == null) continue;
          final amount = (expense['amount'] as num?)?.toDouble() ?? 0;
          spendingByCategory[categoryId] =
              (spendingByCategory[categoryId] ?? 0) + amount;
          todaySpent += amount;
        }
        final groupedCategories = <String, _HomeCategorySummary>{};
        for (final category in categories) {
          final categoryId = (category['id'] as num?)?.toInt() ?? 0;
          final name = category['name']?.toString() ?? 'Category';
          final displayName = _displayCategoryName(name);
          final existing = groupedCategories[displayName];
          groupedCategories[displayName] = _HomeCategorySummary(
            name: displayName,
            amount:
                (existing?.amount ?? 0) + (spendingByCategory[categoryId] ?? 0),
            limit:
                (existing?.limit ?? 0) +
                ((category['limitAmount'] as num?)?.toDouble() ?? 0),
            color: existing?.color ?? _categoryColor(name),
          );
        }
        if (groupedCategories.isNotEmpty) {
          todayCategories = _defaultHomeCategories().map((defaultCategory) {
            final loaded = groupedCategories[defaultCategory.name];
            return _HomeCategorySummary(
              name: defaultCategory.name,
              amount: loaded?.amount ?? 0,
              limit: loaded?.limit ?? 0,
              color: defaultCategory.color,
            );
          }).toList();
        }
      }
      if (!mounted) return;
      setState(() {
        _budgets = budgets;
        _todayCategories = todayCategories;
        _todaySpent = todaySpent;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _displayCategoryName(String name) {
    final value = name.toLowerCase();
    if (value.contains('eating') || value.contains('food')) return 'Food';
    if (value.contains('grocery')) return 'Groceries';
    return name;
  }

  List<_HomeCategorySummary> _defaultHomeCategories() => const [
    _HomeCategorySummary(
      name: 'Food',
      amount: 0,
      limit: 0,
      color: Color(0xFFF47C20),
    ),
    _HomeCategorySummary(
      name: 'Transport',
      amount: 0,
      limit: 0,
      color: Color(0xFF5A8DEE),
    ),
    _HomeCategorySummary(
      name: 'Bills',
      amount: 0,
      limit: 0,
      color: Color(0xFF8B5CF6),
    ),
    _HomeCategorySummary(
      name: 'Groceries',
      amount: 0,
      limit: 0,
      color: Color(0xFF2CA879),
    ),
  ];

  Color _categoryColor(String name) {
    final value = name.toLowerCase();
    if (value.contains('transport')) return const Color(0xFF5A8DEE);
    if (value.contains('bill')) return const Color(0xFF8B5CF6);
    if (value.contains('grocery')) return const Color(0xFF2CA879);
    return const Color(0xFFF47C20);
  }

  double get _totalBudget => _budgets.fold<double>(
    0,
    (sum, budget) => sum + ((budget['amount'] as num?)?.toDouble() ?? 0),
  );

  String get _firstName {
    final value = widget.email
        .split('@')
        .first
        .replaceAll(RegExp(r'[._-]'), ' ');
    return value.isEmpty
        ? 'there'
        : value[0].toUpperCase() + value.substring(1);
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openQuickExpense([String? quickCategory]) async {
    try {
      var budgets = await ApiService.getBudgets(token: widget.token);
      Map<String, dynamic> budget;
      final ownedBudgets = budgets
          .where((item) => item['owner'] == true)
          .toList();
      if (ownedBudgets.isEmpty && budgets.isEmpty) {
        final now = DateTime.now();
        budget = await ApiService.createBudget(
          token: widget.token,
          name: '${_monthName(now.month)} budget',
          amount: 60000,
          startDate: DateTime(now.year, now.month, 1),
          endDate: DateTime(now.year, now.month + 1, 0),
          memberUserIds: const [],
        );
      } else if (ownedBudgets.isNotEmpty) {
        budget = ownedBudgets.first;
      } else {
        throw Exception('Create a personal budget before adding an expense.');
      }
      final budgetId = (budget['id'] as num).toInt();
      final categories = await ApiService.getBudgetCategories(
        token: widget.token,
        budgetId: budgetId,
      );
      Map<String, dynamic>? lockedCategory;
      if (quickCategory != null) {
        final requested = quickCategory.toLowerCase();
        for (final category in categories) {
          final name = category['name']?.toString().toLowerCase() ?? '';
          final matches = requested == 'food'
              ? name.contains('eating') || name.contains('food')
              : name.contains(requested);
          if (matches) {
            lockedCategory = category;
            break;
          }
        }
        if (lockedCategory == null) {
          throw Exception(
            '$quickCategory category is not available in this budget.',
          );
        }
      }
      if (!mounted) return;
      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _QuickExpenseDialog(
          token: widget.token,
          budgetId: budgetId,
          categories: categories,
          lockedCategoryId: (lockedCategory?['id'] as num?)?.toInt(),
          lockedCategoryName: lockedCategory?['name']?.toString(),
        ),
      );
      if (saved == true && mounted) {
        await _loadBudgets();
        _showMessage('Expense saved successfully.');
      }
    } catch (error) {
      if (mounted)
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalBudget;
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECFA),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openQuickExpense(),
        backgroundColor: const Color(0xFFF47C20),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 8,
        tooltip: 'Add expense',
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadBudgets,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 92),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(name: _firstName, onLogout: _logout),
                const SizedBox(height: 12),
                _BudgetHero(total: total, isLoading: _isLoading),
                const SizedBox(height: 8),
                _TodayCard(amount: _todaySpent),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1E5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.add,
                          label: 'Quick expense',
                          onTap: () => _openQuickExpense(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.people_alt_outlined,
                          label: 'Shared budgets',
                          onTap: widget.onNavigate == null
                              ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SharedExpensesScreen(
                                      token: widget.token,
                                    ),
                                  ),
                                )
                              : () => widget.onNavigate!(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.bar_chart_rounded,
                          label: 'Find gigs',
                          onTap: widget.onNavigate == null
                              ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FindGigsScreen(token: widget.token),
                                  ),
                                )
                              : () => widget.onNavigate!(3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _CategoryCard(categories: _todayCategories),
                const SizedBox(height: 8),
                _QuickAdd(onTap: _openQuickExpense),
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

class _QuickExpenseDialog extends StatefulWidget {
  final String token;
  final int budgetId;
  final List<Map<String, dynamic>> categories;
  final int? lockedCategoryId;
  final String? lockedCategoryName;

  const _QuickExpenseDialog({
    required this.token,
    required this.budgetId,
    required this.categories,
    this.lockedCategoryId,
    this.lockedCategoryName,
  });

  @override
  State<_QuickExpenseDialog> createState() => _QuickExpenseDialogState();
}

class _QuickExpenseDialogState extends State<_QuickExpenseDialog> {
  final _amountController = TextEditingController();
  int? _selectedCategoryId;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId =
        widget.lockedCategoryId ??
        (widget.categories.isNotEmpty
            ? (widget.categories.first['id'] as num?)?.toInt()
            : null);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _categoryName(Map<String, dynamic> category) =>
      category['name']?.toString() ?? 'Category';

  Future<void> _save() async {
    final amount = double.tryParse(
      _amountController.text.replaceAll(',', '').trim(),
    );
    if (_selectedCategoryId == null) {
      setState(() => _error = 'Choose a category.');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter an amount greater than zero.');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final category = widget.categories.firstWhere(
      (item) => (item['id'] as num?)?.toInt() == _selectedCategoryId,
      orElse: () => widget.categories.first,
    );
    try {
      await ApiService.createExpense(
        token: widget.token,
        budgetId: widget.budgetId,
        categoryId: _selectedCategoryId!,
        name: '${_categoryName(category)} expense',
        amount: amount,
        expenseDate: DateTime.now(),
        source: 'Quick expense',
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quick expense'),
      content: widget.categories.isEmpty
          ? const Text('No budget categories are available yet.')
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.lockedCategoryId != null) ...[
                    const Text(
                      'Category',
                      style: TextStyle(color: Color(0xFF7890B8), fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8ECFA),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFF47C20)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: Color(0xFFF47C20),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.lockedCategoryName ?? 'Category',
                              style: const TextStyle(
                                color: Color(0xFF172C57),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Text(
                            'Selected',
                            style: TextStyle(
                              color: Color(0xFF7890B8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Choose category',
                      style: TextStyle(color: Color(0xFF7890B8), fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedCategoryId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: widget.categories
                          .map(
                            (category) => DropdownMenuItem<int>(
                              value: (category['id'] as num?)?.toInt(),
                              child: Text(_categoryName(category)),
                            ),
                          )
                          .toList(),
                      onChanged: _isSaving
                          ? null
                          : (value) =>
                                setState(() => _selectedCategoryId = value),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Text(
                    'Amount',
                    style: TextStyle(color: Color(0xFF7890B8), fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _amountController,
                    autofocus: true,
                    enabled: !_isSaving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      prefixText: 'Rs ',
                      hintText: '0.00',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving || widget.categories.isEmpty ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save expense'),
        ),
      ],
    );
  }
}

class _HomeCategorySummary {
  final String name;
  final double amount;
  final double limit;
  final Color color;

  const _HomeCategorySummary({
    required this.name,
    required this.amount,
    required this.limit,
    required this.color,
  });
}

class _Header extends StatelessWidget {
  final String name;
  final VoidCallback onLogout;

  const _Header({required this.name, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              'Good morning, $name',
              style: const TextStyle(
                color: Color(0xFF172C57),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onLogout,
          icon: const Icon(
            Icons.notifications_none,
            color: Color(0xFF172C57),
            size: 21,
          ),
          tooltip: 'Notifications',
        ),
        IconButton(
          onPressed: onLogout,
          icon: const Icon(Icons.logout, color: Color(0xFF172C57), size: 19),
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
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D3D73),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172C57).withOpacity(.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Family budget · This month',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            isLoading ? 'Loading...' : 'Rs ${total.toStringAsFixed(0)} left',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              value: 0,
              minHeight: 7,
              backgroundColor: Color(0xFFDDE3F3),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF47C20)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rs 0 used of Rs ${total.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 3),
          const Text(
            'This month',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final double amount;

  const _TodayCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172C57).withOpacity(.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's spending",
            style: TextStyle(color: Color(0xFF7890B8), fontSize: 10),
          ),
          SizedBox(height: 4),
          Text(
            'Rs ${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Color(0xFF172C57),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 4),
          child: Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFFFFD7B5),
                child: Icon(icon, color: const Color(0xFFF47C20), size: 17),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF172C57),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final List<_HomeCategorySummary> categories;

  const _CategoryCard({required this.categories});

  @override
  Widget build(BuildContext context) {
    final total = categories.fold<double>(
      0,
      (sum, category) => sum + category.amount,
    );
    return _SectionCard(
      title: 'By category',
      child: categories.isEmpty
          ? const Text(
              'No expenses recorded today.',
              style: TextStyle(color: Color(0xFF7890B8), fontSize: 11),
            )
          : Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: categories.map((category) {
                      final share = total == 0 ? 0.0 : category.amount / total;
                      return Expanded(
                        flex: (share * 1000).round().clamp(1, 1000).toInt(),
                        child: Container(height: 8, color: category.color),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                ...categories.map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CategoryLine(category: category, total: total),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CategoryLine extends StatelessWidget {
  final _HomeCategorySummary category;
  final double total;

  const _CategoryLine({required this.category, required this.total});

  @override
  Widget build(BuildContext context) {
    final share = total <= 0 ? 0 : (category.amount / total * 100).round();
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: category.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                category.name,
                style: const TextStyle(color: Color(0xFF172C57), fontSize: 11),
              ),
            ),
            Text(
              'Rs ${category.amount.toStringAsFixed(0)}  $share%',
              style: const TextStyle(
                color: Color(0xFF172C57),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickAdd extends StatelessWidget {
  final ValueChanged<String> onTap;
  const _QuickAdd({required this.onTap});

  @override
  Widget build(BuildContext context) => _SectionCard(
    title: 'Quick add',
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _QuickCategoryButton(
          icon: Icons.restaurant_rounded,
          label: 'Food',
          color: const Color(0xFFF47C20),
          onTap: () => onTap('Food'),
        ),
        _QuickCategoryButton(
          icon: Icons.directions_bus_rounded,
          label: 'Transport',
          color: const Color(0xFF5A8DEE),
          onTap: () => onTap('Transport'),
        ),
        _QuickCategoryButton(
          icon: Icons.receipt_long_rounded,
          label: 'Bills',
          color: const Color(0xFF8B5CF6),
          onTap: () => onTap('Bills'),
        ),
        _QuickCategoryButton(
          icon: Icons.shopping_basket_rounded,
          label: 'Groceries',
          color: const Color(0xFF2CA879),
          onTap: () => onTap('Groceries'),
        ),
      ],
    ),
  );
}

class _QuickCategoryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickCategoryButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: color.withValues(alpha: .10),
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 15),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF172C57),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
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
        _RecentLine(
          icon: Icons.restaurant,
          title: 'Lunch',
          category: 'Food',
          amount: '-450',
        ),
        _RecentLine(
          icon: Icons.directions_bus,
          title: 'Bus fare',
          category: 'Transport',
          amount: '-80',
        ),
        _RecentLine(
          icon: Icons.wifi,
          title: 'Data plan',
          category: 'Bills',
          amount: '-1,200',
        ),
      ],
    ),
  );
}

class _RecentLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String category;
  final String amount;

  const _RecentLine({
    required this.icon,
    required this.title,
    required this.category,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFE8ECFA),
          child: Icon(icon, size: 17, color: const Color(0xFF5A8DEE)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF172C57),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                category,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            color: Color(0xFF172C57),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
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
    padding: const EdgeInsets.fromLTRB(18, 17, 18, 17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF172C57).withOpacity(.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
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
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}
