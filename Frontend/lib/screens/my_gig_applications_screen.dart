import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

class GigApplication {
  final int id;
  final int gigId;
  final String gigTitle;
  final String estimatedEarnings;
  final String companyName;
  final String location;
  final String? applicationDeadline;
  final String status;
  final String note;
  final String? imageData;
  final DateTime? createdAt;

  const GigApplication({
    required this.id,
    required this.gigId,
    required this.gigTitle,
    required this.estimatedEarnings,
    required this.companyName,
    required this.location,
    this.applicationDeadline,
    required this.status,
    required this.note,
    this.imageData,
    this.createdAt,
  });

  factory GigApplication.fromJson(Map<String, dynamic> json) {
    return GigApplication(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      gigId: int.tryParse(json['gigId']?.toString() ?? '') ?? 0,
      gigTitle: json['gigTitle']?.toString() ?? 'Gig application',
      estimatedEarnings: json['estimatedEarnings']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? 'Company',
      location: json['location']?.toString() ?? 'Flexible location',
      applicationDeadline: json['applicationDeadline']?.toString(),
      status: json['status']?.toString().toUpperCase() ?? 'PENDING',
      note: json['note']?.toString() ?? '',
      imageData: json['imageData']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

class MyGigApplicationsScreen extends StatefulWidget {
  final String token;

  const MyGigApplicationsScreen({super.key, required this.token});

  @override
  State<MyGigApplicationsScreen> createState() => _MyGigApplicationsScreenState();
}

class _MyGigApplicationsScreenState extends State<MyGigApplicationsScreen> {
  static const background = Color(0xFFE8ECFA);
  static const navy = Color(0xFF172C57);
  static const muted = Color(0xFF657596);
  static const orange = Color(0xFFF47C20);

  List<GigApplication> _applications = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await ApiService.getMyGigApplications(token: widget.token);
      if (!mounted) return;
      setState(() {
        _applications = rows.map(GigApplication.fromJson).toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: navy,
        elevation: 0,
        title: const Text(
          'My applications',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(onPressed: _loadApplications, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _loadApplications)
              : _applications.isEmpty
                  ? const Center(
                      child: Text(
                        'You have not applied to any gigs yet.',
                        style: TextStyle(color: muted, fontSize: 14),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadApplications,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                        itemCount: _applications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, index) => _ApplicationCard(
                          application: _applications[index],
                          onEdit: () => _editApplication(_applications[index]),
                          onDelete: () => _deleteApplication(_applications[index]),
                        ),
                      ),
                    ),
    );
  }

  Future<void> _editApplication(GigApplication application) async {
    final noteController = TextEditingController(text: application.note);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        var saving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Edit application'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Note to employer'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Write a short introduction...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        setDialogState(() => saving = true);
                        try {
                          await ApiService.updateGigApplication(
                            token: widget.token,
                            applicationId: application.id,
                            note: noteController.text,
                          );
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext, true);
                          }
                        } catch (error) {
                          if (dialogContext.mounted) {
                            setDialogState(() => saving = false);
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
                            );
                          }
                        }
                      },
                child: Text(saving ? 'Saving...' : 'Save'),
              ),
            ],
          ),
        );
      },
    );
    noteController.dispose();
    if (saved == true) _loadApplications();
  }

  Future<void> _deleteApplication(GigApplication application) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete application?'),
        content: Text('Remove your application for ${application.gigTitle}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ApiService.deleteGigApplication(
        token: widget.token,
        applicationId: application.id,
      );
      await _loadApplications();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
}

class _ApplicationCard extends StatelessWidget {
  final GigApplication application;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ApplicationCard({
    required this.application,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = application.status;
    final pending = status == 'PENDING';
    final rejected = status == 'REJECTED';
    final color = pending
        ? const Color(0xFFB66A00)
        : rejected
            ? Colors.red.shade700
            : Colors.green.shade700;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ApplicationImage(application: application),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.gigTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF172C57),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${application.companyName} • ${application.location}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF657596), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (application.applicationDeadline != null && application.applicationDeadline!.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                'Application deadline: ${application.applicationDeadline}',
                style: const TextStyle(color: Color(0xFF657596), fontSize: 12),
              ),
            ],
            if (application.note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                application.note,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF657596), fontSize: 12, height: 1.3),
              ),
            ],
            if (pending || rejected) ...[
              const Divider(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (pending)
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                    ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ApplicationImage extends StatelessWidget {
  final GigApplication application;

  const _ApplicationImage({required this.application});

  @override
  Widget build(BuildContext context) {
    final data = application.imageData;
    if (data != null && data.isNotEmpty) {
      try {
        final encoded = data.contains(',') ? data.substring(data.indexOf(',') + 1) : data;
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(base64Decode(encoded), width: 52, height: 52, fit: BoxFit.cover),
        );
      } catch (_) {}
    }
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF47C20).withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.work_outline, color: Color(0xFFF47C20)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF657596))),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
