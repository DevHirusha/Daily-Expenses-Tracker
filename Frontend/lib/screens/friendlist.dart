import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FriendListScreen extends StatefulWidget {
  final String token;

  const FriendListScreen({super.key, required this.token});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  int _selectedTab = 0;
  List<_Friend> _requests = const [];
  List<_Friend> _friends = const [];
  bool _isLoading = true;
  String? _updatingRequest;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getFriendRequests(token: widget.token),
        ApiService.getFriends(token: widget.token),
      ]);
      if (!mounted) return;
      setState(() {
        _requests = results[0].map(_Friend.fromJson).toList();
        _friends = results[1].map(_Friend.fromJson).toList();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _respondToRequest(_Friend friend, bool accept) async {
    final requestId = friend.requestId;
    if (requestId == null) return;
    setState(() => _updatingRequest = friend.requestId.toString());
    try {
      await ApiService.respondToFriendRequest(
        token: widget.token,
        requestId: requestId,
        accept: accept,
      );
      await _loadFriends();
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _updatingRequest = null);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF3FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF3FF),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF173B72)),
          tooltip: 'Back',
        ),
        title: const Text(
          'Friends',
          style: TextStyle(
            color: Color(0xFF173B72),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TabSelector(
                selectedTab: _selectedTab,
                requestCount: _requests.length,
                onChanged: (value) => setState(() => _selectedTab = value),
              ),
              const SizedBox(height: 14),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(36),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_selectedTab == 0) ...[
                _SectionHeader(
                  title: 'Friend Requests',
                  action: 'View all (${_requests.length})',
                ),
                const SizedBox(height: 8),
                ..._requests.map(_buildRequestCard),
                const SizedBox(height: 14),
                const _SectionHeader(title: 'Friends'),
                const SizedBox(height: 8),
                ..._friends.map(_buildFriendCard),
              ] else ...[
                const _SectionHeader(title: 'Friends'),
                const SizedBox(height: 8),
                ..._friends.map(_buildFriendCard),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(_Friend friend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _FriendAvatar(friend: friend, radius: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF173B72),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 14,
                      color: Color(0xFF7187A6),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      friend.detail,
                      style: const TextStyle(
                        color: Color(0xFF7187A6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _RequestButton(
            label: 'Accept',
            backgroundColor: const Color(0xFF1769FF),
            foregroundColor: Colors.white,
            onPressed: _updatingRequest == friend.requestId.toString()
                ? null
                : () => _respondToRequest(friend, true),
          ),
          const SizedBox(width: 6),
          _RequestButton(
            label: 'Decline',
            backgroundColor: const Color(0xFFEAF2FF),
            foregroundColor: const Color(0xFF42618E),
            onPressed: _updatingRequest == friend.requestId.toString()
                ? null
                : () => _respondToRequest(friend, false),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(_Friend friend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          _FriendAvatar(friend: friend, radius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: const TextStyle(
                    color: Color(0xFF173B72),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  friend.detail,
                  style: const TextStyle(
                    color: Color(0xFF7187A6),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: Color(0xFF7192C5)),
            tooltip: 'Friend options',
          ),
        ],
      ),
    );
  }
}

class _TabSelector extends StatelessWidget {
  final int selectedTab;
  final int requestCount;
  final ValueChanged<int> onChanged;

  const _TabSelector({
    required this.selectedTab,
    required this.requestCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 31,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFDCEAFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(child: _tab('Friend Requests', 0, showCount: true)),
          Expanded(child: _tab('Friends', 1)),
        ],
      ),
    );
  }

  Widget _tab(String label, int value, {bool showCount = false}) {
    final selected = selectedTab == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF1769FF)
                    : const Color(0xFF526B93),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showCount) ...[
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const BoxDecoration(
                  color: Color(0xFF1769FF),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$requestCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;

  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF6880A5),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (action != null)
          Text(
            action!,
            style: const TextStyle(
              color: Color(0xFF1769FF),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _RequestButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onPressed;

  const _RequestButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _FriendAvatar extends StatelessWidget {
  final _Friend friend;
  final double radius;

  const _FriendAvatar({required this.friend, required this.radius});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: friend.color,
      child: _initials(),
    );
  }

  Widget _initials() {
    return Text(
      friend.name.substring(0, 1),
      style: const TextStyle(color: Colors.white, fontSize: 20),
    );
  }
}

class _Friend {
  final String userId;
  final String name;
  final String detail;
  final String username;
  final int? requestId;
  final Color color;

  const _Friend({
    required this.userId,
    required this.name,
    required this.detail,
    required this.username,
    this.requestId,
    this.color = const Color(0xFF6E8EC5),
  });

  factory _Friend.fromJson(Map<String, dynamic> json) {
    final username = json['username']?.toString() ?? '';
    return _Friend(
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? username,
      detail: json['email']?.toString() ?? '@$username',
      username: username,
      requestId: (json['requestId'] as num?)?.toInt(),
      color: _avatarColors[username.hashCode.abs() % _avatarColors.length],
    );
  }
}

const _avatarColors = [
  Color(0xFFF97316),
  Color(0xFF234680),
  Color(0xFF22A866),
  Color(0xFF8B6BE8),
];
