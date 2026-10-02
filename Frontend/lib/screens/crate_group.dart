import 'package:flutter/material.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final groupNameController = TextEditingController();
  final searchController = TextEditingController();

  final members = const [
    _Person('Nuwan Silva', 'nuwan@gmail.com', Color(0xFF294C88)),
    _Person('Pavithra Fernando', 'pavithra@gmail.com', Color(0xFF16AFA5)),
    _Person('Amali Perera', 'amali@gmail.com', Color(0xFF673AB7)),
    _Person('Sangeeth Wijesinghe', 'sangeeth@gmail.com', Color(0xFFF97316)),
  ];

  final selected = <String>{
    'Nuwan Silva',
    'Pavithra Fernando',
    'Amali Perera',
  };

  @override
  void dispose() {
    groupNameController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _toggleMember(_Person person) {
    setState(() {
      if (selected.contains(person.name)) {
        selected.remove(person.name);
      } else if (selected.length < 10) {
        selected.add(person.name);
      }
    });
  }

  void _createGroup() {
    final name = groupNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a group name')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name group created')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final results = members
        .where((person) =>
            person.name.toLowerCase().contains(query) ||
            person.email.toLowerCase().contains(query))
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
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF41699F)),
                  hintText: 'Search by name or email',
                  hintStyle: const TextStyle(color: Color(0xFF88A4CE), fontSize: 12),
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
                          selected: selected.contains(person.name),
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
                    style: const TextStyle(color: Color(0xFF7995C0), fontSize: 11),
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
                      .where((person) => selected.contains(person.name))
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
                  onPressed: _createGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: const Text(
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
  final String name;
  final String email;
  final Color color;

  const _Person(this.name, this.email, this.color);
}

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
              foregroundColor: selected ? const Color(0xFF7995C0) : const Color(0xFF1D5AAA),
              side: BorderSide(color: selected ? const Color(0xFFB9C9E4) : const Color(0xFF2B68B3)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
          style: const TextStyle(color: Color(0xFF1B477F), fontSize: 11, fontWeight: FontWeight.bold),
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
