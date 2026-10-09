import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

class GigDetailsScreen extends StatelessWidget {
  const GigDetailsScreen({
    super.key,
    required this.token,
    required this.gigId,
    required this.title,
    required this.company,
    required this.pay,
    required this.location,
    required this.type,
    this.description = '',
    this.requirements = '',
    this.companyPhoneNumber = '',
    this.applicationDeadline,
    this.imageData,
  });

  final String title;
  final String token;
  final int gigId;
  final String company;
  final String pay;
  final String location;
  final String type;
  final String description;
  final String requirements;
  final String companyPhoneNumber;
  final String? applicationDeadline;
  final String? imageData;

  static const background = Color(0xFFE8ECFA);
  static const navy = Color(0xFF172C57);
  static const muted = Color(0xFF657596);
  static const orange = Color(0xFFF47C20);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _Header(title: title),
            const SizedBox(height: 20),
            _EarningsCard(
              pay: pay,
              location: location,
              type: type,
            ),
            if (applicationDeadline != null && applicationDeadline!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _DeadlineCard(deadline: applicationDeadline!),
            ],
            if (imageData != null && imageData!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _GigPhoto(imageData: imageData!),
            ],
            const SizedBox(height: 12),
            _InfoCard(
              title: 'JOB DESCRIPTION',
              child: Text(
                description.isEmpty ? 'No description provided.' : description,
                style: const TextStyle(color: navy, fontSize: 13, height: 1.35),
              ),
            ),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'REQUIREMENTS',
              child: requirements.trim().isEmpty
                  ? const Text('No specific requirements provided.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: requirements
                          .split(RegExp(r'\r?\n'))
                          .where((item) => item.trim().isNotEmpty)
                          .map((item) => _Requirement(text: item.trim()))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 12),
            _EmployerCard(company: company, phone: companyPhoneNumber),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _isApplicationClosed
                    ? null
                    : () async {
                  final applied = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ApplyContactScreen(
                        token: token,
                        gigId: gigId,
                        company: company,
                        location: location,
                        applicationDeadline: applicationDeadline,
                      ),
                    ),
                  );
                  if (applied == true && context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(_isApplicationClosed ? 'Applications closed' : 'Apply now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _isApplicationClosed {
    final deadline = DateTime.tryParse(applicationDeadline ?? '');
    if (deadline == null) return false;
    final today = DateTime.now();
    return deadline.isBefore(DateTime(today.year, today.month, today.day));
  }
}

class _DeadlineCard extends StatelessWidget {
  const _DeadlineCard({required this.deadline});

  final String deadline;

  @override
  Widget build(BuildContext context) {
    final parsed = DateTime.tryParse(deadline);
    final formatted = parsed == null
        ? deadline
        : '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_outlined, color: GigDetailsScreen.orange, size: 20),
          const SizedBox(width: 9),
          const Text(
            'Application deadline:',
            style: TextStyle(color: GigDetailsScreen.muted, fontSize: 12),
          ),
          const SizedBox(width: 5),
          Text(
            formatted,
            style: const TextStyle(
              color: GigDetailsScreen.navy,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GigPhoto extends StatelessWidget {
  const _GigPhoto({required this.imageData});

  final String imageData;

  @override
  Widget build(BuildContext context) {
    try {
      final encoded = imageData.contains(',')
          ? imageData.substring(imageData.indexOf(',') + 1)
          : imageData;
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(
          base64Decode(encoded),
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HeaderButton(
          icon: Icons.arrow_back,
          onTap: () => Navigator.maybePop(context),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: GigDetailsScreen.navy,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _HeaderButton(icon: Icons.favorite_border, onTap: () {}),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: GigDetailsScreen.navy, size: 20),
        ),
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({
    required this.pay,
    required this.location,
    required this.type,
  });

  final String pay;
  final String location;
  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: BoxDecoration(
        color: GigDetailsScreen.navy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ESTIMATED EARNINGS',
            style: TextStyle(
              color: Color(0xFFC8D3EA),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: .2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            pay,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _Chip(label: location),
              _Chip(label: type),
              const _Chip(label: '4h shifts'),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: GigDetailsScreen.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: .2,
            ),
          ),
          const SizedBox(height: 7),
          child,
        ],
      ),
    );
  }
}

class _Requirement extends StatelessWidget {
  const _Requirement({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check, color: GigDetailsScreen.orange, size: 16),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: GigDetailsScreen.navy,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2E4A7B),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmployerCard extends StatelessWidget {
  const _EmployerCard({required this.company, this.phone = ''});

  final String company;
  final String phone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EMPLOYER',
            style: TextStyle(
              color: GigDetailsScreen.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: GigDetailsScreen.orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company,
                      style: const TextStyle(
                        color: GigDetailsScreen.navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (phone.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        phone,
                        style: const TextStyle(
                          color: GigDetailsScreen.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '12 gigs posted',
                    style: TextStyle(
                      color: GigDetailsScreen.navy,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Responds in ~1 day',
                    style: TextStyle(color: GigDetailsScreen.muted, fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ApplyContactScreen extends StatefulWidget {
  const ApplyContactScreen({
    super.key,
    required this.token,
    required this.gigId,
    required this.company,
    required this.location,
    this.applicationDeadline,
  });

  final String token;
  final int gigId;
  final String company;
  final String location;
  final String? applicationDeadline;

  @override
  State<ApplyContactScreen> createState() => _ApplyContactScreenState();
}

class _ApplyContactScreenState extends State<ApplyContactScreen> {
  final _noteController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GigDetailsScreen.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Row(
              children: [
                _HeaderButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.maybePop(context),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Apply & Contact',
                  style: TextStyle(
                    color: GigDetailsScreen.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _CompanySummary(company: widget.company, location: widget.location),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.phone, size: 17),
                    label: const Text('Call employer'),
                    style: _orangeButton(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat_bubble_outline, size: 17),
                    label: const Text('Message'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GigDetailsScreen.navy,
                      side: const BorderSide(color: GigDetailsScreen.navy, width: 1.4),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _OrDivider(),
            const SizedBox(height: 16),
            if (widget.applicationDeadline != null && widget.applicationDeadline!.isNotEmpty) ...[
              const _FieldLabel('Application deadline'),
              const SizedBox(height: 6),
              _FormSurface(child: Text(_formatDeadline(widget.applicationDeadline!))),
              const SizedBox(height: 16),
            ],
            const _FieldLabel('Note to employer (optional)'),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              minLines: 3,
              maxLines: 5,
              style: const TextStyle(color: GigDetailsScreen.navy, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Write a short introduction, your schedule, vehicle\ninfo, or previous experience...',
                hintStyle: const TextStyle(color: Color(0xFF9AA5BB), fontSize: 12),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _submitting ? null : _submitApplication,
                style: _orangeButton(),
                child: Text(_submitting ? 'Submitting...' : 'Submit application'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitApplication() async {
    setState(() => _submitting = true);
    try {
      await ApiService.createGigApplication(
        token: widget.token,
        gigId: widget.gigId,
        note: _noteController.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _formatDeadline(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

  ButtonStyle _orangeButton() {
    return FilledButton.styleFrom(
      backgroundColor: GigDetailsScreen.orange,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    );
  }
}

class _CompanySummary extends StatelessWidget {
  const _CompanySummary({required this.company, required this.location});

  final String company;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: GigDetailsScreen.orange,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storefront, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company,
                  style: const TextStyle(
                    color: GigDetailsScreen.navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Immediate vacancy · $location',
                  style: const TextStyle(color: GigDetailsScreen.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFC6CEE2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'OR APPLY THROUGH APP',
            style: TextStyle(
              color: GigDetailsScreen.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFC6CEE2))),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: GigDetailsScreen.muted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _FormSurface extends StatelessWidget {
  const _FormSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: GigDetailsScreen.navy,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        child: child,
      ),
    );
  }
}
