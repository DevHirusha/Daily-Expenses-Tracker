import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AnnouncementsScreen extends StatefulWidget {
  final String token;

  const AnnouncementsScreen({super.key, required this.token});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  List<Map<String, dynamic>> _announcements = const [];
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _error;

  int get _unreadCount => _announcements
      .where((announcement) => announcement['read'] != true)
      .length;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final announcements = await ApiService.getAnnouncements(
        token: widget.token,
      );
      if (!mounted) return;
      setState(() {
        _announcements = announcements;
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

  Future<void> _markAllAsRead() async {
    if (_unreadCount == 0 || _isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await ApiService.markAllAnnouncementsRead(token: widget.token);
      if (!mounted) return;
      setState(() {
        _announcements = _announcements
            .map((announcement) => {...announcement, 'read': true})
            .toList();
        _isUpdating = false;
      });
      _showMessage('All announcements marked as read.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isUpdating = false);
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _clearAll() async {
    if (_announcements.isEmpty || _isUpdating) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text(
          'These announcements will be removed from your notification list. New announcements will still appear.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD9544D),
            ),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isUpdating = true);
    try {
      await ApiService.clearAllAnnouncements(token: widget.token);
      if (!mounted) return;
      setState(() {
        _announcements = const [];
        _isUpdating = false;
      });
      _showMessage('Notifications cleared.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isUpdating = false);
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF172C57);
    const orange = Color(0xFFF47C20);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: navy),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: navy, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadAnnouncements,
            tooltip: 'Refresh notifications',
            icon: const Icon(Icons.refresh_rounded, color: navy),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: orange,
          onRefresh: _loadAnnouncements,
          child: _isLoading
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 260),
                    Center(child: CircularProgressIndicator(color: orange)),
                  ],
                )
              : _error != null
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(22),
                  children: [
                    const SizedBox(height: 120),
                    _EmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: 'Could not load updates',
                      message: _error!,
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: _loadAnnouncements,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try again'),
                      ),
                    ),
                  ],
                )
              : _announcements.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(22),
                  children: const [
                    SizedBox(height: 135),
                    _EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'You are all caught up',
                      message:
                          'New announcements from the team will appear here.',
                    ),
                  ],
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                  children: [
                    _AnnouncementSummary(
                      count: _announcements.length,
                      unreadCount: _unreadCount,
                      isUpdating: _isUpdating,
                      onMarkAllRead: _markAllAsRead,
                      onClearAll: _clearAll,
                    ),
                    const SizedBox(height: 18),
                    ..._announcements.map(
                      (announcement) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AnnouncementCard(announcement: announcement),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _AnnouncementSummary extends StatelessWidget {
  final int count;
  final int unreadCount;
  final bool isUpdating;
  final VoidCallback onMarkAllRead;
  final VoidCallback onClearAll;

  const _AnnouncementSummary({
    required this.count,
    required this.unreadCount,
    required this.isUpdating,
    required this.onMarkAllRead,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF244C90), Color(0xFF172C57)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.campaign_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Updates from the team',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count ${count == 1 ? 'announcement' : 'announcements'}',
                      style: const TextStyle(
                        color: Color(0xFFB9C9E8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isUpdating || unreadCount == 0
                      ? null
                      : onMarkAllRead,
                  icon: const Icon(Icons.done_all_rounded, size: 16),
                  label: Text(unreadCount == 0 ? 'All read' : 'Mark all read'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white54,
                    side: BorderSide(color: Colors.white.withValues(alpha: .3)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: TextButton.icon(
                  onPressed: isUpdating ? null : onClearAll,
                  icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                  label: const Text('Clear all'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFFC1A0),
                    disabledForegroundColor: Colors.white38,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> announcement;

  const _AnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final title = announcement['title']?.toString() ?? 'Announcement';
    final message = announcement['message']?.toString() ?? '';
    final createdAt = announcement['createdAt']?.toString();
    final creator = announcement['createdByName']?.toString();

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172C57).withValues(alpha: .05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE9DF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.campaign_outlined,
                  color: Color(0xFFF47C20),
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF172C57),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF53678F),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                color: Color(0xFF9AA8C1),
                size: 14,
              ),
              const SizedBox(width: 5),
              Text(
                _formatDate(createdAt),
                style: const TextStyle(color: Color(0xFF9AA8C1), fontSize: 11),
              ),
              if (creator != null && creator.trim().isNotEmpty) ...[
                const SizedBox(width: 10),
                const Text('•', style: TextStyle(color: Color(0xFFB4BFD0))),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'By $creator',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9AA8C1),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String? value) {
    final date = DateTime.tryParse(value ?? '')?.toLocal();
    if (date == null) return 'Recently';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFE7EDF8),
            borderRadius: BorderRadius.circular(23),
          ),
          child: Icon(icon, color: const Color(0xFF6980A8), size: 34),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF172C57),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF8292B4), fontSize: 13),
        ),
      ],
    );
  }
}
