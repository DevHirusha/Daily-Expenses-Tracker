import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CreateGroupScreen extends StatefulWidget {
  final String token;

  const CreateGroupScreen({super.key, required this.token});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final groupNameController = TextEditingController();
  final searchController = TextEditingController();
  List<_Person> members = const [];
  final selected = <String>{};
  bool isLoading = true;
  bool isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final friends = await ApiService.getFriends(token: widget.token);
      if (!mounted) return;
      setState(() {
        members = friends.map(_Person.fromJson).toList();
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  void dispose() {
    groupNameController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _toggleMember(_Person person) {
    setState(() {
      if (selected.contains(person.userId)) {
        selected.remove(person.userId);
      } else if (selected.length < 10) {
        selected.add(person.userId);
      }
    });
  }

  Future<void> _createGroup() async {
    final name = groupNameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Enter a group name');
      return;
    }
    setState(() => isCreating = true);
    try {
      await ApiService.createGroup(
        token: widget.token,
        name: name,
        memberUserIds: selected.toList(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isCreating = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final results = members
        .where(
          (person) =>
              person.name.toLowerCase().contains(query) ||
              person.email.toLowerCase().contains(query),
        )
        .toList();

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
          'Create Group',
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
              _GroupNameField(controller: groupNameController),
              const SizedBox(height: 12),
              TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF41699F),
                  ),
                  hintText: 'Search by name or email',
                  hintStyle: const TextStyle(
                    color: Color(0xFF88A4CE),
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF4F7FD),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Search results',
                style: TextStyle(color: Color(0xFF7995C0), fontSize: 11),
              ),
              const SizedBox(height: 6),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F8FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: results
                        .map(
                          (person) => _PersonRow(
                            person: person,
                            selected: selected.contains(person.userId),
                            onTap: () => _toggleMember(person),
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Selected members',
                    style: TextStyle(color: Color(0xFF41699F), fontSize: 12),
                  ),
                  Text(
                    '${selected.length}/10',
                    style: const TextStyle(
                      color: Color(0xFF7995C0),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: members
                      .where((person) => selected.contains(person.userId))
                      .map(
                        (person) => _SelectedPersonRow(
                          person: person,
                          onRemove: () => _toggleMember(person),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isCreating ? null : _createGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text(
                          'Create Group',
                          style: TextStyle(fontWeight: FontWeight.bold),
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

class _Person {
  final String userId;
  final String name;
  final String email;
  final Color color;

  const _Person({
    required this.userId,
    required this.name,
    required this.email,
    required this.color,
  });

  factory _Person.fromJson(Map<String, dynamic> json) {
    final username = json['username']?.toString() ?? '';
    return _Person(
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? username,
      email: json['email']?.toString() ?? '@$username',
      color: _personColors[username.hashCode.abs() % _personColors.length],
    );
  }
}

const _personColors = [
  Color(0xFF294C88),
  Color(0xFF16AFA5),
  Color(0xFF673AB7),
  Color(0xFFF97316),
];

class _GroupNameField extends StatelessWidget {
  final TextEditingController controller;

  const _GroupNameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const Icon(Icons.group_outlined, color: Color(0xFF172C57), size: 23),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Group name',
                hintText: 'e.g. Family Budget',
                border: InputBorder.none,
                labelStyle: TextStyle(color: Color(0xFF7896C2), fontSize: 11),
                hintStyle: TextStyle(color: Color(0xFF88A4CE), fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  final _Person person;
  final bool selected;
  final VoidCallback onTap;

  const _PersonRow({
    required this.person,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        children: [
          _Avatar(person: person),
          const SizedBox(width: 10),
          Expanded(child: _PersonDetails(person: person)),
          OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(selected ? Icons.check : Icons.add, size: 14),
            label: Text(selected ? 'Added' : 'Add'),
            style: OutlinedButton.styleFrom(
              foregroundColor: selected
                  ? const Color(0xFF7995C0)
                  : const Color(0xFF1D5AAA),
              side: BorderSide(
                color: selected
                    ? const Color(0xFFB9C9E4)
                    : const Color(0xFF2B68B3),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedPersonRow extends StatelessWidget {
  final _Person person;
  final VoidCallback onRemove;

  const _SelectedPersonRow({required this.person, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _Avatar(person: person),
          const SizedBox(width: 10),
          Expanded(child: _PersonDetails(person: person)),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, color: Color(0xFF9EB2D3), size: 18),
            tooltip: 'Remove member',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final _Person person;

  const _Avatar({required this.person});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: person.color,
      child: Text(
        person.name.substring(0, 1),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PersonDetails extends StatelessWidget {
  final _Person person;

  const _PersonDetails({required this.person});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          person.name,
          style: const TextStyle(
            color: Color(0xFF1B477F),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          person.email,
          style: const TextStyle(color: Color(0xFF83A2D2), fontSize: 9),
        ),
      ],
    );
  }
}
