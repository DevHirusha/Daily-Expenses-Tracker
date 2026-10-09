import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SupporterDashboardScreen extends StatefulWidget {
  static const background = Color(0xFFE8ECFA);
  static const navy = Color(0xFF172C57);
  static const muted = Color(0xFF657596);
  static const green = Color(0xFF31AF70);
  static const orange = Color(0xFFF47C20);

  final String token;

  const SupporterDashboardScreen({super.key, required this.token});

  @override
  State<SupporterDashboardScreen> createState() =>
      _SupporterDashboardScreenState();
}

class _SupporterDashboardScreenState extends State<SupporterDashboardScreen> {
  double _income = 0;
  double _expenses = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final applications = await ApiService.getMyGigApplications(
        token: widget.token,
      );
      final budgets = await ApiService.getBudgets(token: widget.token);

      var approvedIncome = 0.0;
      for (final application in applications) {
        if (application['status']?.toString().toUpperCase() != 'APPROVED') {
          continue;
        }
        approvedIncome += _parseAmount(application['estimatedEarnings']);
      }

      var totalExpenses = 0.0;
      for (final budget in budgets) {
        final budgetId = (budget['id'] as num?)?.toInt();
        if (budgetId == null) continue;
        try {
          final expenses = await ApiService.getExpenses(
            token: widget.token,
            budgetId: budgetId,
          );
          for (final expense in expenses) {
            totalExpenses += (expense['amount'] as num?)?.toDouble() ?? 0;
          }
        } catch (_) {
          // Keep the income total visible if an inaccessible budget is returned.
        }
      }

      if (!mounted) return;
      setState(() {
        _income = approvedIncome;
        _expenses = totalExpenses;
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

  double _parseAmount(dynamic value) {
    final text = value?.toString() ?? '';
    final match = RegExp(r'\d[\d,]*(?:\.\d+)?').firstMatch(text);
    if (match == null) return 0;
    return double.tryParse(match.group(0)!.replaceAll(',', '')) ?? 0;
  }

  String _money(double value) => 'Rs ${value.toStringAsFixed(0)}';

  String _signedMoney(double value) =>
      value < 0 ? '-Rs ${value.abs().toStringAsFixed(0)}' : _money(value);

  @override
  Widget build(BuildContext context) {
    final net = _income - _expenses;
    final combined = _income + _expenses;
    final progress = combined <= 0
        ? 0.0
        : (_income / combined).clamp(0.0, 1.0).toDouble();
    return Scaffold(
      backgroundColor: SupporterDashboardScreen.background,
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _loadSummary,
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Row(
              children: [
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  child: InkWell(
                    onTap: () => Navigator.maybePop(context),
                    borderRadius: BorderRadius.circular(9),
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        Icons.arrow_back,
                        color: SupporterDashboardScreen.navy,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Supporter Dashboard',
                    style: TextStyle(
                      color: SupporterDashboardScreen.navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SupporterDashboardScreen.navy,
                    side: const BorderSide(
                      color: SupporterDashboardScreen.navy,
                    ),
                    minimumSize: const Size(76, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('View only'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _MonthlyCard(
              net: _signedMoney(net),
              progress: progress,
              status: net >= 0
                  ? 'Income exceeds your expenses'
                  : 'Expenses exceed your income',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'INCOME',
                    amount: _money(_income),
                    amountColor: SupporterDashboardScreen.green,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    label: 'EXPENSES',
                    amount: _money(_expenses),
                    amountColor: SupporterDashboardScreen.navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _PrivacyNotice(),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: SupporterDashboardScreen.navy,
                  side: const BorderSide(
                    color: SupporterDashboardScreen.navy,
                    width: 1.4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('View full summary'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyCard extends StatelessWidget {
  final String net;
  final double progress;
  final String status;

  const _MonthlyCard({
    required this.net,
    required this.progress,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      decoration: BoxDecoration(
        color: SupporterDashboardScreen.navy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Net this month',
            style: TextStyle(color: Color(0xFFC8D3EA), fontSize: 11),
          ),
          const SizedBox(height: 5),
          Text(
            net,
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Color(0xFFD4DDEF),
              valueColor: AlwaysStoppedAnimation<Color>(
                SupporterDashboardScreen.green,
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            status,
            style: TextStyle(color: Color(0xFFC8D3EA), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.amount,
    required this.amountColor,
  });

  final String label;
  final String amount;
  final Color amountColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: SupporterDashboardScreen.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            amount,
            style: TextStyle(
              color: amountColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0DE),
        border: Border.all(color: const Color(0xFFFFD6AA)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFFFD9AE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              color: SupporterDashboardScreen.orange,
              size: 16,
            ),
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Notice',
                  style: TextStyle(
                    color: SupporterDashboardScreen.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Only combined totals are visible. Nadeesha\'s\n'
                  'individual gigs, specific transaction names, and\n'
                  'purchases remain private.',
                  style: TextStyle(
                    color: SupporterDashboardScreen.muted,
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
