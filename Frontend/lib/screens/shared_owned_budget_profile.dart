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
  Map<String, double> _amountOverrides = {};

  int get _budgetId => (widget.budget['id'] as num).toInt();
  bool get _isOwner => widget.budget['owner'] == true;

  double get _amount => (widget.budget['amount'] as num?)?.toDouble() ?? 0;

  String get _ownerId => _members
      .firstWhere(
        (member) => member['role']?.toString() == 'OWNER',
        orElse: () => const <String, dynamic>{},
      )['userId']
      ?.toString() ??
      '';

  int get _flexibleMemberCount => _members.where(
    (member) =>
        member['role']?.toString() != 'OWNER' &&
        !_percentageOverrides.containsKey(member['userId']?.toString()) &&
        !_amountOverrides.containsKey(member['userId']?.toString()),
  ).length;

    double get _fixedAmount => _amountOverrides.values.fold(0, (sum, value) => sum + value);
    double get _fixedPercentageAmount => _amount *
      _percentageOverrides.values.fold<double>(0, (sum, value) => sum + value) / 100;

  double get _ownerShareAmount {
    if (_amountOverrides.containsKey(_ownerId)) {
      return _amountOverrides[_ownerId]!;
    }
    if (_percentageOverrides.containsKey(_ownerId)) {
      return _amount * _percentageOverrides[_ownerId]! / 100;
    }
    final flexibleParticipants = _flexibleMemberCount + 1;
    final remaining = (_amount - _fixedAmount - _fixedPercentageAmount)
        .clamp(0, _amount)
        .toDouble();
    return flexibleParticipants == 0 ? 0 : remaining / flexibleParticipants;
  }

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
    _readSavedSplit(widget.budget['splitPercentages']);
    _loadMembers();
    _loadSettlements();
  }

  void _readSavedSplit(dynamic savedSplit) {
    if (savedSplit is! String || savedSplit.isEmpty) return;
    final decoded = jsonDecode(savedSplit);
    if (decoded is! Map) return;
    final percentages = decoded['percentages'] is Map ? decoded['percentages'] : decoded;
    final amounts = decoded['amounts'] is Map ? decoded['amounts'] : const {};
    _percentageOverrides = Map<String, double>.fromEntries(
      (percentages as Map).entries.map((entry) => MapEntry(entry.key.toString(), (entry.value as num).toDouble())),
    );
    _amountOverrides = Map<String, double>.fromEntries(
      (amounts as Map).entries.map((entry) => MapEntry(entry.key.toString(), (entry.value as num).toDouble())),
    );
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
    final split = await showDialog<Map<String, Map<String, double>>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AdvancedSplitDialog(
        members: _members,
        budgetAmount: _amount,
        initialPercentages: _percentageOverrides,
        initialAmounts: _amountOverrides,
      ),
    );
    if (split != null && mounted) {
      try {
        await ApiService.updateBudgetSplit(
          token: widget.token,
          budgetId: _budgetId,
          percentages: split['percentages']!,
          amounts: split['amounts']!,
        );
        setState(() {
          _percentageOverrides = split['percentages']!;
          _amountOverrides = split['amounts']!;
          widget.budget['splitPercentages'] = jsonEncode({
            'percentages': _percentageOverrides,
            'amounts': _amountOverrides,
          });
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
                settledAmount: _settledAmount,
                remainingAmount: _remainingAmount,
              ),
              const SizedBox(height: 18),
              _ProofCard(
                proofData: widget.budget['proofData']?.toString(),
                amount: _amount,
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
                  ownerId: _ownerId,
                  ownerShareAmount: _ownerShareAmount,
                  percentageOverrides: _percentageOverrides,
                  amountOverrides: _amountOverrides,
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
  final double settledAmount;
  final double remainingAmount;

  const _SpendCard({
    required this.amount,
    required this.settledAmount,
    required this.remainingAmount,
  });

  @override
  Widget build(BuildContext context) {
    final settledRatio = amount <= 0
        ? 0.0
        : (settledAmount / amount).clamp(0.0, 1.0).toDouble();
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
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: 1.60,
                      child: CircularProgressIndicator(
                        value: settledRatio,
                        strokeWidth: 5,
                        backgroundColor: const Color(0xFFD9DFF2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFF47C20),
                        ),
                      ),
                    ),
                    Text(
                      '${(settledRatio * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Color(0xFF172C57),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Budget settled',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rs ${settledAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFFF47C20),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'of Rs ${amount.toStringAsFixed(2)} total',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rs ${remainingAmount.toStringAsFixed(2)} remaining',
                      style: const TextStyle(
                        color: Color(0xFF172C57),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
  final String ownerId;
  final double ownerShareAmount;
  final Map<String, double> percentageOverrides;
  final Map<String, double> amountOverrides;
  final List<Map<String, dynamic>> settlements;

  const _MemberShareList({
    required this.members,
    required this.amount,
    required this.ownerName,
    required this.ownerId,
    required this.ownerShareAmount,
    required this.percentageOverrides,
    required this.amountOverrides,
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
    final fixedAmount = amountOverrides.values.fold<double>(0, (sum, value) => sum + value);
    final fixedPercentageAmount = amount * percentageOverrides.values.fold<double>(
      0,
      (sum, percentage) => sum + percentage,
    ) / 100;
    final remainingAmount = (amount - fixedAmount - fixedPercentageAmount).clamp(0, amount).toDouble();
    final visibleMembers = members
      .where((member) => member['name']?.toString() != ownerName)
      .toList();
    final flexibleMembers = visibleMembers.where(
      (member) =>
          !percentageOverrides.containsKey(member['userId']?.toString()) &&
          !amountOverrides.containsKey(member['userId']?.toString()),
    );
    final ownerIsFlexible = !percentageOverrides.containsKey(ownerId) &&
        !amountOverrides.containsKey(ownerId);
    final flexibleParticipants = flexibleMembers.length +
        (ownerIsFlexible ? 1 : 0);
    final equalAmount = flexibleParticipants == 0
        ? 0
      : remainingAmount / flexibleParticipants;
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
            final share = amountOverrides[userId] ??
              (percentageOverrides.containsKey(userId)
                ? amount * percentageOverrides[userId]! / 100
                : equalAmount);
            final percentage = amount <= 0 ? 0 : share / amount * 100;
            final settlement = settlements.cast<Map<String, dynamic>?>().firstWhere(
              (item) => item?['payerUserId']?.toString() == userId,
              orElse: () => null,
            );
            final paid = settlement == null
                ? 0
                : (settlement['amount'] as num?)?.toDouble() ?? 0;
            final remaining = (share - paid).clamp(0, share).toDouble();
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
  final double amount;
  final bool canEdit;
  final bool isUpdating;
  final VoidCallback onEdit;
  final ValueChanged<String> onOpen;

  const _ProofCard({
    required this.proofData,
    required this.amount,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
              const SizedBox(height: 10),
              Text(
                'Total cost  Rs ${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFFF47C20),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
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
  final double budgetAmount;
  final Map<String, double> initialPercentages;
  final Map<String, double> initialAmounts;

  const _AdvancedSplitDialog({
    required this.members,
    required this.budgetAmount,
    required this.initialPercentages,
    required this.initialAmounts,
  });

  @override
  State<_AdvancedSplitDialog> createState() => _AdvancedSplitDialogState();
}

class _AdvancedSplitDialogState extends State<_AdvancedSplitDialog> {
  static const _navy = Color(0xFF5066A0);
  static const _orange = Color(0xFFF47C20);
  late final Map<String, String> _modes = {
    for (final member in widget.members)
      member['userId']?.toString() ?? '': widget.initialAmounts.containsKey(
            member['userId']?.toString(),
          )
          ? 'amount'
          : widget.initialPercentages.containsKey(member['userId']?.toString())
          ? 'percentage'
          : 'auto',
  };
  late final Map<String, TextEditingController> _percentageControllers = {
    for (final member in widget.members)
      member['userId']?.toString() ?? '': TextEditingController(
        text:
            widget.initialPercentages[member['userId']?.toString()]
                ?.toString() ??
            '',
      ),
  };
  late final Map<String, TextEditingController> _amountControllers = {
    for (final member in widget.members)
      member['userId']?.toString() ?? '': TextEditingController(
        text: widget.initialAmounts[member['userId']?.toString()]?.toString() ?? '',
      ),
  };
  String? _error;

  void _setAllAuto() {
    setState(() {
      for (final id in _modes.keys) {
        _modes[id] = 'auto';
        _percentageControllers[id]!.clear();
        _amountControllers[id]!.clear();
      }
      _error = null;
    });
  }

  Future<void> _chooseMode(String id) async {
    final mode = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.autorenew, color: _navy),
              title: const Text('Auto split'),
              subtitle: const Text('Share the remaining amount equally'),
              onTap: () => Navigator.pop(context, 'auto'),
            ),
            ListTile(
              leading: const Icon(Icons.percent, color: _orange),
              title: const Text('Percentage'),
              subtitle: const Text('Enter this member\'s percentage'),
              onTap: () => Navigator.pop(context, 'percentage'),
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined, color: _orange),
              title: const Text('Amount'),
              subtitle: const Text('Enter this member\'s allocated amount'),
              onTap: () => Navigator.pop(context, 'amount'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || mode == null) return;
    setState(() {
      _modes[id] = mode;
      if (mode == 'auto') {
        _percentageControllers[id]!.clear();
        _amountControllers[id]!.clear();
      } else if (mode == 'percentage') {
        _amountControllers[id]!.clear();
      } else {
        _percentageControllers[id]!.clear();
      }
    });
  }

  @override
  void dispose() {
    for (final controller in [..._percentageControllers.values, ..._amountControllers.values]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    final percentages = <String, double>{};
    final amounts = <String, double>{};
    for (final member in widget.members) {
      final id = member['userId']?.toString() ?? '';
      final percentageText = _percentageControllers[id]!.text.trim();
      final amountText = _amountControllers[id]!.text.trim();
      if (percentageText.isNotEmpty && amountText.isNotEmpty) {
        setState(() => _error = 'Use either percentage or amount for each member');
        return;
      }
      if (percentageText.isNotEmpty) {
        final percentage = double.tryParse(percentageText);
        if (percentage == null || percentage < 0 || percentage > 100) {
          setState(() => _error = 'Each percentage must be between 0 and 100');
          return;
        }
        percentages[id] = percentage;
      } else if (amountText.isNotEmpty) {
        final amount = double.tryParse(amountText);
        if (amount == null || amount < 0) {
          setState(() => _error = 'Each amount must be zero or greater');
          return;
        }
        amounts[id] = amount;
      }
    }
    final total = percentages.values.fold<double>(
      0,
      (sum, percentage) => sum + percentage,
    );
    final allocatedAmount = amounts.values.fold<double>(
      0,
      (sum, amount) => sum + amount,
    );
    final percentageAmount = widget.budgetAmount * total / 100;
    if (total > 100) {
      setState(() => _error = 'Fixed percentages cannot exceed 100%');
      return;
    }
    if (allocatedAmount + percentageAmount > widget.budgetAmount) {
      setState(() => _error = 'Fixed allocations cannot exceed the budget amount');
      return;
    }
    Navigator.pop(context, {'percentages': percentages, 'amounts': amounts});
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: AlertDialog(
    titlePadding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
    title: Row(
      children: [
        const Expanded(child: Text('Advanced split')),
        TextButton.icon(
          onPressed: _setAllAuto,
          icon: const Icon(Icons.autorenew, size: 17),
          label: const Text('Auto split'),
          style: TextButton.styleFrom(foregroundColor: _orange),
        ),
      ],
    ),
    content: SizedBox(
      width: double.maxFinite,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a percentage or an allocated amount. Blank members share the remaining amount equally.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 14),
            ...widget.members.map(
              (member) {
                final id = member['userId']?.toString() ?? '';
                final mode = _modes[id] ?? 'auto';
                final input = mode == 'percentage'
                    ? TextField(
                        controller: _percentageControllers[id],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          suffixText: '%',
                          hintText: 'Percentage',
                          isDense: true,
                        ),
                      )
                    : mode == 'amount'
                    ? TextField(
                        controller: _amountControllers[id],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          prefixText: 'Rs ',
                          hintText: 'Amount',
                          isDense: true,
                        ),
                      )
                    : const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Auto',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          member['name']?.toString() ?? 'Member',
                          style: const TextStyle(color: Color(0xFF172C57)),
                        ),
                      ),
                      SizedBox(width: 112, child: input),
                      IconButton(
                        onPressed: () => _chooseMode(id),
                        icon: const Icon(Icons.call_split, size: 20),
                        color: const Color(0xFF5066A0),
                        tooltip: 'Choose split type',
                      ),
                    ],
                  ),
                );
              },
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
        style: TextButton.styleFrom(foregroundColor: _navy),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _save,
        style: FilledButton.styleFrom(
          backgroundColor: _navy,
          foregroundColor: Colors.white,
        ),
        child: const Text('Done'),
      ),
    ],
    ),
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
