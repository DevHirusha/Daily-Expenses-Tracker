import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class SharedOwnedBudgetProfileScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> budget;

  const SharedOwnedBudgetProfileScreen({
    super.key,
    required this.token,
    required this.budget,
  });

  @override
  State<SharedOwnedBudgetProfileScreen> createState() =>
      _SharedOwnedBudgetProfileScreenState();
}

class _SharedOwnedBudgetProfileScreenState
    extends State<SharedOwnedBudgetProfileScreen> {
  List<Map<String, dynamic>> _members = const [];
  List<Map<String, dynamic>> _settlements = const [];
  bool _isLoading = true;
  bool _isDeleting = false;
  bool _showSettled = true;
  bool _isUpdatingProof = false;
  Map<String, double> _percentageOverrides = {};

  int get _budgetId => (widget.budget['id'] as num).toInt();
  bool get _isOwner => widget.budget['owner'] == true;

  double get _amount => (widget.budget['amount'] as num?)?.toDouble() ?? 0;

  double get _ownerShareAmount =>
      _members.isEmpty ? 0 : _amount / (_members.length + 1);

  double _value(Map<String, dynamic> item, String key) =>
      (item[key] as num?)?.toDouble() ?? 0;

  double get _settledAmount => _settlements.fold<double>(
    0,
    (total, settlement) => total + _value(settlement, 'amount'),
  );

  double get _remainingAmount {
    final remainingBudget = _amount - _settledAmount;
    final memberRemaining = remainingBudget - _ownerShareAmount;
    return memberRemaining < 0 ? 0 : memberRemaining;
  }

  @override
  void initState() {
    super.initState();
    final savedSplit = widget.budget['splitPercentages'];
    if (savedSplit is String && savedSplit.isNotEmpty) {
      final decoded = jsonDecode(savedSplit);
      if (decoded is Map) {
        _percentageOverrides = decoded.map(
          (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
        );
      }
    }
    _loadMembers();
    _loadSettlements();
  }

  Future<void> _loadSettlements() async {
    try {
      final settlements = await ApiService.getBudgetSettlements(
        token: widget.token,
        budgetId: _budgetId,
      );
      if (mounted) setState(() => _settlements = settlements);
    } catch (_) {}
  }

  Future<void> _loadMembers() async {
    try {
      final members = await ApiService.getBudgetMembers(
        token: widget.token,
        budgetId: _budgetId,
      );
      if (!mounted) return;
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _showMembers() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Budget members',
                style: TextStyle(
                  color: Color(0xFF172C57),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (_members.isEmpty)
                const Text('No members selected')
              else
                ..._members.map(
                  (member) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFFFE1C7),
                      child: Text(
                        (member['name']?.toString() ?? 'M')[0].toUpperCase(),
                        style: const TextStyle(color: Color(0xFFF47C20)),
                      ),
                    ),
                    title: Text(member['name']?.toString() ?? 'Member'),
                    subtitle: Text(member['email']?.toString() ?? ''),
                    trailing: Text(
                      member['role']?.toString() == 'OWNER'
                          ? 'Owner'
                          : 'Member',
                      style: const TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                ),
              if (_isOwner)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showFriends();
                    },
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Add member'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF47C20),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAdvancedSplit() async {
    if (_members.isEmpty) {
      _showMessage('Add members before setting percentages');
      return;
    }
    final percentages = await showDialog<Map<String, double>>(
      context: context,
      builder: (context) => _AdvancedSplitDialog(
        members: _members,
        initialPercentages: _percentageOverrides,
      ),
    );
    if (percentages != null && mounted) {
      try {
        await ApiService.updateBudgetSplit(
          token: widget.token,
          budgetId: _budgetId,
          percentages: percentages,
        );
        setState(() {
          _percentageOverrides = percentages;
          widget.budget['splitPercentages'] = jsonEncode(percentages);
          _showSettled = false;
        });
      } catch (error) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _showFriends() async {
    try {
      final friends = await ApiService.getFriends(token: widget.token);
      if (!mounted) return;
      final existing = _members
          .map((member) => member['userId']?.toString())
          .whereType<String>()
          .toSet();
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => _FriendPicker(
          friends: friends,
          existingIds: existing,
          onAdd: (userId) async {
            await ApiService.addBudgetMember(
              token: widget.token,
              budgetId: _budgetId,
              userId: userId,
            );
            if (context.mounted) Navigator.pop(context);
            await _loadMembers();
          },
        ),
      );
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _deleteBudget() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete budget?'),
        content: const Text('This budget and its member list will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isDeleting = true);
    try {
      await ApiService.deleteBudget(token: widget.token, budgetId: _budgetId);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _isDeleting = false);
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _editProof() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    setState(() => _isUpdatingProof = true);
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image == null) return;
      final proofData = base64Encode(await image.readAsBytes());
      await ApiService.updateBudgetProof(
        token: widget.token,
        budgetId: _budgetId,
        proofData: proofData,
      );
      if (mounted) {
        setState(() => widget.budget['proofData'] = proofData);
        _showMessage('Proof updated');
      }
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isUpdatingProof = false);
    }
  }

  void _showFullProof(String proofData) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.memory(base64Decode(proofData), fit: BoxFit.contain),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'Close proof',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettlementHistory(Map<String, dynamic> settlement) {
    final payments = (settlement['payments'] as List?)
            ?.whereType<Map>()
            .map((payment) => Map<String, dynamic>.from(payment))
            .toList() ??
        const <Map<String, dynamic>>[];
    if (payments.length < 2) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${settlement['payerName'] ?? 'Member'} settlements'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: payments.length,
            separatorBuilder: (_, index) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final payment = payments[index];
              final proof = payment['proofData']?.toString() ?? '';
              final date = payment['createdAt']?.toString() ?? '';
              final amount = _value(payment, 'amount');
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Payment ${index + 1}: Rs ${amount.toStringAsFixed(2)}'),
                subtitle: date.isEmpty ? null : Text(date),
                trailing: proof.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _showFullProof(proof);
                        },
                        icon: const Icon(
                          Icons.receipt_long_outlined,
                          color: Color(0xFFF47C20),
                        ),
                        tooltip: 'View payment proof',
                      ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8ECFA),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF172C57)),
        ),
        title: Text(
          widget.budget['name']?.toString() ?? 'Budget',
          style: const TextStyle(
            color: Color(0xFF172C57),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isOwner)
            IconButton(
              onPressed: _isDeleting ? null : _deleteBudget,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete budget',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SpendCard(
                amount: _amount,
                ownerShareAmount: _ownerShareAmount,
                settledAmount: _settledAmount,
                remainingAmount: _remainingAmount,
              ),
              const SizedBox(height: 18),
              _ProofCard(
                proofData: widget.budget['proofData']?.toString(),
                canEdit: _isOwner,
                isUpdating: _isUpdatingProof,
                onEdit: _editProof,
                onOpen: _showFullProof,
              ),
              const SizedBox(height: 18),
              InkWell(
                onTap: _showMembers,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.people_alt_outlined,
                        color: Color(0xFFF47C20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isLoading
                              ? 'Loading members...'
                              : '${_members.length} members',
                          style: const TextStyle(
                            color: Color(0xFF172C57),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_isOwner)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _isLoading ? null : _showAdvancedSplit,
                    icon: const Icon(Icons.tune, size: 17),
                    label: const Text('Advanced split'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFF47C20),
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              _SettlementToggle(
                showSettled: _showSettled,
                onChanged: (value) => setState(() => _showSettled = value),
              ),
              const SizedBox(height: 12),
              _SettlementAmount(
                showSettled: _showSettled,
                amount: _showSettled ? _settledAmount : _remainingAmount,
              ),
              const SizedBox(height: 12),
              if (_showSettled)
                _SettlementSection(
                  settlements: _settlements
                      .where((settlement) => _value(settlement, 'amount') > 0)
                      .toList(),
                  onOpenProof: _showFullProof,
                  onViewAll: _showSettlementHistory,
                ),
              if (!_showSettled && !_isLoading) ...[
                const SizedBox(height: 12),
                _MemberShareList(
                  members: _members,
                  amount: _amount,
                  ownerName: widget.budget['ownerName']?.toString() ?? 'You',
                  ownerShareAmount: _ownerShareAmount,
                  percentageOverrides: _percentageOverrides,
                  settlements: _settlements,
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'EXPENSES',
                style: TextStyle(
                  color: Color(0xFF7995C0),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const _EmptyExpenses(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettlementSection extends StatelessWidget {
  final List<Map<String, dynamic>> settlements;
  final ValueChanged<String> onOpenProof;
  final ValueChanged<Map<String, dynamic>> onViewAll;

  const _SettlementSection({
    required this.settlements,
    required this.onOpenProof,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (settlements.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settlements',
            style: TextStyle(
              color: Color(0xFF172C57),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          ...settlements.map((settlement) {
            final payments = settlement['payments'];
            final hasMultiplePayments = payments is List && payments.length > 1;
            final proof = settlement['proofData']?.toString() ?? '';
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFFFE1C7),
                child: Text(
                  (settlement['payerName']?.toString() ?? 'M')[0].toUpperCase(),
                  style: const TextStyle(color: Color(0xFFF47C20)),
                ),
              ),
              title: Text(settlement['payerName']?.toString() ?? 'Member'),
              subtitle: Text(
                settlement['fullyPaid'] == true
                    ? 'Paid in full • Rs ${settlement['amount']}'
                    : 'Paid Rs ${settlement['amount']} • Remaining Rs ${settlement['remainingAmount']}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasMultiplePayments)
                    TextButton(
                      onPressed: () => onViewAll(settlement),
                      child: const Text('View all'),
                    ),
                  if (proof.isNotEmpty)
                    IconButton(
                      onPressed: () => onOpenProof(proof),
                      icon: const Icon(
                        Icons.receipt_long_outlined,
                        color: Color(0xFFF47C20),
                      ),
                      tooltip: 'View latest settlement proof',
                    )
                  else
                    const Icon(
                      Icons.hourglass_empty,
                      color: Color(0xFF94A3B8),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SpendCard extends StatelessWidget {
  final double amount;
  final double ownerShareAmount;
  final double settledAmount;
  final double remainingAmount;

  const _SpendCard({
    required this.amount,
    required this.ownerShareAmount,
    required this.settledAmount,
    required this.remainingAmount,
  });

  @override
  Widget build(BuildContext context) {
    final ownerRatio = amount <= 0
      ? 0.0
      : (ownerShareAmount / amount).clamp(0.0, 1.0).toDouble();
    final settledRatio = amount <= 0
      ? 0.0
      : (settledAmount / amount).clamp(0.0, 1.0 - ownerRatio).toDouble();
    final remainingRatio = (1 - ownerRatio - settledRatio).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Spent', style: TextStyle(color: Color(0xFF64748B))),
              Text(
                'Rs ${settledAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Color(0xFF172C57),
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 9,
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: constraints.maxWidth * ownerRatio,
                        child: Container(color: const Color(0xFF2563EB)),
                      ),
                    ),
                    Positioned(
                      left: constraints.maxWidth * ownerRatio,
                      child: SizedBox(
                        width: constraints.maxWidth * settledRatio,
                        height: constraints.maxHeight,
                        child: Container(color: const Color(0xFFF47C20)),
                      ),
                    ),
                    Positioned(
                      left: constraints.maxWidth * (ownerRatio + settledRatio),
                      child: SizedBox(
                        width: constraints.maxWidth * remainingRatio,
                        height: constraints.maxHeight,
                        child: Container(color: const Color(0xFFD9DFF2)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Rs ${remainingAmount.toStringAsFixed(0)} remaining',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;

  const _Segment({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: selected ? const Color(0xFF172C57) : const Color(0xFF7995C0),
        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
      ),
    ),
  );
}

class _SettlementToggle extends StatelessWidget {
  final bool showSettled;
  final ValueChanged<bool> onChanged;

  const _SettlementToggle({required this.showSettled, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    height: 42,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: const Color(0xFFD9DFF2),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(true),
            child: _Segment(label: 'Settled', selected: showSettled),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(false),
            child: _Segment(label: 'Remains', selected: !showSettled),
          ),
        ),
      ],
    ),
  );
}

class _SettlementAmount extends StatelessWidget {
  final bool showSettled;
  final double amount;

  const _SettlementAmount({required this.showSettled, required this.amount});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          showSettled
              ? 'Settled by members'
              : amount <= 0
              ? 'All paid'
              : 'Remaining for members',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
        if (!showSettled && amount <= 0)
          const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 22)
        else
          Text(
            'Rs ${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Color(0xFF172C57),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    ),
  );
}

class _MemberShareList extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final double amount;
  final String ownerName;
  final double ownerShareAmount;
  final Map<String, double> percentageOverrides;
  final List<Map<String, dynamic>> settlements;

  const _MemberShareList({
    required this.members,
    required this.amount,
    required this.ownerName,
    required this.ownerShareAmount,
    required this.percentageOverrides,
    required this.settlements,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const Text(
        'Add members to calculate each person\'s share.',
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
      );
    }
    final fixedTotal = percentageOverrides.values.fold<double>(
      0,
      (sum, percentage) => sum + percentage,
    );
    final remainingPercentage = (100 - fixedTotal).clamp(0, 100).toDouble();
    final visibleMembers = members
      .where((member) => member['name']?.toString() != ownerName)
      .toList();
    final flexibleMembers = visibleMembers.where(
      (member) =>
          !percentageOverrides.containsKey(member['userId']?.toString()),
    );
    final equalPercentage = flexibleMembers.isEmpty
        ? 0
        : remainingPercentage / flexibleMembers.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Member share',
            style: TextStyle(
              color: Color(0xFF172C57),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _OwnerShareRow(
            name: ownerName,
            percentage: amount <= 0 ? 0 : ownerShareAmount / amount * 100,
            amount: ownerShareAmount,
          ),
          ...visibleMembers.map((member) {
            final userId = member['userId']?.toString() ?? '';
            final percentage = percentageOverrides[userId] ?? equalPercentage;
            final share = amount * percentage / 100;
            final settlement = settlements.cast<Map<String, dynamic>?>().firstWhere(
              (item) => item?['payerUserId']?.toString() == userId,
              orElse: () => null,
            );
            final paid = settlement == null
                ? 0
                : (settlement['amount'] as num?)?.toDouble() ?? 0;
            final remaining = settlement == null
                ? share
                : (settlement['remainingAmount'] as num?)?.toDouble() ?? share;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: const Color(0xFFFFE1C7),
                    child: Text(
                      (member['name']?.toString() ?? 'M')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFF47C20),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      member['name']?.toString() ?? 'Member',
                      style: const TextStyle(color: Color(0xFF172C57)),
                    ),
                  ),
                  remaining <= 0
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${percentage.toStringAsFixed(1)}%  •  Share Rs ${share.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFFF47C20),
                                fontSize: 11,
                              ),
                            ),
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF16A34A),
                                  size: 18,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Settled',
                                  style: TextStyle(
                                    color: Color(0xFF16A34A),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${percentage.toStringAsFixed(1)}%  •  Share Rs ${share.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFFF47C20),
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              'Paid Rs ${paid.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Remain Rs ${remaining.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFF172C57),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _OwnerShareRow extends StatelessWidget {
  final String name;
  final double percentage;
  final double amount;

  const _OwnerShareRow({
    required this.name,
    required this.percentage,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 15,
          backgroundColor: Color(0xFFFFE0C2),
          child: Icon(Icons.person, color: Color(0xFFC2410C), size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$name (You)',
            style: const TextStyle(color: Color(0xFF172C57)),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Color(0xFFF47C20),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Share Rs ${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Color(0xFFF47C20),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ProofCard extends StatelessWidget {
  final String? proofData;
  final bool canEdit;
  final bool isUpdating;
  final VoidCallback onEdit;
  final ValueChanged<String> onOpen;

  const _ProofCard({
    required this.proofData,
    required this.canEdit,
    required this.isUpdating,
    required this.onEdit,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final hasProof = proofData != null && proofData!.isNotEmpty;
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 250,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: hasProof ? () => onOpen(proofData!) : null,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: hasProof
                      ? Image.memory(
                          base64Decode(proofData!),
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 72,
                          height: 72,
                          color: const Color(0xFFE8ECFA),
                          child: const Icon(
                            Icons.image_outlined,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Proof',
                      style: TextStyle(
                        color: Color(0xFF172C57),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasProof ? 'Tap to view' : 'No proof uploaded',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                      ),
                    ),
                    if (canEdit)
                      InkWell(
                        onTap: isUpdating ? null : onEdit,
                        child: const Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Text(
                            'Change',
                            style: TextStyle(
                              color: Color(0xFFF47C20),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdvancedSplitDialog extends StatefulWidget {
  final List<Map<String, dynamic>> members;
  final Map<String, double> initialPercentages;

  const _AdvancedSplitDialog({
    required this.members,
    required this.initialPercentages,
  });

  @override
  State<_AdvancedSplitDialog> createState() => _AdvancedSplitDialogState();
}

class _AdvancedSplitDialogState extends State<_AdvancedSplitDialog> {
  late final Map<String, TextEditingController> _controllers = {
    for (final member in widget.members)
      member['userId']?.toString() ?? '': TextEditingController(
        text:
            widget.initialPercentages[member['userId']?.toString()]
                ?.toString() ??
            '',
      ),
  };
  String? _error;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    final percentages = <String, double>{};
    for (final entry in _controllers.entries) {
      final value = entry.value.text.trim();
      if (value.isEmpty) continue;
      final percentage = double.tryParse(value);
      if (percentage == null || percentage < 0 || percentage > 100) {
        setState(() => _error = 'Each percentage must be between 0 and 100');
        return;
      }
      percentages[entry.key] = percentage;
    }
    final total = percentages.values.fold<double>(
      0,
      (sum, percentage) => sum + percentage,
    );
    if (total > 100) {
      setState(() => _error = 'Fixed percentages cannot exceed 100%');
      return;
    }
    Navigator.pop(context, percentages);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Advanced split'),
    content: SizedBox(
      width: double.maxFinite,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set fixed percentages for members. The remaining percentage is divided equally among blank members.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 14),
            ...widget.members.map(
              (member) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        member['name']?.toString() ?? 'Member',
                        style: const TextStyle(color: Color(0xFF172C57)),
                      ),
                    ),
                    SizedBox(
                      width: 86,
                      child: TextField(
                        controller:
                            _controllers[member['userId']?.toString() ?? ''],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          suffixText: '%',
                          hintText: 'Auto',
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Done')),
    ],
  );
}

class _EmptyExpenses extends StatelessWidget {
  const _EmptyExpenses();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 34),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Center(
      child: Text(
        'No expenses yet',
        style: TextStyle(color: Color(0xFF94A3B8)),
      ),
    ),
  );
}

class _FriendPicker extends StatefulWidget {
  final List<Map<String, dynamic>> friends;
  final Set<String> existingIds;
  final Future<void> Function(String userId) onAdd;

  const _FriendPicker({
    required this.friends,
    required this.existingIds,
    required this.onAdd,
  });

  @override
  State<_FriendPicker> createState() => _FriendPickerState();
}

class _FriendPickerState extends State<_FriendPicker> {
  String? _adding;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add from friends',
            style: TextStyle(
              color: Color(0xFF172C57),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.friends.isEmpty)
            const Text('No friends found.')
          else
            ...widget.friends.map((friend) {
              final id = friend['userId']?.toString() ?? '';
              final exists = widget.existingIds.contains(id);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(friend['name']?.toString() ?? 'Friend'),
                subtitle: Text(friend['email']?.toString() ?? ''),
                trailing: exists
                    ? const Text(
                        'Added',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      )
                    : TextButton(
                        onPressed: _adding == id
                            ? null
                            : () async {
                                setState(() => _adding = id);
                                await widget.onAdd(id);
                              },
                        child: Text(_adding == id ? 'Adding...' : 'Add'),
                      ),
              );
            }),
        ],
      ),
    ),
  );
}
