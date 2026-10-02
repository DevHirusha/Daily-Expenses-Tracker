import 'package:flutter/material.dart';

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final searchController = TextEditingController(text: 'nuwan');

  final contacts = const [
    _Contact('Nuwan Silva', 'nuwan@gmail.com', Color(0xFF294C88)),
    _Contact('Nuwan Perera', 'nuwan.perera@gmail.com', Color(0xFF6337A8)),
    _Contact('Nuwan Jayasinghe', 'nuwan.j@gmail.com', Color(0xFF20A9A5)),
  ];

  @override
  void initState() {
    super.initState();
    searchController.addListener(_refreshResults);
  }

  @override
  void dispose() {
    searchController
      ..removeListener(_refreshResults)
      ..dispose();
    super.dispose();
  }

  void _refreshResults() => setState(() {});

  void _invite(_Contact contact) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invite sent to ${contact.name}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final results = contacts
        .where((contact) =>
            contact.name.toLowerCase().contains(query) ||
            contact.email.toLowerCase().contains(query))
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
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF5A78AB)),
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
                '${results.length} results found',
                style: const TextStyle(
                  color: Color(0xFF7890B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              if (results.isEmpty)
                const _EmptyResults()
              else
                ...results.map(
                  (contact) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ContactCard(
                      contact: contact,
                      onInvite: () => _invite(contact),
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
  final String name;
  final String email;
  final Color avatarColor;

  const _Contact(this.name, this.email, this.avatarColor);
}

class _ContactCard extends StatelessWidget {
  final _Contact contact;
  final VoidCallback onInvite;

  const _ContactCard({required this.contact, required this.onInvite});

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
                    contact.email,
                    style: const TextStyle(
                      color: Color(0xFF83A2D2),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: onInvite,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF315589),
                side: const BorderSide(color: Color(0xFF315589)),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Invite'),
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
          Icon(Icons.person_search_outlined, size: 42, color: Color(0xFF91A6CA)),
          SizedBox(height: 10),
          Text(
            'No people found',
            style: TextStyle(color: Color(0xFF5F78A7), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
