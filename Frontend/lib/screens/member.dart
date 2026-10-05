import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'add_member.dart';
import 'crate_group.dart';
import 'friendlist.dart';
import 'group.dart';

class MembersScreen extends StatefulWidget {
  final String token;

  const MembersScreen({super.key, required this.token});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  List<_Group> groups = const [];
  bool isLoading = true;
  bool isJoining = false;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      final result = await ApiService.getGroups(token: widget.token);
      if (!mounted) return;
      setState(() {
        groups = result.map(_Group.fromJson).toList();
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _openCreateGroup() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CreateGroupScreen(token: widget.token)),
    );
    if (created == true) _loadGroups();
  }

  Future<void> _openJoinGroup() async {
    final controller = TextEditingController();
    final joinCode = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Join a group'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Join code',
            hintText: 'Enter or paste the code',
            suffixIcon: IconButton(
              tooltip: 'Paste join code',
              icon: const Icon(Icons.content_paste),
              onPressed: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data?.text != null) controller.text = data!.text!.trim();
              },
            ),
          ),
          onSubmitted: (_) => Navigator.pop(
            dialogContext,
            controller.text.trim().toUpperCase(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final code = controller.text.trim().toUpperCase();
              if (code.isNotEmpty) Navigator.pop(dialogContext, code);
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (joinCode == null || joinCode.isEmpty || !mounted) return;

    setState(() => isJoining = true);
    try {
      final group = await ApiService.joinGroup(
        token: widget.token,
        joinCode: joinCode,
      );
      await _loadGroups();
      if (mounted) {
        setState(() => isJoining = false);
        await _showJoinedDialog(group['name']?.toString() ?? 'the group');
      }
    } catch (error) {
      if (mounted) {
        setState(() => isJoining = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showJoinedDialog(String groupName) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Text('🎉', style: TextStyle(fontSize: 26)),
            SizedBox(width: 10),
            Expanded(child: Text('Welcome!')),
          ],
        ),
        content: Text('You joined $groupName successfully.'),
        actions: [
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.groups),
            label: const Text('Open groups'),
          ),
        ],
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
          'Members',
          style: TextStyle(
            color: Color(0xFF172C57),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Add Friends',
                      icon: Icons.add,
                      backgroundColor: const Color(0xFF172C57),
                      foregroundColor: Colors.white,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddMemberScreen(token: widget.token),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      label: 'Join Group',
                      icon: Icons.people_alt_outlined,
                      backgroundColor: Color(0xFFF47C20),
                      foregroundColor: Colors.white,
                      onTap: isJoining ? null : _openJoinGroup,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _MenuRow(
                icon: Icons.people_alt_outlined,
                label: 'See Friends',
                iconBackground: const Color(0xFFE1E8FA),
                iconColor: const Color(0xFF172C57),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FriendListScreen(token: widget.token),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Your in group',
                    style: TextStyle(
                      color: Color(0xFF172C57),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _SmallButton(
                    label: 'New',
                    icon: Icons.add,
                    onTap: _openCreateGroup,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (groups.isEmpty)
                const _EmptyGroups()
              else
                ...groups.map(
                  (group) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _GroupCard(
                      name: group.name,
                      details: '${group.memberCount} members • Active',
                      icon: Icons.groups_outlined,
                      iconBackground: const Color(0xFFE1E8FA),
                      iconColor: const Color(0xFF5A8DEE),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupDetailsScreen(
                            token: widget.token,
                            groupId: group.id,
                            name: group.name,
                            memberCount: '${group.memberCount} members',
                            joinCode: group.joinCode,
                            isOwner: group.isOwner,
                          ),
                        ),
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

class _Group {
  final int id;
  final String name;
  final String joinCode;
  final int memberCount;
  final bool isOwner;

  const _Group({
    required this.id,
    required this.name,
    required this.joinCode,
    required this.memberCount,
    required this.isOwner,
  });

  factory _Group.fromJson(Map<String, dynamic> json) {
    return _Group(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? 'Unnamed group',
      joinCode: json['joinCode']?.toString() ?? '',
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      isOwner: json['owner'] == true,
    );
  }
}

class _EmptyGroups extends StatelessWidget {
  const _EmptyGroups();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          'No groups yet. Create one to get started.',
          style: TextStyle(color: Color(0xFF7890B8)),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 19),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SmallButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF172C57),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconBackground;
  final Color iconColor;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.iconBackground,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: iconBackground,
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF172C57),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final String name;
  final String details;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final VoidCallback onTap;

  const _GroupCard({
    required this.name,
    required this.details,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: iconBackground,
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Color(0xFF172C57),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      details,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}
