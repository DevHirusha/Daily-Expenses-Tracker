import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String token;
  final int groupId;
  final String name;
  final String memberCount;
  final String joinCode;
  final bool isOwner;

  const GroupDetailsScreen({
    super.key,
    required this.token,
    required this.groupId,
    required this.name,
    required this.memberCount,
    required this.joinCode,
    required this.isOwner,
  });

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  late String _joinCode;
  bool _isResettingCode = false;

  @override
  void initState() {
    super.initState();
    _joinCode = widget.joinCode;
  }

  Future<void> _showMembers() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _MembersDialog(
        token: widget.token,
        groupId: widget.groupId,
        isOwner: widget.isOwner,
      ),
    );
  }

  Future<void> _leaveGroup() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave group?'),
        content: const Text('You will no longer have access to this group.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (shouldLeave != true || !mounted) return;

    try {
      await ApiService.leaveGroup(token: widget.token, groupId: widget.groupId);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _copyLink() {
    Clipboard.setData(
      ClipboardData(text: 'daily-expenses://group/$_joinCode'),
    );
    _showMessage('Group link copied', isError: false);
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _joinCode));
    _showMessage('Join code copied', isError: false);
  }

  Future<void> _resetJoinCode() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset join code?'),
        content: const Text(
          'The current QR code and link will stop working for new members.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (shouldReset != true || !mounted) return;

    setState(() => _isResettingCode = true);
    try {
      final group = await ApiService.resetGroupJoinCode(
        token: widget.token,
        groupId: widget.groupId,
      );
      if (mounted) {
        setState(() {
          _joinCode = group['joinCode']?.toString() ?? _joinCode;
          _isResettingCode = false;
        });
        _showMessage('Join code reset', isError: false);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isResettingCode = false);
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
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
          'Group details',
          style: TextStyle(
            color: Color(0xFF172C57),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(9, 4, 9, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GroupHeader(name: widget.name, memberCount: widget.memberCount),
              const SizedBox(height: 12),
              _InviteCard(
                joinCode: _joinCode,
                onCopyCode: _copyCode,
                onCopy: _copyLink,
                canReset: widget.isOwner,
                isResetting: _isResettingCode,
                onReset: _resetJoinCode,
              ),
              const SizedBox(height: 12),
              _SettingsRow(
                icon: Icons.people_alt_outlined,
                label: 'View members',
                onTap: _showMembers,
              ),
              const SizedBox(height: 8),
              _SettingsRow(
                icon: Icons.settings,
                label: 'Group settings',
                onTap: () {},
              ),
              const SizedBox(height: 8),
              _SettingsRow(
                icon: Icons.logout,
                label: 'Leave group',
                onTap: _leaveGroup,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MembersDialog extends StatefulWidget {
  final String token;
  final int groupId;
  final bool isOwner;

  const _MembersDialog({
    required this.token,
    required this.groupId,
    required this.isOwner,
  });

  @override
  State<_MembersDialog> createState() => _MembersDialogState();
}

class _MembersDialogState extends State<_MembersDialog> {
  List<_Member> members = const [];
  List<_Member> friends = const [];
  bool isLoading = true;
  bool isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.getGroupMembers(
          token: widget.token,
          groupId: widget.groupId,
        ),
        ApiService.getFriends(token: widget.token),
      ]);
      if (!mounted) return;
      setState(() {
        members = results[0].map(_Member.fromJson).toList();
        friends = results[1].map(_Member.fromJson).toList();
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _addMember(_Member friend) async {
    setState(() => isAdding = true);
    try {
      await ApiService.addGroupMember(
        token: widget.token,
        groupId: widget.groupId,
        userId: friend.userId,
      );
      await _loadData();
      _showMessage('${friend.name} added to the group', isError: false);
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => isAdding = false);
    }
  }

  Future<void> _removeMember(_Member member) async {
    try {
      await ApiService.removeGroupMember(
        token: widget.token,
        groupId: widget.groupId,
        userId: member.userId,
      );
      await _loadData();
      _showMessage('${member.name} removed', isError: false);
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memberIds = members.map((member) => member.userId).toSet();
    final availableFriends = friends
        .where((friend) => !memberIds.contains(friend.userId))
        .toList();

    return AlertDialog(
      title: const Text('Group members'),
      content: SizedBox(
        width: double.maxFinite,
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...members.map(
                      (member) => _MemberRow(
                        member: member,
                        canRemove: widget.isOwner && member.role != 'OWNER',
                        onRemove: () => _removeMember(member),
                      ),
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Add from friends',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (availableFriends.isEmpty)
                      const Text('All your friends are already in this group.')
                    else
                      ...availableFriends.map(
                        (friend) => _FriendToAddRow(
                          member: friend,
                          isAdding: isAdding,
                          onAdd: () => _addMember(friend),
                        ),
                      ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _Member {
  final String userId;
  final String name;
  final String username;
  final String role;

  const _Member({
    required this.userId,
    required this.name,
    required this.username,
    required this.role,
  });

  factory _Member.fromJson(Map<String, dynamic> json) {
    final username = json['username']?.toString() ?? '';
    return _Member(
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? username,
      username: username,
      role: json['role']?.toString() ?? 'MEMBER',
    );
  }
}

class _MemberRow extends StatelessWidget {
  final _Member member;
  final bool canRemove;
  final VoidCallback onRemove;

  const _MemberRow({
    required this.member,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF294C88),
        child: Text(
          member.name.substring(0, 1).toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(member.name),
      subtitle: Text('@${member.username}'),
      trailing: canRemove
          ? IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.person_remove_outlined, color: Colors.red),
              tooltip: 'Remove member',
            )
          : Text(member.role == 'OWNER' ? 'Owner' : 'Member'),
    );
  }
}

class _FriendToAddRow extends StatelessWidget {
  final _Member member;
  final bool isAdding;
  final VoidCallback onAdd;

  const _FriendToAddRow({
    required this.member,
    required this.isAdding,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        child: Text(member.name.substring(0, 1).toUpperCase()),
      ),
      title: Text(member.name),
      subtitle: Text('@${member.username}'),
      trailing: IconButton(
        onPressed: isAdding ? null : onAdd,
        icon: const Icon(Icons.person_add_alt_1),
        tooltip: 'Add member',
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String name;
  final String memberCount;

  const _GroupHeader({required this.name, required this.memberCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1D3D73),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFF234B88),
            child: Icon(Icons.groups, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$memberCount • Active',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  final String joinCode;
  final VoidCallback onCopyCode;
  final VoidCallback onCopy;
  final bool canReset;
  final bool isResetting;
  final VoidCallback onReset;

  const _InviteCard({
    required this.joinCode,
    required this.onCopyCode,
    required this.onCopy,
    required this.canReset,
    required this.isResetting,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFDDE6FA),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          const Text(
            'JOIN CODE',
            style: TextStyle(color: Color(0xFF7895C0), fontSize: 12),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                joinCode,
                style: const TextStyle(
                  color: Color(0xFF172C57),
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              IconButton(
                onPressed: onCopyCode,
                icon: const Icon(Icons.copy_outlined, size: 18),
                color: const Color(0xFF31558F),
                visualDensity: VisualDensity.compact,
                tooltip: 'Copy join code',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Scan to join',
            style: TextStyle(color: Color(0xFF7895C0), fontSize: 12),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: QrImageView(
              data: 'daily-expenses://group/$joinCode',
              size: 92,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_outlined, size: 16),
            label: const Text('Copy link'),
          ),
          if (canReset) ...[
            const SizedBox(height: 2),
            TextButton.icon(
              onPressed: isResetting ? null : onReset,
              icon: isResetting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 16),
              label: const Text('Reset code'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF17427F), size: 21),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF17427F),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF7FA1D4)),
            ],
          ),
        ),
      ),
    );
  }
}
