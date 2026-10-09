import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'gig_details_screen.dart';
import 'supporter_dashboard_screen.dart';

class FindGigsScreen extends StatefulWidget {
  final String token;

  const FindGigsScreen({super.key, required this.token});

  @override
  State<FindGigsScreen> createState() => _FindGigsScreenState();
}

class _FindGigsScreenState extends State<FindGigsScreen> {
  static const _background = Color(0xFFE8ECFA);
  static const _navy = Color(0xFF172C57);
  static const _mutedNavy = Color(0xFF657596);
  static const _orange = Color(0xFFF47C20);

  final _filters = const ['All', 'ONLINE', 'HYBRID', 'ONSITE'];
  int _selectedFilter = 0;
  List<_Gig> _gigs = const [];
  final Set<int> _appliedGigIds = <int>{};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGigs();
  }

  Future<void> _loadGigs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final rows = await ApiService.getGigs(token: widget.token);
      final gigs = rows.map(_Gig.fromJson).toList();
      if (!mounted) return;
      setState(() {
        _gigs = gigs;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _SummaryCard(onTap: _openSupporterDashboard),
              const SizedBox(height: 20),
              _buildFilterBar(),
              const SizedBox(height: 18),
              const Text(
                'Available opportunities',
                style: TextStyle(
                  color: _navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 36),
                  child: Column(
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _mutedNavy, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _loadGigs,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try again'),
                      ),
                    ],
                  ),
                )
              else if (visibleGigs.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(
                    child: Text(
                      'No gigs found',
                      style: TextStyle(color: _mutedNavy, fontSize: 15),
                    ),
                  ),
                )
              else
                ...visibleGigs.map(
                  (gig) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _GigCard(
                      gig: gig,
                      onDetails: () {
                        _openGigDetails(gig);
                      },
                      onApply: () {
                        _applyToGig(gig);
                      },
                      isApplied: gig.id != null && _appliedGigIds.contains(gig.id),
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
              fontSize: 18,
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
              width: 40,
              height: 40,
              child: Icon(Icons.search, color: _navy, size: 21),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 42,
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
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _filters[index],
                  style: TextStyle(
                    color: selected ? _navy : _mutedNavy,
                    fontSize: 12,
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

  Future<void> _openGigDetails(_Gig gig) async {
    final applied = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => GigDetailsScreen(
          title: gig.title,
          company: gig.company,
          pay: gig.pay,
          location: gig.location,
          type: gig.type,
          description: gig.description,
          requirements: gig.requirements,
          companyPhoneNumber: gig.companyPhoneNumber,
          imageData: gig.imageData,
        ),
      ),
    );
    _markGigAsApplied(gig, applied == true);
  }

  Future<void> _applyToGig(_Gig gig) async {
    if (gig.id != null && _appliedGigIds.contains(gig.id)) return;

    final applied = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ApplyContactScreen(
          company: gig.company,
          location: gig.location,
        ),
      ),
    );
    _markGigAsApplied(gig, applied == true);
  }

  void _markGigAsApplied(_Gig gig, bool applied) {
    if (!applied || gig.id == null || !mounted) return;
    setState(() => _appliedGigIds.add(gig.id!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Application submitted.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openSupporterDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SupporterDashboardScreen(),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF172C57),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D4A7C),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.insights_outlined,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Supporter summary',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'View combined income and expenses',
                      style: TextStyle(
                        color: Color(0xFFC8D3EA),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GigCard extends StatelessWidget {
  final _Gig gig;
  final VoidCallback onDetails;
  final VoidCallback onApply;
  final bool isApplied;

  const _GigCard({
    required this.gig,
    required this.onDetails,
    required this.onApply,
    required this.isApplied,
  });

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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: gig.iconColor,
                      shape: BoxShape.circle,
                    ),
                    child: _GigAvatar(gig: gig),
                  ),
                  const SizedBox(width: 12),
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
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          gig.company,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: mutedNavy,
                            fontSize: 12,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    gig.pay,
                    style: const TextStyle(
                      color: orange,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _Tag(label: gig.location),
                  const SizedBox(width: 8),
                  _Tag(label: gig.type),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(top: 14, bottom: 12),
                child: Divider(height: 1, color: Color(0xFFE7EAF2)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      gig.posted,
                      style: const TextStyle(color: mutedNavy, fontSize: 11),
                    ),
                  ),
                  InkWell(
                    onTap: onDetails,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                      child: Text(
                        'View Details →',
                        style: TextStyle(
                          color: orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 32,
                    child: FilledButton.icon(
                      onPressed: isApplied ? null : onApply,
                      icon: Icon(
                        isApplied ? Icons.check : Icons.send_outlined,
                        size: 14,
                      ),
                      label: Text(isApplied ? 'Applied' : 'Apply'),
                      style: FilledButton.styleFrom(
                        backgroundColor: orange,
                        disabledBackgroundColor: const Color(0xFFB6BED0),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        textStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F8),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF34456B),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Gig {
  final int? id;
  final String title;
  final String company;
  final String pay;
  final String location;
  final String type;
  final String posted;
  final String category;
  final String description;
  final String requirements;
  final String companyPhoneNumber;
  final IconData icon;
  final Color iconColor;
  final String? imageData;

  const _Gig({
    this.id,
    required this.title,
    required this.company,
    required this.pay,
    required this.location,
    required this.type,
    required this.posted,
    required this.category,
    this.description = '',
    this.requirements = '',
    this.companyPhoneNumber = '',
    required this.icon,
    required this.iconColor,
    this.imageData,
  });

  factory _Gig.fromJson(Map<String, dynamic> json) {
    final category = json['category']?.toString().toUpperCase() ?? 'ONLINE';
    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    final posted = createdAt == null
        ? 'Recently posted'
        : 'Posted ${_relativeTime(createdAt)}';
    return _Gig(
      id: int.tryParse(json['id']?.toString() ?? ''),
      title: json['title']?.toString() ?? 'Untitled gig',
      company: json['companyName']?.toString().trim().isNotEmpty == true
          ? json['companyName'].toString()
          : json['createdByName']?.toString() ?? 'Company',
      pay: json['estimatedEarnings']?.toString() ?? 'Payment not specified',
      location: json['location']?.toString().trim().isNotEmpty == true
          ? json['location'].toString()
          : 'Flexible location',
      type: category,
      posted: posted,
      category: category,
      description: json['description']?.toString() ?? '',
      requirements: json['requirements']?.toString() ?? '',
      companyPhoneNumber: json['companyPhoneNumber']?.toString() ?? '',
      icon: _iconFor(category),
      iconColor: _colorFor(category),
      imageData: json['imageData']?.toString(),
    );
  }

  static String _relativeTime(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt.toLocal());
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  static IconData _iconFor(String category) {
    switch (category) {
      case 'ONSITE':
        return Icons.storefront;
      case 'HYBRID':
        return Icons.sync_alt;
      default:
        return Icons.computer;
    }
  }

  static Color _colorFor(String category) {
    switch (category) {
      case 'ONSITE':
        return const Color(0xFFF58220);
      case 'HYBRID':
        return const Color(0xFF1A315D);
      default:
        return const Color(0xFF6C789B);
    }
  }
}

class _GigAvatar extends StatelessWidget {
  final _Gig gig;

  const _GigAvatar({required this.gig});

  @override
  Widget build(BuildContext context) {
    final imageData = gig.imageData;
    if (imageData != null && imageData.isNotEmpty) {
      try {
        final encoded = imageData.contains(',')
            ? imageData.substring(imageData.indexOf(',') + 1)
            : imageData;
        return ClipOval(
          child: Image.memory(
            base64Decode(encoded),
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {
        // Fall back to the category icon when an image cannot be decoded.
      }
    }
    return Icon(gig.icon, color: Colors.white, size: 21);
  }
}
