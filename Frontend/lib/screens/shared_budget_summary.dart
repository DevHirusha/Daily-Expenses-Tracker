import 'dart:convert';

import 'package:flutter/material.dart';
import '../services/api_service.dart';

enum _SummaryPeriod { day, week, month, year }

class SharedBudgetSummaryScreen extends StatefulWidget {
  final String token;

  const SharedBudgetSummaryScreen({super.key, required this.token});

  @override
  State<SharedBudgetSummaryScreen> createState() =>
      _SharedBudgetSummaryScreenState();
}

class _SharedBudgetSummaryScreenState
    extends State<SharedBudgetSummaryScreen> {
  List<Map<String, dynamic>> _budgets = const [];
  Map<int, _BudgetBreakdown> _breakdowns = const {};
  _SummaryPeriod _period = _SummaryPeriod.month;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    try {
      final budgets = await ApiService.getBudgets(token: widget.token);
      final breakdownEntries = await Future.wait(
        budgets.map((budget) async {
          final id = (budget['id'] as num).toInt();
          final members = await ApiService.getBudgetMembers(
            token: widget.token,
            budgetId: id,
          );
          return MapEntry(id, _BudgetBreakdown(budget: budget, members: members));
        }),
      );
      if (!mounted) return;
      setState(() {
        _budgets = budgets;
        _breakdowns = Map.fromEntries(breakdownEntries);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  List<Map<String, dynamic>> get _visibleBudgets =>
      _budgets.where(_isInSelectedPeriod).toList();

  Map<String, List<Map<String, dynamic>>> get _groupedBudgets {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final budget in _visibleBudgets) {
      final name = budget['groupName']?.toString().trim();
      final groupName = name == null || name.isEmpty ? 'Personal budgets' : name;
      grouped.putIfAbsent(groupName, () => []).add(budget);
    }
    return grouped;
  }

  double _value(Map<String, dynamic> budget, String key) =>
      (budget[key] as num?)?.toDouble() ?? 0;

  double get _spent => _visibleBudgets
      .where((budget) => budget['owner'] == true)
      .fold(0, (sum, budget) => sum + _value(budget, 'amount'));

  double get _contributed => _visibleBudgets
      .where((budget) => budget['owner'] != true)
      .fold(0, (sum, budget) => sum + _value(budget, 'payableAmount'));

  double get _total => _spent + _contributed;
  double get _remaining => (_total - _spent).clamp(0, double.infinity);

  DateTime? _date(Object? value) {
    final text = value?.toString();
    return text == null || text.isEmpty || text == 'null'
        ? null
        : DateTime.tryParse(text);
  }

  (DateTime, DateTime) get _bounds {
    final now = DateTime.now();
    switch (_period) {
      case _SummaryPeriod.day:
        final start = DateTime(now.year, now.month, now.day);
        return (start, start.add(const Duration(days: 1)));
      case _SummaryPeriod.week:
        final start = DateTime(now.year, now.month, now.day - now.weekday + 1);
        return (start, start.add(const Duration(days: 7)));
      case _SummaryPeriod.month:
        return (DateTime(now.year, now.month), DateTime(now.year, now.month + 1));
      case _SummaryPeriod.year:
        return (DateTime(now.year), DateTime(now.year + 1));
    }
  }

  bool _isInSelectedPeriod(Map<String, dynamic> budget) {
    final start = _date(budget['startDate']) ?? DateTime(2000);
    final end = _date(budget['endDate']) ?? DateTime(2100);
    return !end.isBefore(_bounds.$1) && !start.isAfter(_bounds.$2);
  }

  String get _periodLabel {
    switch (_period) {
      case _SummaryPeriod.day:
        return 'Today';
      case _SummaryPeriod.week:
        return 'This week';
      case _SummaryPeriod.month:
        return 'This month';
      case _SummaryPeriod.year:
        return 'This year';
    }
  }

  String _money(double value) => 'Rs ${value.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final total = _total;
    final ratio = total == 0 ? 0.0 : (_spent / total).clamp(0.0, 1.0);
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
        title: const Text('Budget summary', style: TextStyle(
          color: Color(0xFF172C57), fontWeight: FontWeight.bold,
        )),
        actions: [
          PopupMenuButton<_SummaryPeriod>(
            initialValue: _period,
            onSelected: (value) => setState(() => _period = value),
            tooltip: 'Filter summary period',
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                label: Text(_periodLabel),
                labelStyle: const TextStyle(
                  color: Color(0xFF172C57), fontSize: 12, fontWeight: FontWeight.w600,
                ),
                backgroundColor: Colors.white,
                side: BorderSide.none,
              ),
            ),
            itemBuilder: (context) => const [
              PopupMenuItem(value: _SummaryPeriod.day, child: Text('Day')),
              PopupMenuItem(value: _SummaryPeriod.week, child: Text('Week')),
              PopupMenuItem(value: _SummaryPeriod.month, child: Text('Month')),
              PopupMenuItem(value: _SummaryPeriod.year, child: Text('Year')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadBudgets,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(15, 8, 15, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _OverviewCard(
                        total: total,
                        spent: _spent,
                        contributed: _contributed,
                        remaining: _remaining,
                      ),
                      const SizedBox(height: 18),
                      _SpendChart(
                        spent: _spent,
                        contributed: _contributed,
                        ratio: ratio,
                      ),
                      const SizedBox(height: 22),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18),
                        child: Text('Your budget contributions', style: TextStyle(
                          color: Color(0xFF172C57), fontSize: 16, fontWeight: FontWeight.bold,
                        )),
                      ),
                      const SizedBox(height: 12),
                      _visibleBudgets.isEmpty
                          ? const _EmptySummary()
                          : _GroupContributionList(
                              groups: _groupedBudgets,
                              money: _money,
                              breakdowns: _breakdowns,
                            ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final double total;
  final double spent;
  final double contributed;
  final double remaining;

  const _OverviewCard({required this.total, required this.spent,
    required this.contributed, required this.remaining});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Total budget', style: TextStyle(color: Color(0xFF7890B8), fontSize: 12)),
      const SizedBox(height: 4),
      Text('Rs ${total.toStringAsFixed(0)}', style: const TextStyle(
        color: Color(0xFF172C57), fontSize: 26, fontWeight: FontWeight.bold,
      )),
      const SizedBox(height: 14),
      const Divider(height: 1, color: Color(0xFFE8ECF4)),
      const SizedBox(height: 12),
      Row(children: [
        _Metric(label: 'Contributed', value: contributed),
        _Metric(label: 'Spent', value: spent),
        _Metric(label: 'Remaining', value: remaining),
      ]),
    ]),
  );
}

class _Metric extends StatelessWidget {
  final String label;
  final double value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Color(0xFF7890B8), fontSize: 11)),
      const SizedBox(height: 4),
      Text('Rs ${value.toStringAsFixed(0)}', style: const TextStyle(
        color: Color(0xFF172C57), fontSize: 13, fontWeight: FontWeight.bold,
      )),
    ]),
  );
}

class _SpendChart extends StatelessWidget {
  final double spent;
  final double contributed;
  final double ratio;
  const _SpendChart({required this.spent, required this.contributed, required this.ratio});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Row(children: [
      SizedBox(width: 108, height: 108, child: Stack(alignment: Alignment.center, children: [
        CustomPaint(size: const Size.square(108), painter: _DonutPainter(ratio: ratio)),
        Text('${(ratio * 100).round()}%', style: const TextStyle(
          color: Color(0xFF172C57), fontSize: 20, fontWeight: FontWeight.bold,
        )),
      ])),
      const SizedBox(width: 18),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Legend(color: const Color(0xFFF47C20), label: 'Spent', value: spent),
        const SizedBox(height: 14),
        _Legend(color: const Color(0xFFD5DCF0), label: 'Contributed', value: contributed),
      ])),
    ]),
  );
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final double value;
  const _Legend({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 8),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Color(0xFF172C57), fontSize: 12, fontWeight: FontWeight.bold)),
      Text('Rs ${value.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
    ]),
  ]);
}

class _GroupContributionList extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> groups;
  final String Function(double) money;
  final Map<int, _BudgetBreakdown> breakdowns;

  const _GroupContributionList({
    required this.groups,
    required this.money,
    required this.breakdowns,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: groups.entries.map((entry) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _GroupContributionCard(
        groupName: entry.key,
        budgets: entry.value,
        money: money,
        breakdowns: breakdowns,
      ),
    )).toList(),
  );
}

class _GroupContributionCard extends StatelessWidget {
  final String groupName;
  final List<Map<String, dynamic>> budgets;
  final String Function(double) money;
  final Map<int, _BudgetBreakdown> breakdowns;

  const _GroupContributionCard({
    required this.groupName,
    required this.budgets,
    required this.money,
    required this.breakdowns,
  });

  @override
  Widget build(BuildContext context) {
    final memberTotals = <String, _MemberTotal>{};
    for (final budget in budgets) {
      final breakdown = breakdowns[(budget['id'] as num).toInt()];
      if (breakdown == null) continue;
      for (final member in breakdown.members) {
        final userId = member['userId']?.toString() ?? '';
        if (userId.isEmpty) continue;
        final amount = breakdown.amountFor(member);
        final current = memberTotals[userId];
        memberTotals[userId] = _MemberTotal(
          name: member['name']?.toString() ?? member['username']?.toString() ?? 'Member',
          amount: (current?.amount ?? 0) + amount,
        );
      }
    }
    final groupTotal = budgets.fold<double>(
      0,
      (sum, budget) => sum + ((budget['amount'] as num?)?.toDouble() ?? 0),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.groups_outlined, color: Color(0xFF5A8DEE), size: 19),
          const SizedBox(width: 8),
          Expanded(child: Text(groupName, overflow: TextOverflow.ellipsis, style: const TextStyle(
            color: Color(0xFF172C57), fontSize: 14, fontWeight: FontWeight.bold,
          ))),
          Text(money(groupTotal), style: const TextStyle(
            color: Color(0xFF172C57), fontSize: 12, fontWeight: FontWeight.bold,
          )),
        ]),
        const SizedBox(height: 14),
        _GroupBudgetPie(
          budgets: budgets,
          total: groupTotal,
          money: money,
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: Color(0xFFE8ECF4)),
        const SizedBox(height: 12),
        const Text(
          'Spent by members in this group',
          style: TextStyle(
            color: Color(0xFF172C57),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...memberTotals.entries.map(
          (entry) => _MemberProgressRow(
            name: entry.value.name,
            amount: entry.value.amount,
            total: groupTotal,
            money: money,
          ),
        ),
      ]),
    );
  }
}

class _BudgetBreakdown {
  final Map<String, dynamic> budget;
  final List<Map<String, dynamic>> members;

  const _BudgetBreakdown({required this.budget, required this.members});

  double amountFor(Map<String, dynamic> member) {
    final amount = (budget['amount'] as num?)?.toDouble() ?? 0;
    final overrides = <String, double>{};
    final savedSplit = budget['splitPercentages'];
    if (savedSplit is String && savedSplit.isNotEmpty) {
      try {
        final decoded = jsonDecode(savedSplit);
        if (decoded is Map) {
          overrides.addAll(
            decoded.map(
              (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
            ),
          );
        }
      } catch (_) {}
    }
    final fixedTotal = overrides.values.fold<double>(0, (sum, value) => sum + value);
    final flexible = members.where(
      (item) => !overrides.containsKey(item['userId']?.toString()),
    ).length + 1;
    final userId = member['userId']?.toString() ?? '';
    final percentage = overrides[userId] ??
        (flexible == 0 ? 0 : (100 - fixedTotal) / flexible);
    return amount * percentage / 100;
  }
}

class _MemberTotal {
  final String name;
  final double amount;

  const _MemberTotal({required this.name, required this.amount});
}

class _GroupBudgetPie extends StatelessWidget {
  final List<Map<String, dynamic>> budgets;
  final double total;
  final String Function(double) money;

  const _GroupBudgetPie({
    required this.budgets,
    required this.total,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    final values = budgets
        .map((budget) => (budget['amount'] as num?)?.toDouble() ?? 0)
        .toList();
    const colors = [
      Color(0xFFB93B2F),
      Color(0xFFF47C20),
      Color(0xFFFFA05E),
      Color(0xFF5A8DEE),
      Color(0xFF7C65C1),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: CustomPaint(
              painter: _MemberPiePainter(values: values),
              child: Center(
                child: Text(
                  money(total),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF172C57),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                budgets.length,
                (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors[index % colors.length],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${budgets[index]['name'] ?? 'Budget'}  ${money(values[index])}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF7890B8),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetPie extends StatelessWidget {
  final String name;
  final _BudgetBreakdown? breakdown;
  final String Function(double) money;

  const _BudgetPie({
    required this.name,
    required this.breakdown,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    final data = breakdown;
    if (data == null || data.members.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Text(name, style: const TextStyle(color: Color(0xFF172C57))),
      );
    }
    final values = data.members.map(data.amountFor).toList();
    final total = values.fold<double>(0, (sum, value) => sum + value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            height: 82,
            child: CustomPaint(
              painter: _MemberPiePainter(values: values),
              child: Center(
                child: Text(
                  money(total),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF172C57),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF172C57),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                ...List.generate(data.members.length, (index) {
                  final member = data.members[index];
                  return Text(
                    '${member['name'] ?? member['username'] ?? 'Member'}  ${money(values[index])}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF7890B8), fontSize: 10),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberProgressRow extends StatelessWidget {
  final String name;
  final double amount;
  final double total;
  final String Function(double) money;

  const _MemberProgressRow({
    required this.name,
    required this.amount,
    required this.total,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : (amount / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF172C57),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                money(amount),
                style: const TextStyle(color: Color(0xFF7890B8), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFD9DFF2),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF47C20)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberPiePainter extends CustomPainter {
  final List<double> values;

  const _MemberPiePainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, value) => sum + value);
    if (total == 0) return;
    final colors = [
      const Color(0xFFB93B2F),
      const Color(0xFFF47C20),
      const Color(0xFFFFA05E),
      const Color(0xFF5A8DEE),
      const Color(0xFF7C65C1),
    ];
    final rect = Offset.zero & size;
    var start = -1.5708;
    for (var index = 0; index < values.length; index++) {
      final sweep = 6.2832 * values[index] / total;
      canvas.drawArc(
        rect,
        start,
        sweep,
        true,
        Paint()..color = colors[index % colors.length],
      );
      start += sweep;
    }
    canvas.drawCircle(size.center(Offset.zero), size.shortestSide * .25,
        Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_MemberPiePainter oldDelegate) => oldDelegate.values != values;
}

class _DonutPainter extends CustomPainter {
  final double ratio;
  const _DonutPainter({required this.ratio});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 8;
    final background = Paint()..color = const Color(0xFFD5DCF0)..style = PaintingStyle.stroke..strokeWidth = 12;
    final foreground = Paint()..color = const Color(0xFFF47C20)..style = PaintingStyle.stroke..strokeWidth = 12;
    canvas.drawCircle(center, radius, background);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -1.5708,
      6.2832 * ratio, false, foreground);
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) => oldDelegate.ratio != ratio;
}

class _EmptySummary extends StatelessWidget {
  const _EmptySummary();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 28),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: const Center(child: Text('No budgets in this period', style: TextStyle(color: Color(0xFF94A3B8)))),
  );
}
