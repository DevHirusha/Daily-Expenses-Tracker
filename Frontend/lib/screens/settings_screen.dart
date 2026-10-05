import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final String email;

  const SettingsScreen({super.key, required this.email});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;

  String get _displayName {
    final value = widget.email.split('@').first.replaceAll(RegExp(r'[._-]'), ' ');
    if (value.isEmpty) return 'Your profile';
    return value
        .split(' ')
        .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _darkMode ? Colors.white : const Color(0xFF172C57);
    final mutedColor = _darkMode ? Colors.white70 : const Color(0xFF8B9BC1);
    final background = _darkMode ? const Color(0xFF17233D) : const Color(0xFFE8ECFA);
    final cardColor = _darkMode ? const Color(0xFF243452) : Colors.white;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          onPressed: () {},
          icon: Icon(Icons.arrow_back, color: textColor),
          tooltip: 'Back',
        ),
        title: Text(
          'Settings',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileCard(
                name: _displayName,
                email: widget.email,
                background: cardColor,
                textColor: textColor,
                mutedColor: mutedColor,
              ),
              const SizedBox(height: 20),
              _SectionLabel(label: 'ACCOUNT', color: mutedColor),
              const SizedBox(height: 6),
              _SettingsGroup(
                background: cardColor,
                textColor: textColor,
                mutedColor: mutedColor,
                rows: [
                  _SettingData(Icons.person_outline, 'Personal Information', 'Manage your personal details & contacts'),
                  _SettingData(Icons.shield_outlined, 'Security', 'Change password & manage security'),
                  _SettingData(Icons.notifications_none, 'Notifications', 'Manage your alerts and reminders'),
                ],
              ),
              const SizedBox(height: 20),
              _SectionLabel(label: 'PREFERENCES', color: mutedColor),
              const SizedBox(height: 6),
              _SettingsGroup(
                background: cardColor,
                textColor: textColor,
                mutedColor: mutedColor,
                rows: [
                  _SettingData(Icons.palette_outlined, 'Appearance', 'Light / Dark mode and theme'),
                  _SettingData(Icons.language, 'Language', 'Select your preferred language', trailing: 'English'),
                  _SettingData(Icons.dark_mode_outlined, 'Dark Mode', 'Enable dark theme aesthetics', toggle: true),
                ],
                onToggle: (index) {
                  if (index == 2) setState(() => _darkMode = !_darkMode);
                },
                darkMode: _darkMode,
              ),
              const SizedBox(height: 20),
              _SectionLabel(label: 'SUPPORT & INFO', color: mutedColor),
              const SizedBox(height: 6),
              _SettingsGroup(
                background: cardColor,
                textColor: textColor,
                mutedColor: mutedColor,
                rows: [
                  _SettingData(Icons.headset_mic_outlined, 'Help & Support', 'Get help or contact us'),
                  _SettingData(Icons.description_outlined, 'Terms & Privacy', 'Read our terms and privacy policy'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String name;
  final String email;
  final Color background;
  final Color textColor;
  final Color mutedColor;

  const _ProfileCard({required this.name, required this.email, required this.background, required this.textColor, required this.mutedColor});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty ? 'U' : name.trim().split(' ').map((part) => part[0]).take(2).join().toUpperCase();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(19)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFFF47C20),
            child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(email, overflow: TextOverflow.ellipsis, style: TextStyle(color: mutedColor, fontSize: 11)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: const Color(0xFFFFDEC7), borderRadius: BorderRadius.circular(12)),
            child: const Text('PRO', style: TextStyle(color: Color(0xFFF47C20), fontSize: 9, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold));
}

class _SettingData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;
  final bool toggle;

  const _SettingData(this.icon, this.title, this.subtitle, {this.trailing, this.toggle = false});
}

class _SettingsGroup extends StatelessWidget {
  final Color background;
  final Color textColor;
  final Color mutedColor;
  final List<_SettingData> rows;
  final ValueChanged<int>? onToggle;
  final bool darkMode;

  const _SettingsGroup({required this.background, required this.textColor, required this.mutedColor, required this.rows, this.onToggle, this.darkMode = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(19)),
      child: Column(
        children: List.generate(rows.length, (index) {
          final row = rows[index];
          return Column(
            children: [
              InkWell(
                onTap: row.toggle && onToggle != null ? () => onToggle!(index) : () {},
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: _iconBackground(row.icon),
                        child: Icon(row.icon, color: _iconColor(row.icon), size: 19),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(row.title, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(row.subtitle, style: TextStyle(color: mutedColor, fontSize: 11)),
                        ]),
                      ),
                      if (row.trailing != null)
                        Text(row.trailing!, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold)),
                      if (row.toggle)
                        Switch.adaptive(
                          value: darkMode,
                          onChanged: (_) => onToggle?.call(index),
                          activeColor: const Color(0xFFF47C20),
                        )
                      else
                        Icon(Icons.chevron_right, color: mutedColor, size: 21),
                    ],
                  ),
                ),
              ),
              if (index < rows.length - 1) Divider(height: 1, color: mutedColor.withOpacity(.25)),
            ],
          );
        }),
      ),
    );
  }

  Color _iconBackground(IconData icon) {
    if (icon == Icons.shield_outlined) return const Color(0xFFDDF4ED);
    if (icon == Icons.notifications_none) return const Color(0xFFFFE9DF);
    if (icon == Icons.palette_outlined) return const Color(0xFFEAE6FF);
    if (icon == Icons.language) return const Color(0xFFDFF4F5);
    return const Color(0xFFE3EFFD);
  }

  Color _iconColor(IconData icon) {
    if (icon == Icons.shield_outlined) return const Color(0xFF24A879);
    if (icon == Icons.notifications_none) return const Color(0xFFF47C20);
    if (icon == Icons.palette_outlined) return const Color(0xFF8066E8);
    if (icon == Icons.language) return const Color(0xFF12A6B0);
    return const Color(0xFF3286E5);
  }
}
