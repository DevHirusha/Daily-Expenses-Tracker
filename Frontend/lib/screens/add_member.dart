import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddMemberScreen extends StatefulWidget {
  final String token;

  const AddMemberScreen({super.key, required this.token});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final searchController = TextEditingController();
  Timer? _searchDebounce;
  List<_Contact> _results = const [];
  bool _isSearching = false;
  String? _sendingUsername;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    searchController
      ..removeListener(_onQueryChanged)
      ..dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged() {
    _searchDebounce?.cancel();
    final query = searchController.text.trim();
    if (query.length < 2) {
      setState(() {
        _results = const [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      () => _searchUsers(query),
    );
  }

  Future<void> _searchUsers(String query) async {
    try {
      final users = await ApiService.searchUsers(
        token: widget.token,
        username: query,
      );
      if (!mounted || query != searchController.text.trim()) return;
      setState(() {
        _results = users.map(_Contact.fromJson).toList();
        _isSearching = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSearching = false);
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _invite(_Contact contact) async {
    setState(() => _sendingUsername = contact.username);
    try {
      await ApiService.sendFriendRequest(
        token: widget.token,
        username: contact.username,
      );
      if (!mounted) return;
      _showMessage('Friend request sent to ${contact.name}', isError: false);
      setState(() {
        _results = _results
            .map(
              (item) => item.username == contact.username
                  ? item.copyWith(requestStatus: 'PENDING')
                  : item,
            )
            .toList();
      });
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sendingUsername = null);
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
          'Search results',
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
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF5A78AB),
                  ),
                  suffixIcon: IconButton(
                    onPressed: searchController.clear,
                    icon: const Icon(Icons.cancel, color: Color(0xFFB7C5E3)),
                    tooltip: 'Clear search',
                  ),
                  hintText: 'Search people',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _isSearching
                    ? 'Searching...'
                    : '${_results.length} results found',
                style: const TextStyle(
                  color: Color(0xFF7890B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              if (_isSearching)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_results.isEmpty)
                const _EmptyResults()
              else
                ..._results.map(
                  (contact) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ContactCard(
                      contact: contact,
                      onInvite: () => _invite(contact),
                      isSending: _sendingUsername == contact.username,
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

class _Contact {
  final String userId;
  final String name;
  final String username;
  final String email;
  final Color avatarColor;
  final String? requestStatus;

  const _Contact({
    required this.userId,
    required this.name,
    required this.username,
    required this.email,
    required this.avatarColor,
    this.requestStatus,
  });

  factory _Contact.fromJson(Map<String, dynamic> json) {
    final username = json['username']?.toString() ?? '';
    return _Contact(
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? username,
      username: username,
      email: json['email']?.toString() ?? '',
      avatarColor:
          _avatarColors[username.hashCode.abs() % _avatarColors.length],
      requestStatus: json['requestStatus']?.toString(),
    );
  }

  _Contact copyWith({String? requestStatus}) => _Contact(
    userId: userId,
    name: name,
    username: username,
    email: email,
    avatarColor: avatarColor,
    requestStatus: requestStatus,
  );
}

const _avatarColors = [
  Color(0xFF294C88),
  Color(0xFF6337A8),
  Color(0xFF20A9A5),
  Color(0xFFF47C20),
];

class _ContactCard extends StatelessWidget {
  final _Contact contact;
  final VoidCallback onInvite;
  final bool isSending;

  const _ContactCard({
    required this.contact,
    required this.onInvite,
    required this.isSending,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: contact.avatarColor,
              child: Text(
                contact.name.substring(0, 1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: const TextStyle(
                      color: Color(0xFF172C57),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${contact.username}',
                    style: const TextStyle(
                      color: Color(0xFF83A2D2),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (contact.requestStatus == 'PENDING')
              const Text(
                'Pending',
                style: TextStyle(
                  color: Color(0xFF7890B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              OutlinedButton(
                onPressed: onInvite,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF315589),
                  side: const BorderSide(color: Color(0xFF315589)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Invite'),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: const Column(
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 42,
            color: Color(0xFF91A6CA),
          ),
          SizedBox(height: 10),
          Text(
            'No people found',
            style: TextStyle(
              color: Color(0xFF5F78A7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
