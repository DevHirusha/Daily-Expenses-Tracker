import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final String token;

  const AddExpenseScreen({super.key, required this.token});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _picker = ImagePicker();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  XFile? _proof;
  DateTime? _startDate;
  DateTime? _endDate;
  Map<String, dynamic>? _selectedGroup;
  List<Map<String, dynamic>> _groups = const [];
  List<Map<String, dynamic>> _friends = const [];
  Set<String> _groupMemberIds = {};
  Set<String> _selectedMemberIds = {};
  Map<String, String> _memberNames = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPeople();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadPeople() async {
    try {
      final results = await Future.wait([
        ApiService.getGroups(token: widget.token),
        ApiService.getFriends(token: widget.token),
      ]);
      if (!mounted) return;
      setState(() {
        _groups = results[0];
        _friends = results[1];
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = date;
        if (_endDate != null && _endDate!.isBefore(date)) _endDate = date;
      } else {
        _endDate = date;
      }
    });
  }

  Future<void> _chooseGroup() async {
    if (_isLoading) return;
    final group = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (context) => SafeArea(
        child: _groups.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('You are not a member of any group yet.'),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: _groups
                    .map(
                      (group) => ListTile(
                        leading: const Icon(
                          Icons.groups_outlined,
                          color: Color(0xFFF47C20),
                        ),
                        title: Text(group['name']?.toString() ?? 'Group'),
                        subtitle: Text('${group['memberCount'] ?? 0} people'),
                        onTap: () => Navigator.pop(context, group),
                      ),
                    )
                    .toList(),
              ),
      ),
    );
    if (group == null || !mounted) return;
    await _selectGroupMembers(group);
  }

  Future<void> _selectGroupMembers(Map<String, dynamic> group) async {
    try {
      final members = await ApiService.getGroupMembers(
        token: widget.token,
        groupId: (group['id'] as num).toInt(),
      );
      if (!mounted) return;
      final selected = await showDialog<Set<String>>(
        context: context,
        builder: (context) => _GroupMembersDialog(members: members),
      );
      if (selected == null || !mounted) return;
      setState(() {
        _selectedGroup = group;
        _groupMemberIds = members
            .map((member) => member['userId']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();
        _selectedMemberIds = selected;
        _memberNames = {
          for (final member in members)
            member['userId']?.toString() ?? '':
                member['name']?.toString() ??
                member['username']?.toString() ??
                'Member',
        };
      });
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _addMembers() async {
    if (_selectedGroup == null) {
      _showMessage('Select a group first');
      return;
    }
    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _FriendsDialog(
        friends: _friends,
        groupMemberIds: _groupMemberIds,
        selectedIds: _selectedMemberIds,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedMemberIds = selected;
      _memberNames.addEntries(
        _friends
            .where((friend) => selected.contains(friend['userId']?.toString()))
            .map(
              (friend) => MapEntry(
                friend['userId']?.toString() ?? '',
                friend['name']?.toString() ??
                    friend['username']?.toString() ??
                    'Member',
              ),
            ),
      );
    });
  }

  Future<void> _saveBudget() async {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (name.isEmpty || amount == null || amount <= 0) {
      _showMessage('Enter an expense name and a valid amount');
      return;
    }
    setState(() => _isSaving = true);
    try {
      String? proofData;
      if (_proof != null) {
        proofData = base64Encode(await _proof!.readAsBytes());
      }
      await ApiService.createBudget(
        token: widget.token,
        name: name,
        amount: amount,
        startDate: _startDate,
        endDate: _endDate,
        groupId: (_selectedGroup?['id'] as num?)?.toInt(),
        memberUserIds: _selectedMemberIds.toList(),
        proofData: proofData,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _pickProof(ImageSource source) async {
    final image = await _picker.pickImage(source: source, imageQuality: 85);
    if (image != null && mounted) setState(() => _proof = image);
  }

  Future<void> _showProofOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(context);
                _pickProof(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickProof(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
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
          tooltip: 'Back',
        ),
        title: const Text(
          'Add expense',
          style: TextStyle(
            color: Color(0xFF172C57),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel('Expense name'),
              _ExpenseField(
                controller: _nameController,
                hint: 'What did you spend on?',
              ),
              const SizedBox(height: 14),
              const _FieldLabel('Amount'),
              _ExpenseField(
                controller: _amountController,
                hint: 'Rs 0.00',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              const _FieldLabel('Period'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _ChoiceTile(
                      icon: Icons.calendar_today_outlined,
                      label: _formatDate(_startDate, 'Start date'),
                      onTap: () => _pickDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ChoiceTile(
                      icon: Icons.calendar_today_outlined,
                      label: _formatDate(_endDate, 'End date'),
                      onTap: () => _pickDate(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const _FieldLabel('Group'),
              const SizedBox(height: 6),
              _ChoiceTile(
                icon: Icons.groups_outlined,
                label: _selectedGroup == null
                    ? 'Select group'
                    : '${_selectedGroup!['name']} (${_selectedMemberIds.length} people)',
                onTap: _chooseGroup,
              ),
              const SizedBox(height: 14),
              const _FieldLabel('Members'),
              const SizedBox(height: 6),
              _ChoiceTile(
                icon: Icons.person_add_alt_1_outlined,
                label: _selectedMemberIds.isEmpty
                    ? 'Add member'
                    : '${_selectedMemberIds.length} members selected',
                accent: true,
                onTap: _addMembers,
              ),
              if (_selectedMemberIds.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _selectedMemberIds
                      .map(
                        (id) => Chip(
                          label: Text(_memberNames[id] ?? 'Member'),
                          labelStyle: const TextStyle(
                            color: Color(0xFF172C57),
                            fontSize: 11,
                          ),
                          backgroundColor: Colors.white,
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 14),
              const _FieldLabel('Proof'),
              const SizedBox(height: 6),
              _ProofPicker(proof: _proof, onTap: _showProofOptions),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveBudget,
                  icon: const Icon(Icons.add),
                  label: const Text('Add expense'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    foregroundColor: Colors.white,
                    elevation: 0,
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

String _formatDate(DateTime? date, String fallback) {
  if (date == null) return fallback;
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(color: Color(0xFF7995C0), fontSize: 12),
  );
}

class _ExpenseField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  const _ExpenseField({
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF88A4CE), fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

class _GroupMembersDialog extends StatefulWidget {
  final List<Map<String, dynamic>> members;

  const _GroupMembersDialog({required this.members});

  @override
  State<_GroupMembersDialog> createState() => _GroupMembersDialogState();
}

class _GroupMembersDialogState extends State<_GroupMembersDialog> {
  late final Set<String> selectedIds = widget.members
      .map((member) => member['userId']?.toString() ?? '')
      .where((id) => id.isNotEmpty)
      .toSet();

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Select group members'),
    content: SizedBox(
      width: double.maxFinite,
      child: ListView(
        shrinkWrap: true,
        children: widget.members
            .map(
              (member) => CheckboxListTile(
                value: selectedIds.contains(member['userId']?.toString()),
                title: Text(member['name']?.toString() ?? 'Member'),
                subtitle: Text(member['email']?.toString() ?? ''),
                onChanged: (checked) => setState(() {
                  final id = member['userId']?.toString() ?? '';
                  if (checked == true) {
                    selectedIds.add(id);
                  } else {
                    selectedIds.remove(id);
                  }
                }),
              ),
            )
            .toList(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, selectedIds),
        child: const Text('Done'),
      ),
    ],
  );
}

class _FriendsDialog extends StatefulWidget {
  final List<Map<String, dynamic>> friends;
  final Set<String> groupMemberIds;
  final Set<String> selectedIds;

  const _FriendsDialog({
    required this.friends,
    required this.groupMemberIds,
    required this.selectedIds,
  });

  @override
  State<_FriendsDialog> createState() => _FriendsDialogState();
}

class _FriendsDialogState extends State<_FriendsDialog> {
  late final Set<String> selectedIds = {...widget.selectedIds};

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add members'),
    content: SizedBox(
      width: double.maxFinite,
      child: widget.friends.isEmpty
          ? const Text('No friends found.')
          : ListView(
              shrinkWrap: true,
              children: widget.friends.map((friend) {
                final id = friend['userId']?.toString() ?? '';
                final alreadyInGroup = widget.groupMemberIds.contains(id);
                final selected = selectedIds.contains(id);
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFE1C7),
                    child: Icon(Icons.person, color: Color(0xFFF47C20)),
                  ),
                  title: Text(friend['name']?.toString() ?? 'Friend'),
                  subtitle: Text(friend['email']?.toString() ?? ''),
                  trailing: alreadyInGroup
                      ? const Text(
                          'In group',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        )
                      : TextButton(
                          onPressed: () => setState(() {
                            if (selected) {
                              selectedIds.remove(id);
                            } else {
                              selectedIds.add(id);
                            }
                          }),
                          child: Text(selected ? 'Added' : 'Add'),
                        ),
                );
              }).toList(),
            ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, selectedIds),
        child: const Text('Done'),
      ),
    ],
  );
}

class _ChoiceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accent;

  const _ChoiceTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ? const Color(0xFFF47C20) : const Color(0xFF172C57);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: accent ? Border.all(color: const Color(0xFFF47C20)) : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, size: 19, color: const Color(0xFFF47C20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: accent ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: accent
                    ? const Color(0xFFF47C20)
                    : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProofPicker extends StatelessWidget {
  final XFile? proof;
  final VoidCallback onTap;

  const _ProofPicker({required this.proof, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: double.infinity,
          height: 150,
          child: proof == null
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      color: Color(0xFFF47C20),
                      size: 34,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add proof',
                      style: TextStyle(
                        color: Color(0xFF172C57),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tap to upload a photo',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ],
                )
              : FutureBuilder<Uint8List>(
                  future: proof!.readAsBytes(),
                  builder: (context, snapshot) => snapshot.hasData
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),
        ),
      ),
    );
  }
}
