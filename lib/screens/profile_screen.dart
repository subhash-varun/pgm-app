import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/auth_service.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/user.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Profile? _profile;
  bool _loading = true;
  String? _error;
  bool _editing = false;
  bool _saving = false;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _contactController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _contactController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AuthService.getProfile();
      final profile = Profile.fromJson(data);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _nameController.text = profile.name;
        _emailController.text = profile.email;
        _contactController.text = profile.contactNo;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ApiClient.extractError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startEditing() {
    final p = _profile!;
    setState(() {
      _nameController.text = p.name;
      _emailController.text = p.email;
      _contactController.text = p.contactNo;
      _editing = true;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final contact = _contactController.text.trim();
    if (name.isEmpty) {
      _showError('Name is required');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showError('Please enter a valid email');
      return;
    }
    if (!RegExp(r'^\d{10}$').hasMatch(contact)) {
      _showError('Phone number must be exactly 10 digits');
      return;
    }
    setState(() => _saving = true);
    try {
      await AuthService.updateProfile(name: name, email: email, contactNo: contact);
      if (!mounted) return;
      showSuccessSnack(context, 'Profile updated successfully');
      setState(() => _editing = false);
      _load();
    } catch (e) {
      if (!mounted) return;
      _showError(ApiClient.extractError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    showErrorSnack(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (_profile != null && !_editing)
            IconButton(
              onPressed: _startEditing,
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Profile',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _profile == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _profile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    final p = _profile!;
    final palette = context.palette;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [palette.primary, palette.purple],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: palette.surface,
                child: Text(
                  toInitials(p.name),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: palette.primary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                p.name,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Joined ${formatDate(p.createdAt)}',
                style: const TextStyle(fontSize: 12.5, color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: p.roles
                    .map((r) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            stripRolePrefix(r),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_editing) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: palette.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: palette.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Make sure all information is accurate before saving.',
                    style: TextStyle(fontSize: 12.5, color: palette.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contactController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              counterText: '',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.success,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Save'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () => setState(() => _editing = false),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ] else ...[
          _infoBox(
            icon: Icons.person_outline,
            color: palette.primary,
            label: 'Full Name',
            value: p.name,
          ),
          const SizedBox(height: 10),
          _infoBox(
            icon: Icons.mail_outline,
            color: palette.purple,
            label: 'Email Address',
            value: p.email,
          ),
          const SizedBox(height: 10),
          _infoBox(
            icon: Icons.phone_outlined,
            color: palette.success,
            label: 'Phone Number',
            value: p.contactNo.isEmpty ? '—' : p.contactNo,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatBox(label: 'User ID', value: '#${p.id}'),
              const SizedBox(width: 10),
              _StatBox(
                label: 'Account Type',
                value: p.roles.isEmpty ? '—' : stripRolePrefix(p.roles.first),
              ),
              const SizedBox(width: 10),
              const _StatBox(label: 'Status', value: 'Active'),
            ],
          ),
        ],
      ],
    );
  }

  Widget _infoBox({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: p.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: p.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
