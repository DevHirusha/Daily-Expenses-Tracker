import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GroupDetailsScreen extends StatelessWidget {
  final String name;
  final String memberCount;
  final String description;
  final String joinCode;

  const GroupDetailsScreen({
    super.key,
    required this.name,
    required this.memberCount,
    required this.description,
    required this.joinCode,
  });

  void _copyLink(BuildContext context) {
    Clipboard.setData(
      ClipboardData(text: 'daily-expenses://group/$joinCode'),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Group link copied')),
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
              _GroupHeader(name: name, memberCount: memberCount),
              const SizedBox(height: 12),
              _DescriptionCard(name: name, description: description),
              const SizedBox(height: 12),
              _InviteCard(joinCode: joinCode, onCopy: () => _copyLink(context)),
              const SizedBox(height: 12),
              _SettingsRow(
                icon: Icons.people_alt_outlined,
                label: 'View members',
                onTap: () {},
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
                onTap: () {},
              ),
            ],
          ),
        ),
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

class _DescriptionCard extends StatelessWidget {
  final String name;
  final String description;

  const _DescriptionCard({required this.name, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 21,
                backgroundColor: Color(0xFFE1E8FA),
                child: Icon(Icons.groups, color: Color(0xFF172C57)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Group name',
                    style: TextStyle(color: Color(0xFF7895C0), fontSize: 12),
                  ),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Color(0xFF172C57),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF7090C0),
              fontSize: 15,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  final String joinCode;
  final VoidCallback onCopy;

  const _InviteCard({required this.joinCode, required this.onCopy});

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
          Text(
            joinCode,
            style: const TextStyle(
              color: Color(0xFF172C57),
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _OutlineButton(
                  icon: Icons.copy_outlined,
                  label: 'Copy link',
                  onTap: onCopy,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OutlineButton(
                  icon: Icons.ios_share_outlined,
                  label: 'Share',
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
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
        ],
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF172C57),
        side: const BorderSide(color: Color(0xFF315589)),
        padding: const EdgeInsets.symmetric(vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
