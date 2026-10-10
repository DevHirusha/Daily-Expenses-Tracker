import 'package:flutter/material.dart';

import '../services/api_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String token;
  final String fallbackEmail;

  const UserProfileScreen({
    super.key,
    required this.token,
    required this.fallbackEmail,
  });

  static Future<Map<String, dynamic>?> loadProfile(String token) async {
    try {
      return await ApiService.getProfile(token: token);
    } catch (_) {
      return null;
    }
  }

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _accountId;
  bool _isVerified = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController(text: widget.fallbackEmail);
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final profile = await UserProfileScreen.loadProfile(widget.token);
    if (!mounted) return;

    if (profile == null) {
      setState(() {
        _isLoading = false;
        _error =
            'We could not load your profile. Check your connection and try again.';
      });
      return;
    }

    setState(() {
      _nameController.text = profile['name']?.toString() ?? '';
      _usernameController.text = profile['username']?.toString() ?? '';
      _emailController.text =
          profile['email']?.toString() ?? widget.fallbackEmail;
      _accountId = profile['userId']?.toString();
      _isVerified = profile['isAccountVerified'] == true;
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      final profile = await ApiService.updateProfile(
        token: widget.token,
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _nameController.text =
            profile['name']?.toString() ?? _nameController.text.trim();
        _usernameController.text =
            profile['username']?.toString() ?? _usernameController.text.trim();
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Color(0xFF249A70),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFD9544D),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String get _displayName {
    final name = _nameController.text.trim();
    return name.isEmpty ? 'Your profile' : name;
  }

  String get _initials {
    final parts = _displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    return parts.take(2).map((part) => part[0]).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF172C57);
    const muted = Color(0xFF8292B4);
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
          'Personal information',
          style: TextStyle(color: navy, fontWeight: FontWeight.w800),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: orange))
          : SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProfileHero(
                        initials: _initials,
                        name: _displayName,
                        username: _usernameController.text,
                        verified: _isVerified,
                      ),
                      const SizedBox(height: 26),
                      if (_error != null) ...[
                        _ErrorBanner(message: _error!, onRetry: _loadProfile),
                        const SizedBox(height: 18),
                      ],
                      const Text(
                        'YOUR DETAILS',
                        style: TextStyle(
                          color: muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ProfileField(
                        controller: _nameController,
                        label: 'Full name',
                        hint: 'How should we call you?',
                        icon: Icons.badge_outlined,
                        validator: (value) =>
                            value == null || value.trim().length < 2
                            ? 'Enter at least 2 characters'
                            : null,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 13),
                      _ProfileField(
                        controller: _usernameController,
                        label: 'Username',
                        hint: 'Choose a public username',
                        prefixText: '@',
                        icon: Icons.alternate_email_rounded,
                        validator: (value) {
                          final username = value?.trim() ?? '';
                          if (!RegExp(
                            r'^[a-zA-Z0-9._]{3,30}$',
                          ).hasMatch(username)) {
                            return 'Use 3–30 letters, numbers, dots, or underscores';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 13),
                      _ProfileField(
                        controller: _emailController,
                        label: 'Email address',
                        hint: 'Your account email',
                        icon: Icons.mail_outline_rounded,
                        readOnly: true,
                        suffixIcon: Icons.lock_outline_rounded,
                      ),
                      const SizedBox(height: 22),
                      _AccountStatus(
                        verified: _isVerified,
                        accountId: _accountId,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orange,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: orange.withValues(
                              alpha: .55,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                          ),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 19,
                                  height: 19,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded),
                          label: Text(
                            _isSaving ? 'Saving changes...' : 'Save changes',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final String initials;
  final String name;
  final String username;
  final bool verified;

  const _ProfileHero({
    required this.initials,
    required this.name,
    required this.username,
    required this.verified,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF244C90), Color(0xFF172C57)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172C57).withValues(alpha: .18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .16),
              border: Border.all(
                color: Colors.white.withValues(alpha: .35),
                width: 2,
              ),
            ),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  username.isEmpty ? 'Complete your profile' : '@$username',
                  style: const TextStyle(
                    color: Color(0xFFB9C9E8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Icon(
                      verified
                          ? Icons.verified_rounded
                          : Icons.info_outline_rounded,
                      color: verified
                          ? const Color(0xFF72E0B5)
                          : const Color(0xFFFFC779),
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      verified ? 'Verified account' : 'Verification pending',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final IconData? suffixIcon;
  final String? prefixText;
  final bool readOnly;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const _ProfileField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.suffixIcon,
    this.prefixText,
    this.readOnly = false,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(
        color: Color(0xFF172C57),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        prefixIcon: Icon(icon, color: const Color(0xFF7D8EAF), size: 21),
        suffixIcon: suffixIcon == null
            ? null
            : Icon(suffixIcon, color: const Color(0xFFAAB7CE), size: 19),
        filled: true,
        fillColor: readOnly ? const Color(0xFFECEFF6) : Colors.white,
        labelStyle: const TextStyle(color: Color(0xFF8292B4), fontSize: 13),
        hintStyle: const TextStyle(color: Color(0xFFB1BCD0), fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFF47C20), width: 1.3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD9544D)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD9544D), width: 1.3),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
      ),
    );
  }
}

class _AccountStatus extends StatelessWidget {
  final bool verified;
  final String? accountId;

  const _AccountStatus({required this.verified, required this.accountId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F6EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFF249A70),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verified ? 'Account verified' : 'Verify your account',
                  style: const TextStyle(
                    color: Color(0xFF172C57),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  accountId == null
                      ? 'Your profile is protected'
                      : 'Account ID: ${accountId!.length > 12 ? '${accountId!.substring(0, 12)}…' : accountId}',
                  style: const TextStyle(
                    color: Color(0xFF8292B4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            verified
                ? Icons.check_circle_rounded
                : Icons.arrow_forward_ios_rounded,
            color: verified ? const Color(0xFF249A70) : const Color(0xFFAAB7CE),
            size: verified ? 21 : 14,
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFED),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFD9544D)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF9C3B35), fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(
                color: Color(0xFFD9544D),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
