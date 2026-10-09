import 'package:flutter/material.dart';

class SupporterDashboardScreen extends StatelessWidget {
  const SupporterDashboardScreen({super.key});

  static const background = Color(0xFFE8ECFA);
  static const navy = Color(0xFF172C57);
  static const muted = Color(0xFF657596);
  static const green = Color(0xFF31AF70);
  static const orange = Color(0xFFF47C20);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        bottom: false,
        child: ListView(
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
                        color: navy,
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
                      color: navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: navy,
                    side: const BorderSide(color: navy),
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
            const _MonthlyCard(),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'INCOME',
                    amount: 'Rs 34,000',
                    amountColor: green,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    label: 'EXPENSES',
                    amount: 'Rs 28,500',
                    amountColor: navy,
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
                  foregroundColor: navy,
                  side: const BorderSide(color: navy, width: 1.4),
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
  const _MonthlyCard();

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
          const Text(
            'Rs 5,500',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: .7,
              minHeight: 6,
              backgroundColor: Color(0xFFD4DDEF),
              valueColor: AlwaysStoppedAnimation<Color>(
                SupporterDashboardScreen.green,
              ),
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Income exceeds your expenses',
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
