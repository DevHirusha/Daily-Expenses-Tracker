import 'package:flutter/material.dart';
import '../services/api_service.dart';

const _background = Color(0xFFE8ECFA);
const _navy = Color(0xFF172C57);
const _navyLight = Color(0xFF294D8C);
const _orange = Color(0xFFF47C20);
const _orangeSoft = Color(0xFFFFEBD8);
const _green = Color(0xFF2CA879);
const _muted = Color(0xFF7890B8);

class BudgetDashboardScreen extends StatefulWidget {
  final String token;

  const BudgetDashboardScreen({super.key, required this.token});

  @override
  State<BudgetDashboardScreen> createState() => _BudgetDashboardScreenState();
}

class _BudgetDashboardScreenState extends State<BudgetDashboardScreen> {
  double _monthlyBudget = 60000;
  int _warningThreshold = 80;
  int? _budgetId;
  String _budgetName = 'Budget';
  bool _isLoading = true;
  String? _loadError;

  List<_BudgetCategory> _categories = const [
    _BudgetCategory(
      name: 'Eating out',
      spent: 10800,
      limit: 9000,
      icon: Icons.restaurant_outlined,
      color: _orange,
    ),
    _BudgetCategory(
      name: 'Transport',
      spent: 7040,
      limit: 8000,
      icon: Icons.directions_car_outlined,
      color: Color(0xFF5A8DEE),
    ),
    _BudgetCategory(
      name: 'Groceries',
      spent: 14800,
      limit: 20000,
      icon: Icons.shopping_basket_outlined,
      color: _green,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      var budgets = await ApiService.getBudgets(token: widget.token);
      late final Map<String, dynamic> budget;
      if (budgets.isEmpty) {
        final now = DateTime.now();
        budget = await ApiService.createBudget(
          token: widget.token,
          name: _monthName(now.month),
          amount: _monthlyBudget,
          startDate: DateTime(now.year, now.month, 1),
          endDate: DateTime(now.year, now.month + 1, 0),
          memberUserIds: const [],
        );
      } else {
        budget = budgets.firstWhere(
          (item) => item['owner'] == true,
          orElse: () => budgets.first,
        );
      }
      final budgetId = (budget['id'] as num).toInt();
      final categories = await ApiService.getBudgetCategories(
        token: widget.token,
        budgetId: budgetId,
      );
      final expenses = await ApiService.getExpenses(
        token: widget.token,
        budgetId: budgetId,
      );
      final spentByCategory = <int, double>{};
      for (final expense in expenses) {
        final categoryId = (expense['categoryId'] as num?)?.toInt();
        if (categoryId == null) continue;
        final amount = (expense['amount'] as num?)?.toDouble() ?? 0;
        spentByCategory[categoryId] =
            (spentByCategory[categoryId] ?? 0) + amount;
      }
      final loadedCategories = categories.map((category) {
        final categoryId = (category['id'] as num?)?.toInt();
        return _BudgetCategory.fromJson(
          category,
          spentOverride: categoryId == null
              ? null
              : spentByCategory[categoryId] ?? 0,
        );
      }).toList();
      if (!mounted) return;
      setState(() {
        _budgetId = budgetId;
        _budgetName = budget['name']?.toString() ?? _budgetName;
        _monthlyBudget =
            (budget['amount'] as num?)?.toDouble() ?? _monthlyBudget;
        _categories = loadedCategories;
        _isLoading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.toString().replaceFirst('Exception: ', '');
      });
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

  double get _spent =>
      _categories.fold(0, (sum, category) => sum + category.spent);
  double get _remaining =>
      (_monthlyBudget - _spent).clamp(0, double.infinity).toDouble();
  double get _safeToSpendToday =>
      _remaining /
      (DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day -
          DateTime.now().day +
          1);
  _BudgetCategory? get _overLimitCategory {
    for (final category in _categories) {
      if (category.spent > category.limit) return category;
    }
    return null;
  }

  String _money(double value) => 'Rs ${value.toStringAsFixed(0)}';

  Future<void> _openEditBudget() async {
    if (_budgetId == null) return;
    final result = await Navigator.push<_BudgetEditResult>(
      context,
      MaterialPageRoute(
        builder: (_) => _EditBudgetScreen(
          token: widget.token,
          budgetId: _budgetId!,
          budgetName: _budgetName,
          monthlyBudget: _monthlyBudget,
          warningThreshold: _warningThreshold,
          categories: _categories,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _monthlyBudget = result.monthlyBudget;
      _warningThreshold = result.warningThreshold;
      _categories = result.categories;
    });
    _showMessage('Budget updated successfully.');
  }

  void _openEatingOut() {
    final category = _categories.firstWhere(
      (item) => item.name.toLowerCase() == 'eating out',
      orElse: () => _categories.first,
    );
    if (_budgetId == null || category.id == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EatingOutDetailScreen(
          token: widget.token,
          budgetId: _budgetId!,
          categoryId: category.id!,
        ),
      ),
    );
  }

  Future<void> _openSavingsGoals() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SavingsGoalsScreen(token: widget.token),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_spent / _monthlyBudget).clamp(0.0, 1.0);
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back, color: _navy),
          tooltip: 'Back',
        ),
        title: Text(
          _budgetName,
          style: TextStyle(color: _navy, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _openEditBudget,
            icon: const Icon(Icons.add, color: _navy),
            tooltip: 'Edit budget',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_loadError!, textAlign: TextAlign.center),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SavingsShortcut(onTap: _openSavingsGoals),
                    const SizedBox(height: 12),
                    _SummaryCard(
                      spent: _remaining,
                      budget: _monthlyBudget,
                      progress: progress,
                      money: _money,
                    ),
                    const SizedBox(height: 12),
                    _SafeToSpendCard(amount: _safeToSpendToday),
                    const SizedBox(height: 12),
                    _WarningCard(category: _overLimitCategory),
                    const SizedBox(height: 22),
                    const _SectionTitle(title: 'Categories'),
                    const SizedBox(height: 10),
                    ..._categories.map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CategoryBudgetCard(
                          category: category,
                          money: _money,
                          onTap: category.name == 'Eating out'
                              ? _openEatingOut
                              : null,
                        ),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () => _showMessage(
                          'More categories can be added from Edit budget.',
                        ),
                        child: const Text('See more categories'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _EditBudgetScreen extends StatefulWidget {
  final String token;
  final int budgetId;
  final String budgetName;
  final double monthlyBudget;
  final int warningThreshold;
  final List<_BudgetCategory> categories;

  const _EditBudgetScreen({
    required this.token,
    required this.budgetId,
    required this.budgetName,
    required this.monthlyBudget,
    required this.warningThreshold,
    required this.categories,
  });

  @override
  State<_EditBudgetScreen> createState() => _EditBudgetScreenState();
}

class _EditBudgetScreenState extends State<_EditBudgetScreen> {
  late final TextEditingController _monthlyController;
  late final Map<String, TextEditingController> _limitControllers;
  late int _warningThreshold;

  @override
  void initState() {
    super.initState();
    _monthlyController = TextEditingController(
      text: widget.monthlyBudget.toStringAsFixed(0),
    );
    _warningThreshold = widget.warningThreshold;
    _limitControllers = {
      for (final category in widget.categories)
        category.name: TextEditingController(
          text: category.limit.toStringAsFixed(0),
        ),
    };
  }

  @override
  void dispose() {
    _monthlyController.dispose();
    for (final controller in _limitControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double _number(String value, double fallback) =>
      double.tryParse(value.replaceAll(',', '').trim()) ?? fallback;

  double get _assigned => _limitControllers.values.fold<double>(
    0,
    (sum, controller) => sum + _number(controller.text, 0),
  );

  Future<void> _save() async {
    final categories = widget.categories.map((category) {
      return category.copyWith(
        limit: _number(_limitControllers[category.name]!.text, category.limit),
      );
    }).toList();
    try {
      await ApiService.updateBudget(
        token: widget.token,
        budgetId: widget.budgetId,
        name: widget.budgetName,
        amount: _number(_monthlyController.text, widget.monthlyBudget),
      );
      for (final category in categories) {
        if (category.id == null) {
          await ApiService.createBudgetCategory(
            token: widget.token,
            budgetId: widget.budgetId,
            name: category.name,
            limitAmount: category.limit,
            warningThreshold: _warningThreshold,
          );
        } else {
          await ApiService.updateBudgetCategory(
            token: widget.token,
            budgetId: widget.budgetId,
            categoryId: category.id!,
            name: category.name,
            limitAmount: category.limit,
            warningThreshold: _warningThreshold,
          );
        }
      }
      if (mounted)
        Navigator.pop(
          context,
          _BudgetEditResult(
            monthlyBudget: _number(
              _monthlyController.text,
              widget.monthlyBudget,
            ),
            warningThreshold: _warningThreshold,
            categories: categories,
          ),
        );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
    }
  }

  Future<void> _deleteBudget() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this budget?'),
        content: const Text(
          'This demo keeps the dashboard data, but the action is ready for a backend connection.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete == true && mounted) {
      try {
        await ApiService.deleteBudget(
          token: widget.token,
          budgetId: widget.budgetId,
        );
        if (mounted) Navigator.pop(context);
      } catch (error) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString().replaceFirst('Exception: ', '')),
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthlyBudget = _number(
      _monthlyController.text,
      widget.monthlyBudget,
    );
    final leftToAssign = (monthlyBudget - _assigned).clamp(0, double.infinity);
    return Scaffold(
      backgroundColor: _background,
      appBar: const _InnerAppBar(title: 'Edit September budget'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel(label: 'Monthly budget'),
              _BudgetTextField(controller: _monthlyController, prefix: 'Rs '),
              const SizedBox(height: 6),
              const Text(
                'You spent Rs 57,300 last month',
                style: TextStyle(color: _muted, fontSize: 11),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _FieldLabel(label: 'Category limits'),
                  TextButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Add category is ready for the next category.',
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add category'),
                  ),
                ],
              ),
              ...widget.categories.map(
                (category) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          category.name[0].toUpperCase() +
                              category.name.substring(1),
                          style: const TextStyle(color: _navy, fontSize: 13),
                        ),
                      ),
                      SizedBox(
                        width: 126,
                        child: _BudgetTextField(
                          controller: _limitControllers[category.name]!,
                          prefix: 'Rs ',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const _FieldLabel(label: 'Alert warning threshold'),
              const SizedBox(height: 9),
              Row(
                children: [70, 80, 90].map((value) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: value == 90 ? 0 : 8),
                      child: _ThresholdButton(
                        value: value,
                        selected: _warningThreshold == value,
                        onTap: () => setState(() => _warningThreshold = value),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 180),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Left to assign',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                  Text(
                    'Rs ${leftToAssign.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: _green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  style: _primaryButtonStyle(),
                  child: const Text('Save budget'),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: _deleteBudget,
                  child: Text(
                    'Delete this budget',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EatingOutDetailScreen extends StatefulWidget {
  final String token;
  final int budgetId;
  final int categoryId;

  const EatingOutDetailScreen({
    super.key,
    required this.token,
    required this.budgetId,
    required this.categoryId,
  });

  @override
  State<EatingOutDetailScreen> createState() => _EatingOutDetailScreenState();
}

class _EatingOutDetailScreenState extends State<EatingOutDetailScreen> {
  Map<String, dynamic>? _category;
  List<Map<String, dynamic>> _purchases = const [];
  List<Map<String, dynamic>> _weekly = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final result = await ApiService.getCategoryDetails(
        token: widget.token,
        budgetId: widget.budgetId,
        categoryId: widget.categoryId,
      );
      if (!mounted) return;
      setState(() {
        _category = Map<String, dynamic>.from(result['category'] as Map);
        _purchases = (result['recentPurchases'] as List? ?? [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _weekly = (result['weeklySpending'] as List? ?? [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      });
    } catch (error) {
      if (mounted)
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
    }
  }

  void _showAction(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: const _InnerAppBar(title: 'Eating out'),
      body: SafeArea(
        child: _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!, textAlign: TextAlign.center),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SpendSummaryCard(category: _category ?? const {}),
                    const SizedBox(height: 18),
                    const Text(
                      'Weekly spending',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _WeeklySpendingCard(weekly: _weekly),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent purchases',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              _showAction('Showing all purchases.'),
                          child: Text('See all ${_purchases.length}'),
                        ),
                      ],
                    ),
                    const _PurchaseCard(
                      initial: 'A',
                      name: 'Café Colombo',
                      source: 'Amal',
                      date: '14 Sep',
                      amount: 'Rs 2,400',
                      color: _orange,
                    ),
                    if (_purchases.isEmpty)
                      const _WhiteCard(
                        child: Text(
                          'No purchases recorded for this month.',
                          style: TextStyle(color: _muted, fontSize: 12),
                        ),
                      )
                    else
                      ..._purchases.map((purchase) {
                        final name =
                            purchase['name']?.toString() ??
                            purchase['merchant']?.toString() ??
                            'Purchase';
                        final source = purchase['source']?.toString() ?? 'You';
                        final date = purchase['expenseDate']?.toString() ?? '';
                        final amount =
                            (purchase['amount'] as num?)?.toDouble() ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _PurchaseCard(
                            visible: true,
                            initial: name.isEmpty
                                ? '?'
                                : name.substring(0, 1).toUpperCase(),
                            name: name,
                            source: source,
                            date: date,
                            amount: 'Rs ${amount.toStringAsFixed(0)}',
                            color: _orange,
                          ),
                        );
                      }),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () =>
                            _showAction('Amount covered from unassigned.'),
                        style: _primaryButtonStyle(),
                        child: const Text('Cover amount from unassigned'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _showAction('Limit editor opened.'),
                        style: _secondaryButtonStyle(),
                        child: const Text('Raise the limit instead'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class SavingsGoalsScreen extends StatefulWidget {
  final String token;

  const SavingsGoalsScreen({super.key, required this.token});

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

enum _SavingsGoalAction { edit, history, delete }

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  List<_SavingsGoal> _goals = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final result = await ApiService.getSavingsGoals(token: widget.token);
      if (!mounted) return;
      setState(() {
        _goals = result.map(_SavingsGoal.fromJson).toList();
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  double get _totalSaved => _goals.fold(0, (sum, goal) => sum + goal.saved);

  Future<void> _createGoal() async {
    final goal = await Navigator.push<_SavingsGoal>(
      context,
      MaterialPageRoute(
        builder: (_) => NewSavingsGoalScreen(token: widget.token),
      ),
    );
    if (!mounted || goal == null) return;
    setState(() => _goals.add(goal));
  }

  Future<void> _editGoal(_SavingsGoal goal) async {
    final updated = await Navigator.push<_SavingsGoal>(
      context,
      MaterialPageRoute(
        builder: (_) => NewSavingsGoalScreen(
          token: widget.token,
          goal: goal,
        ),
      ),
    );
    if (!mounted || updated == null) return;
    setState(() {
      _goals = _goals
          .map((item) => item.id == updated.id ? updated : item)
          .toList();
    });
  }

  Future<void> _showHistory(_SavingsGoal goal) async {
    if (goal.id == null) return;
    showDialog<void>(
      context: context,
      builder: (_) => _SavingsGoalHistoryDialog(
        token: widget.token,
        goal: goal,
      ),
    );
  }

  Future<void> _deleteGoal(_SavingsGoal goal) async {
    if (goal.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete savings goal?'),
        content: Text('Delete "${goal.name}" and its saving history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ApiService.deleteSavingsGoal(token: widget.token, goalId: goal.id!);
      if (!mounted) return;
      setState(() => _goals.removeWhere((item) => item.id == goal.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Savings goal deleted.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _openSaveMoney(_SavingsGoal goal) async {
    if (goal.id == null) return;
    final updated = await showDialog<_SavingsGoal>(
      context: context,
      builder: (_) => _SaveSavingsDialog(token: widget.token, goal: goal),
    );
    if (!mounted || updated == null) return;
    setState(() {
      _goals = _goals
          .map((item) => item.id == updated.id ? updated : item)
          .toList();
    });
  }

  String _money(double value) => 'Rs ${value.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: const _InnerAppBar(title: 'Savings goals'),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!, textAlign: TextAlign.center),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SavingsTotalCard(
                      total: _totalSaved,
                      count: _goals.length,
                      money: _money,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Active goals',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._goals.map(
                      (goal) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SavingsGoalCard(
                          goal: goal,
                          money: _money,
                          onTap: () => _openSaveMoney(goal),
                          onAction: (action) {
                            switch (action) {
                              case _SavingsGoalAction.edit:
                                _editGoal(goal);
                              case _SavingsGoalAction.history:
                                _showHistory(goal);
                              case _SavingsGoalAction.delete:
                                _deleteGoal(goal);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _createGoal,
                        icon: const Icon(Icons.add),
                        label: const Text('Create savings goal'),
                        style: _primaryButtonStyle(),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class NewSavingsGoalScreen extends StatefulWidget {
  final String token;
  final _SavingsGoal? goal;

  const NewSavingsGoalScreen({super.key, required this.token, this.goal});

  @override
  State<NewSavingsGoalScreen> createState() => _NewSavingsGoalScreenState();
}

class _NewSavingsGoalScreenState extends State<NewSavingsGoalScreen> {
  final _nameController = TextEditingController(text: 'New phone');
  final _targetController = TextEditingController(text: '90000');
  final _savedController = TextEditingController(text: '10000');
  String _selectedType = 'Emergency fund';
  DateTime _targetDate = DateTime(2027, 1, 1);

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    if (goal != null) {
      _nameController.text = goal.name;
      _targetController.text = goal.target.toStringAsFixed(0);
      _savedController.text = goal.saved.toStringAsFixed(0);
      _selectedType = goal.type ?? _selectedType;
      _targetDate = goal.targetDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _savedController.dispose();
    super.dispose();
  }

  double _number(String value) =>
      double.tryParse(value.replaceAll(',', '').trim()) ?? 0;

  String _dateLabel(DateTime date) =>
      '${date.day} ${_monthName(date.month)} ${date.year}';

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 10),
      initialDate: _targetDate.isBefore(DateTime.now())
          ? DateTime.now()
          : _targetDate,
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    final target = _number(_targetController.text);
    final saved = _number(_savedController.text);
    if (name.isEmpty || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a goal name and target amount.')),
      );
      return;
    }
    try {
      final result = widget.goal == null
          ? await ApiService.createSavingsGoal(
              token: widget.token,
              name: name,
              type: _selectedType,
              targetAmount: target,
              targetDate: _targetDate,
              savedAmount: saved,
            )
          : await ApiService.updateSavingsGoal(
              token: widget.token,
              goalId: widget.goal!.id!,
              name: name,
              type: _selectedType,
              targetAmount: target,
              targetDate: _targetDate,
              savedAmount: saved,
            );
      if (mounted) Navigator.pop(context, _SavingsGoal.fromJson(result));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = _number(_targetController.text);
    final saved = _number(_savedController.text);
    final monthly = ((target - saved).clamp(0, double.infinity) / 4);
    return Scaffold(
      backgroundColor: _background,
      appBar: _InnerAppBar(
        title: widget.goal == null ? 'New savings goal' : 'Edit savings goal',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel(label: 'Goal name'),
              _BudgetTextField(controller: _nameController),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: ['Emergency fund', 'Trip', 'Gadget'].map((type) {
                  final selected = _selectedType == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedType = type),
                    selectedColor: _navy,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : _navy,
                      fontSize: 11,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel(label: 'Target amount'),
                        _BudgetTextField(
                          controller: _targetController,
                          prefix: 'Rs ',
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel(label: 'Target date'),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _dateLabel(_targetDate),
                                    style: const TextStyle(
                                      color: _navy,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  color: _muted,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const _FieldLabel(label: 'Already saved'),
              _BudgetTextField(
                controller: _savedController,
                prefix: 'Rs ',
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              _InfoCard(
                backgroundColor: const Color(0xFFD9F4E9),
                icon: Icons.trending_up,
                iconColor: _green,
                title: 'Saving recommendation',
                body:
                    'To get there, save Rs ${monthly.toStringAsFixed(0)} a month for 4 months.',
              ),
              const SizedBox(height: 10),
              const _InfoCard(
                backgroundColor: _orangeSoft,
                icon: Icons.info_outline,
                iconColor: _orange,
                title: 'Your budget has Rs 8,000 unassigned',
                body: 'This goal needs a little more from another category.',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _create,
                  style: _primaryButtonStyle(),
                  child: Text(widget.goal == null ? 'Create goal' : 'Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetCategory {
  final int? id;
  final String name;
  final double spent;
  final double limit;
  final IconData icon;
  final Color color;

  const _BudgetCategory({
    this.id,
    required this.name,
    required this.spent,
    required this.limit,
    required this.icon,
    required this.color,
  });

  factory _BudgetCategory.fromJson(
    Map<String, dynamic> json, {
    double? spentOverride,
  }) {
    final name = json['name']?.toString() ?? 'Category';
    final lower = name.toLowerCase();
    final icon = lower.contains('transport')
        ? Icons.directions_car_outlined
        : lower.contains('grocery')
        ? Icons.shopping_basket_outlined
        : lower.contains('bill')
        ? Icons.receipt_long_outlined
        : Icons.restaurant_outlined;
    final color = lower.contains('eating')
        ? _orange
        : lower.contains('grocery')
        ? _green
        : const Color(0xFF5A8DEE);
    return _BudgetCategory(
      id: (json['id'] as num?)?.toInt(),
      name: name,
      spent: spentOverride ?? (json['spentAmount'] as num?)?.toDouble() ?? 0,
      limit: (json['limitAmount'] as num?)?.toDouble() ?? 0,
      icon: icon,
      color: color,
    );
  }

  _BudgetCategory copyWith({double? limit}) => _BudgetCategory(
    id: id,
    name: name,
    spent: spent,
    limit: limit ?? this.limit,
    icon: icon,
    color: color,
  );
}

class _BudgetEditResult {
  final double monthlyBudget;
  final int warningThreshold;
  final List<_BudgetCategory> categories;

  const _BudgetEditResult({
    required this.monthlyBudget,
    required this.warningThreshold,
    required this.categories,
  });
}

class _SavingsGoal {
  final int? id;
  final String name;
  final String? type;
  final DateTime targetDate;
  final double saved;
  final double target;
  final double monthly;
  final String status;
  final Color color;

  const _SavingsGoal({
    this.id,
    required this.name,
    required this.type,
    required this.targetDate,
    required this.saved,
    required this.target,
    required this.monthly,
    required this.status,
    required this.color,
  });

  factory _SavingsGoal.fromJson(Map<String, dynamic> json) {
    final statusValue = json['status']?.toString() ?? 'ON_TRACK';
    final status = statusValue == 'BEHIND'
        ? 'Behind'
        : statusValue == 'COMPLETED'
        ? 'Completed'
        : 'On track';
    final saved = (json['savedAmount'] as num?)?.toDouble() ?? 0;
    final target = (json['targetAmount'] as num?)?.toDouble() ?? 0;
    final parsedTargetDate = DateTime.tryParse(json['targetDate']?.toString() ?? '');
    return _SavingsGoal(
      id: (json['id'] as num?)?.toInt(),
      name: json['name']?.toString() ?? 'Savings goal',
      type: json['type']?.toString(),
      targetDate: parsedTargetDate ?? DateTime.now(),
      saved: saved,
      target: target,
      monthly: ((target - saved).clamp(0, double.infinity) / 4).toDouble(),
      status: status,
      color: status == 'Behind' ? _orange : _green,
    );
  }

  double get progress => target == 0 ? 0 : (saved / target).clamp(0.0, 1.0);
}

class _InnerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const _InnerAppBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: _background,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(Icons.arrow_back, color: _navy),
        tooltip: 'Back',
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: _navy,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SummaryCard extends StatelessWidget {
  final double spent;
  final double budget;
  final double progress;
  final String Function(double) money;

  const _SummaryCard({
    required this.spent,
    required this.budget,
    required this.progress,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Left this month',
            style: TextStyle(color: Color(0xFFC7D2EA), fontSize: 11),
          ),
          const SizedBox(height: 7),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                money(spent),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              const Text(
                '11 days left',
                style: TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE3EAF8),
              valueColor: const AlwaysStoppedAnimation<Color>(_orange),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'of ${money(budget)} budget',
            style: const TextStyle(color: Color(0xFFC7D2EA), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _SafeToSpendCard extends StatelessWidget {
  final double amount;

  const _SafeToSpendCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Safe to spend today',
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
                SizedBox(height: 5),
                Text(
                  'Rs ${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFD9F4E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Daily cap',
              style: TextStyle(
                color: _green,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final _BudgetCategory? category;

  const _WarningCard({required this.category});

  @override
  Widget build(BuildContext context) {
    if (category == null) return const SizedBox.shrink();
    final over = category!.spent - category!.limit;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _orangeSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.priority_high_rounded, color: _orange, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '${category!.name} is over its limit by Rs ${over.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Color(0xFF96501C),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBudgetCard extends StatelessWidget {
  final _BudgetCategory category;
  final String Function(double) money;
  final VoidCallback? onTap;

  const _CategoryBudgetCard({
    required this.category,
    required this.money,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final over = category.spent > category.limit;
    final difference = (category.limit - category.spent).abs();
    final progress = category.limit <= 0
        ? 0.0
        : (category.spent / category.limit).clamp(0.0, 1.0);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: category.color == _orange
                        ? _orangeSoft
                        : const Color(0xFFE6EEFC),
                    child: Icon(category.icon, color: category.color, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      category.name,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    over
                        ? '${money(difference)} over'
                        : '${money(difference)} left',
                    style: TextStyle(
                      color: over ? Colors.red.shade700 : _navy,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (onTap != null)
                    const Icon(Icons.chevron_right, color: _muted, size: 18),
                ],
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFDCE4F4),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    over ? Colors.red.shade700 : category.color,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${money(category.spent)} of ${money(category.limit)} limit',
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavingsShortcut extends StatelessWidget {
  final VoidCallback onTap;

  const _SavingsShortcut({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _navyLight,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(Icons.savings_outlined, color: Colors.white, size: 21),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Savings goals',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Track your progress toward savings goals',
                      style: TextStyle(color: Color(0xFFC7D2EA), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpendSummaryCard extends StatelessWidget {
  final Map<String, dynamic> category;

  const _SpendSummaryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final spent = (category['spentAmount'] as num?)?.toDouble() ?? 0;
    final limit = (category['limitAmount'] as num?)?.toDouble() ?? 0;
    final over =
        (category['overLimitAmount'] as num?)?.toDouble() ??
        (spent - limit).clamp(0, double.infinity);
    final progress = limit <= 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Spent this month',
                style: TextStyle(color: Color(0xFFC7D2EA), fontSize: 11),
              ),
              Text(
                'Rs ${spent.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE3EAF8),
              valueColor: const AlwaysStoppedAnimation<Color>(_orange),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Limit Rs ${limit.toStringAsFixed(0)}',
                style: const TextStyle(color: Color(0xFFC7D2EA), fontSize: 10),
              ),
              Text(
                over > 0
                    ? 'Rs ${over.toStringAsFixed(0)} over limit'
                    : 'Within limit',
                style: const TextStyle(
                  color: Color(0xFFFFB778),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklySpendingCard extends StatelessWidget {
  final List<Map<String, dynamic>> weekly;

  const _WeeklySpendingCard({required this.weekly});

  @override
  Widget build(BuildContext context) {
    final amounts = List<double>.generate(
      4,
      (index) => index < weekly.length
          ? (weekly[index]['amount'] as num?)?.toDouble() ?? 0
          : 0,
    );
    final maxAmount = amounts.fold<double>(
      0,
      (max, amount) => amount > max ? amount : max,
    );
    return _WhiteCard(
      child: SizedBox(
        height: 128,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(amounts.length, (index) {
            final value = maxAmount == 0 ? 0.0 : amounts[index] / maxAmount;
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 28,
                  height: 82 * value,
                  decoration: BoxDecoration(
                    color: index == amounts.length - 1
                        ? _orange
                        : const Color(0xFFDCE3F3),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'W${index + 1}',
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  final bool visible;
  final String initial;
  final String name;
  final String source;
  final String date;
  final String amount;
  final Color color;

  const _PurchaseCard({
    this.visible = false,
    required this.initial,
    required this.name,
    required this.source,
    required this.date,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return _WhiteCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$source · $date',
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              color: _navy,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavingsTotalCard extends StatelessWidget {
  final double total;
  final int count;
  final String Function(double) money;

  const _SavingsTotalCard({
    required this.total,
    required this.count,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saved so far',
            style: TextStyle(color: Color(0xFFC7D2EA), fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            money(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'across $count active goals',
            style: const TextStyle(color: Color(0xFFC7D2EA), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _SaveSavingsDialog extends StatefulWidget {
  final String token;
  final _SavingsGoal goal;

  const _SaveSavingsDialog({required this.token, required this.goal});

  @override
  State<_SaveSavingsDialog> createState() => _SaveSavingsDialogState();
}

class _SaveSavingsDialogState extends State<_SaveSavingsDialog> {
  final _amountController = TextEditingController();
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(
      _amountController.text.replaceAll(',', '').trim(),
    );
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter an amount greater than zero.');
      return;
    }
    final newSavedAmount = widget.goal.saved + amount;
    if (newSavedAmount > widget.goal.target) {
      setState(
        () => _error =
            'This is more than the remaining Rs ${(widget.goal.target - widget.goal.saved).toStringAsFixed(0)}.',
      );
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final result = await ApiService.updateSavingsGoalSaved(
        token: widget.token,
        goalId: widget.goal.id!,
        savedAmount: newSavedAmount,
      );
      if (mounted) Navigator.pop(context, _SavingsGoal.fromJson(result));
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
    final remaining = widget.goal.target - widget.goal.saved;
    return AlertDialog(
      title: Text('Save for ${widget.goal.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Already saved Rs ${widget.goal.saved.toStringAsFixed(0)} of Rs ${widget.goal.target.toStringAsFixed(0)}',
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            const Text(
              'Amount to save',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              autofocus: true,
              enabled: !_isSaving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                prefixText: 'Rs ',
                hintText: remaining.toStringAsFixed(0),
                border: const OutlineInputBorder(),
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
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save amount'),
        ),
      ],
    );
  }
}

class _SavingsGoalCard extends StatelessWidget {
  final _SavingsGoal goal;
  final String Function(double) money;
  final VoidCallback onTap;
  final ValueChanged<_SavingsGoalAction> onAction;

  const _SavingsGoalCard({
    required this.goal,
    required this.money,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final behind = goal.status == 'Behind';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: _WhiteCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.name,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: behind
                        ? const Color(0xFFFBE2DF)
                        : const Color(0xFFD9F4E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    goal.status,
                    style: TextStyle(
                      color: behind ? Colors.red.shade700 : _green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                PopupMenuButton<_SavingsGoalAction>(
                  tooltip: 'Savings goal options',
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert, color: _navy, size: 20),
                  onSelected: onAction,
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _SavingsGoalAction.edit,
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined),
                          SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: _SavingsGoalAction.history,
                      child: Row(
                        children: [
                          Icon(Icons.history),
                          SizedBox(width: 12),
                          Text('History'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: _SavingsGoalAction.delete,
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 5,
                backgroundColor: const Color(0xFFDCE4F4),
                valueColor: AlwaysStoppedAnimation<Color>(goal.color),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${money(goal.saved)} of ${money(goal.target)}',
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
                Text(
                  '${money(goal.monthly)} a month',
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SavingsGoalHistoryDialog extends StatefulWidget {
  final String token;
  final _SavingsGoal goal;

  const _SavingsGoalHistoryDialog({required this.token, required this.goal});

  @override
  State<_SavingsGoalHistoryDialog> createState() =>
      _SavingsGoalHistoryDialogState();
}

class _SavingsGoalHistoryDialogState extends State<_SavingsGoalHistoryDialog> {
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = ApiService.getSavingsGoalHistory(
      token: widget.token,
      goalId: widget.goal.id!,
    );
  }

  String _dateLabel(String? value) {
    final date = DateTime.tryParse(value ?? '')?.toLocal();
    if (date == null) return 'Unknown date';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.goal.name} history'),
      content: SizedBox(
        width: 380,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Text(
                snapshot.error.toString().replaceFirst('Exception: ', ''),
              );
            }
            final entries = snapshot.data ?? const [];
            if (entries.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No saving history yet.'),
              );
            }
            return SizedBox(
              height: 280,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: entries.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final amount = (entry['amount'] as num?)?.toDouble() ?? 0;
                  final balance = (entry['balanceAfter'] as num?)?.toDouble() ?? 0;
                  final type = entry['entryType']?.toString() == 'INITIAL'
                      ? 'Initial amount'
                      : 'Saved';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFD9F4E9),
                      child: Icon(Icons.savings_outlined, color: _green, size: 18),
                    ),
                    title: Text(
                      '+ Rs ${amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: _green,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text('${_dateLabel(entry['savedAt']?.toString())} • $type'),
                    trailing: Text(
                      'Rs ${balance.toStringAsFixed(0)}',
                      style: const TextStyle(color: _navy, fontSize: 11),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  const _InfoCard({
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(color: _navy, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _WhiteCard({
    required this.child,
    this.padding = const EdgeInsets.all(13),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      color: _navy,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: _navy,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    ),
  );
}

class _BudgetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? prefix;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _BudgetTextField({
    required this.controller,
    this.prefix,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(
        color: _navy,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        prefixText: prefix,
        prefixStyle: const TextStyle(
          color: _navy,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _navyLight, width: 1),
        ),
      ),
    );
  }
}

class _ThresholdButton extends StatelessWidget {
  final int value;
  final bool selected;
  final VoidCallback onTap;

  const _ThresholdButton({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? Colors.white : const Color(0xFFDDE5F6),
        foregroundColor: _navy,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text('$value%'),
    );
  }
}

ButtonStyle _primaryButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: _orange,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 13),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
  );
}

ButtonStyle _secondaryButtonStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: _navy,
    side: const BorderSide(color: _navy, width: 1.2),
    padding: const EdgeInsets.symmetric(vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
  );
}
