import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../services/api_service.dart';

class SharedWithMeScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> budget;

  const SharedWithMeScreen({
    super.key,
    required this.token,
    required this.budget,
  });

  @override
  State<SharedWithMeScreen> createState() => _SharedWithMeScreenState();
}

class _SharedWithMeScreenState extends State<SharedWithMeScreen> {
  List<Map<String, dynamic>> _members = const [];
  Map<String, dynamic>? _mySettlement;
  bool _isLoading = true;
  bool _isSaving = false;

  int get _budgetId => (widget.budget['id'] as num).toInt();
  double get _amount => (widget.budget['amount'] as num?)?.toDouble() ?? 0;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _loadSettlement();
  }

  Future<void> _loadSettlement() async {
    try {
      final settlements = await ApiService.getBudgetSettlements(
        token: widget.token,
        budgetId: _budgetId,
      );
      if (!mounted) return;
      setState(() {
        _mySettlement = settlements.cast<Map<String, dynamic>?>().firstWhere(
          (settlement) => settlement?['currentUser'] == true,
          orElse: () => null,
        );
      });
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
      _message(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _settle() async {
    final settlement = await showDialog<_SettlementDraft>(
      context: context,
      builder: (context) => const _SettlementDialog(),
    );
    if (settlement == null || !mounted) return;
    setState(() => _isSaving = true);
    try {
      await ApiService.saveBudgetSettlement(
        token: widget.token,
        budgetId: _budgetId,
        amount: settlement.amount,
        proofData: settlement.proofData,
      );
      await _loadSettlement();
      if (mounted) _message('Settlement saved');
    } catch (error) {
      if (mounted) _message(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _paymentNotice() {
    final payable = (widget.budget['payableAmount'] as num?)?.toDouble() ?? 0;
    final settlement = _mySettlement;
    final owner = widget.budget['ownerName']?.toString() ?? 'the budget owner';
    if (settlement == null) {
      return _PaymentNotice(
        text: 'You need to pay Rs ${payable.toStringAsFixed(2)} to $owner',
        complete: false,
      );
    }
    final paid = (settlement['amount'] as num?)?.toDouble() ?? 0;
    final remaining = (settlement['remainingAmount'] as num?)?.toDouble() ?? 0;
    final complete = settlement['fullyPaid'] == true;
    return _PaymentNotice(
      text: complete
          ? 'Payment complete. You paid Rs ${paid.toStringAsFixed(2)} to $owner.'
          : 'You paid Rs ${paid.toStringAsFixed(2)}. Remaining Rs ${remaining.toStringAsFixed(2)} to $owner.',
      complete: complete,
    );
  }

  void _showFullProof(String proofData) {
    final encoded = proofData.contains(',')
        ? proofData.substring(proofData.indexOf(',') + 1)
        : proofData;
    final isPdf =
        proofData.startsWith('data:application/pdf') ||
        proofData.startsWith('JVBER');
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isPdf ? Colors.white : Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: isPdf
            ? SizedBox(
                width: double.maxFinite,
                height: 620,
                child: SfPdfViewer.memory(base64Decode(encoded)),
              )
            : Stack(
                children: [
                  InteractiveViewer(
                    child: Image.memory(
                      base64Decode(encoded),
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  double _percentageFor(Map<String, dynamic> member) {
    final split = widget.budget['splitPercentages'];
    final overrides = <String, double>{};
    if (split is String && split.isNotEmpty) {
      final decoded = jsonDecode(split);
      if (decoded is Map) {
        overrides.addAll(
          decoded.map(
            (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
          ),
        );
      }
    }
    final id = member['userId']?.toString() ?? '';
    if (overrides.containsKey(id)) return overrides[id]!;
    final flexible = _members.where(
      (item) => !overrides.containsKey(item['userId']?.toString()),
    );
    final fixed = overrides.values.fold<double>(0, (sum, value) => sum + value);
    return flexible.isEmpty ? 0 : (100 - fixed) / (flexible.length + 1);
  }

  String _date(String key) {
    final value = widget.budget[key]?.toString();
    if (value == null || value.isEmpty || value == 'null') return 'Not set';
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final proof = widget.budget['proofData']?.toString();
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
          widget.budget['name']?.toString() ?? 'Shared budget',
          style: const TextStyle(
            color: Color(0xFF172C57),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BudgetHeader(
                name: widget.budget['name']?.toString() ?? 'Shared budget',
                amount: _amount,
                startDate: _date('startDate'),
                endDate: _date('endDate'),
              ),
              const SizedBox(height: 16),
              _ProofPreview(proofData: proof),
              const SizedBox(height: 16),
              _paymentNotice(),
              const SizedBox(height: 16),
              _Notice(
                text: _isLoading
                    ? 'Loading payment shares...'
                    : 'Who pays and how much to ${widget.budget['ownerName']?.toString() ?? 'the budget owner'}',
              ),
              const SizedBox(height: 8),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_members.isEmpty)
                const _EmptyMembers()
              else
                ..._members.map(
                  (member) => _PayRow(
                    name: member['name']?.toString() ?? 'Member',
                    percentage: _percentageFor(member),
                    amount: _amount * _percentageFor(member) / 100,
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _settle,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(_isSaving ? 'Uploading...' : 'Add settlement'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: const Color(0xFF172C57),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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

class _BudgetHeader extends StatelessWidget {
  final String name;
  final double amount;
  final String startDate;
  final String endDate;

  const _BudgetHeader({
    required this.name,
    required this.amount,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
    decoration: BoxDecoration(
      color: const Color(0xFF1D3D73),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        Text(
          'Rs ${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Period  $startDate  -  $endDate',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    ),
  );
}

class _ProofPreview extends StatelessWidget {
  final String? proofData;

  const _ProofPreview({required this.proofData});

  @override
  Widget build(BuildContext context) {
    final hasProof = proofData != null && proofData!.isNotEmpty;
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: hasProof
            ? () =>
                  (context.findAncestorStateOfType<_SharedWithMeScreenState>())
                      ?._showFullProof(proofData!)
            : null,
        child: Container(
          width: 230,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              if (hasProof)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    base64Decode(proofData!),
                    width: 82,
                    height: 82,
                    fit: BoxFit.cover,
                  ),
                )
              else
                const Icon(
                  Icons.image_outlined,
                  color: Color(0xFF94A3B8),
                  size: 48,
                ),
              const SizedBox(width: 12),
              Text(
                hasProof ? 'Budget proof' : 'No budget proof',
                style: const TextStyle(
                  color: Color(0xFF172C57),
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

class _Notice extends StatelessWidget {
  final String text;

  const _Notice({required this.text});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF172C57),
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  );
}

class _PaymentNotice extends StatelessWidget {
  final String text;
  final bool complete;

  const _PaymentNotice({required this.text, required this.complete});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    decoration: BoxDecoration(
      color: complete ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E6),
      border: Border.all(
        color: complete ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: complete ? const Color(0xFF15803D) : const Color(0xFFDC2626),
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class _PayRow extends StatelessWidget {
  final String name;
  final double percentage;
  final double amount;

  const _PayRow({
    required this.name,
    required this.percentage,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: const Color(0xFFFFE1C7),
          child: Text(
            name[0].toUpperCase(),
            style: const TextStyle(color: Color(0xFFF47C20)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(name, style: const TextStyle(color: Color(0xFF172C57))),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(color: Color(0xFFF47C20), fontSize: 11),
            ),
            Text(
              'Rs ${amount.toStringAsFixed(2)}',
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
}

class _EmptyMembers extends StatelessWidget {
  const _EmptyMembers();

  @override
  Widget build(BuildContext context) => const Text(
    'No members were added to this budget.',
    style: TextStyle(color: Color(0xFF94A3B8)),
  );
}

class _SettlementDialog extends StatefulWidget {
  const _SettlementDialog();

  @override
  State<_SettlementDialog> createState() => _SettlementDialogState();
}

class _SettlementDraft {
  final double amount;
  final String proofData;

  const _SettlementDraft({required this.amount, required this.proofData});
}

class _SettlementDialogState extends State<_SettlementDialog> {
  XFile? _proof;
  bool _isPicking = false;
  final _amountController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() => _isPicking = true);
    final proof = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (mounted) {
      setState(() {
        _proof = proof;
        _isPicking = false;
      });
    }
  }

  Future<void> _done() async {
    final proof = _proof;
    if (proof == null) return;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter the amount you paid');
      return;
    }
    final data = base64Encode(await proof.readAsBytes());
    if (mounted) {
      Navigator.pop(context, _SettlementDraft(amount: amount, proofData: data));
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add settlement proof'),
    content: SizedBox(
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_proof == null)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text('Upload a photo showing your payment.'),
            )
          else
            FutureBuilder<Uint8List>(
              future: _proof!.readAsBytes(),
              builder: (context, snapshot) => snapshot.hasData
                  ? Image.memory(snapshot.data!, height: 150, fit: BoxFit.cover)
                  : const CircularProgressIndicator(),
            ),
          const SizedBox(height: 10),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount paid',
              prefixText: 'Rs ',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _isPicking ? null : _pick,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choose proof photo'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _proof == null ? null : _done,
        child: const Text('Done'),
      ),
    ],
  );
}
