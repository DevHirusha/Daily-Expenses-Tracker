import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FindGigsScreen extends StatefulWidget {
  const FindGigsScreen({super.key});

  @override
  State<FindGigsScreen> createState() => _FindGigsScreenState();
}

class _FindGigsScreenState extends State<FindGigsScreen> {
  static const _background = Color(0xFFE8ECFA);
  static const _navy = Color(0xFF172C57);
  static const _mutedNavy = Color(0xFF657596);
  static const _orange = Color(0xFFF47C20);

  final _filters = const ['All', 'Delivery', 'Retail', 'Remote'];
  int _selectedFilter = 0;

  final _gigs = const [
    _Gig(
      title: 'Delivery rider',
      company: 'QuickBite Ltd',
      pay: 'Rs 1,800/day',
      location: 'Colombo 5',
      type: 'Part-time',
      posted: 'Posted 2h ago',
      category: 'Delivery',
      icon: Icons.two_wheeler,
      iconColor: Color(0xFFF58220),
    ),
    _Gig(
      title: 'Weekend cashier',
      company: 'MainStreet Retail',
      pay: 'Rs 1,200/day',
      location: 'Nugegoda',
      type: 'Weekends',
      posted: 'Posted 1d ago',
      category: 'Retail',
      icon: Icons.storefront,
      iconColor: Color(0xFF1A315D),
    ),
    _Gig(
      title: 'Data entry remote',
      company: 'Dexter Enterprises',
      pay: 'Rs 900/day',
      location: 'Remote',
      type: 'Flexible',
      posted: 'Posted 2d ago',
      category: 'Remote',
      icon: Icons.computer,
      iconColor: Color(0xFF6C789B),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visibleGigs = _selectedFilter == 0
        ? _gigs
        : _gigs
              .where((gig) => gig.category == _filters[_selectedFilter])
              .toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _background,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(11, 8, 11, 24),
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildFilterBar(),
              const SizedBox(height: 12),
              const Text(
                'Opportunities near Colombo',
                style: TextStyle(
                  color: _navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 9),
              if (visibleGigs.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(
                    child: Text(
                      'No gigs found',
                      style: TextStyle(color: _mutedNavy, fontSize: 13),
                    ),
                  ),
                )
              else
                ...visibleGigs.map(
                  (gig) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _GigCard(
                      gig: gig,
                      onDetails: () => _showGigDetails(gig),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Find gigs',
            style: TextStyle(
              color: _navy,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
          child: InkWell(
            borderRadius: BorderRadius.circular(7),
            onTap: _showSearchMessage,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: Icon(Icons.search, color: _navy, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 24,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFD3D9EE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final selected = index == _selectedFilter;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _filters[index],
                  style: TextStyle(
                    color: selected ? _navy : _mutedNavy,
                    fontSize: 9,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _showSearchMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Search is ready for your next gig.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showGigDetails(_Gig gig) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              gig.title,
              style: const TextStyle(
                color: _navy,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(gig.company, style: const TextStyle(color: _mutedNavy)),
            const SizedBox(height: 14),
            Text(
              '${gig.pay} • ${gig.location} • ${gig.type}',
              style: const TextStyle(
                color: _orange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GigCard extends StatelessWidget {
  final _Gig gig;
  final VoidCallback onDetails;

  const _GigCard({required this.gig, required this.onDetails});

  static const navy = Color(0xFF172C57);
  static const mutedNavy = Color(0xFF71809F);
  static const orange = Color(0xFFF47C20);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onDetails,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 23,
                    height: 23,
                    decoration: BoxDecoration(
                      color: gig.iconColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(gig.icon, color: Colors.white, size: 13),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gig.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: navy,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          gig.company,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: mutedNavy,
                            fontSize: 8,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    gig.pay,
                    style: const TextStyle(
                      color: orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  _Tag(label: gig.location),
                  const SizedBox(width: 5),
                  _Tag(label: gig.type),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(top: 7, bottom: 6),
                child: Divider(height: 1, color: Color(0xFFE7EAF2)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    gig.posted,
                    style: const TextStyle(color: mutedNavy, fontSize: 8),
                  ),
                  InkWell(
                    onTap: onDetails,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                      child: Text(
                        'View Details →',
                        style: TextStyle(
                          color: orange,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;

  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F8),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF34456B),
          fontSize: 7,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Gig {
  final String title;
  final String company;
  final String pay;
  final String location;
  final String type;
  final String posted;
  final String category;
  final IconData icon;
  final Color iconColor;

  const _Gig({
    required this.title,
    required this.company,
    required this.pay,
    required this.location,
    required this.type,
    required this.posted,
    required this.category,
    required this.icon,
    required this.iconColor,
  });
}
