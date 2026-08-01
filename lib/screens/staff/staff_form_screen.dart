import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/staff.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';

class StaffFormScreen extends StatefulWidget {
  final Staff? staff;
  const StaffFormScreen({super.key, this.staff});

  @override
  State<StaffFormScreen> createState() => _StaffFormScreenState();
}

class _StaffFormScreenState extends State<StaffFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _adminIdController;
  late final TextEditingController _roleController;
  late String _status;
  bool _loading = false;

  bool get _isEdit => widget.staff != null;

  @override
  void initState() {
    super.initState();
    final s = widget.staff;
    _nameController = TextEditingController(text: s?.name ?? '');
    _emailController = TextEditingController(text: s?.email ?? '');
    _passwordController = TextEditingController();
    _adminIdController = TextEditingController(
        text: s == null ? '' : s.adminId.toString());
    _roleController = TextEditingController(text: s?.role ?? '');
    _status = s?.status ?? 'ACTIVE';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _adminIdController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_isEdit) {
        await StaffService.update(widget.staff!.id, {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _roleController.text.trim(),
          'status': _status,
        });
      } else {
        await StaffService.create({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'adminId': int.tryParse(_adminIdController.text) ?? 0,
          'role': _roleController.text.trim(),
          'status': _status,
        });
      }
      if (!mounted) return;
      showSuccessSnack(
        context,
        _isEdit ? 'Staff updated successfully' : 'Staff created successfully',
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.extractError(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.scaffold,
      appBar: AppBar(title: Text(_isEdit ? 'Edit Staff' : 'Add Staff')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: (v) {
                  final email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (v == null || !email.hasMatch(v.trim())) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              if (!_isEdit) ...[
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password *',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _adminIdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Admin ID *',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Admin ID is required'
                      : null,
                ),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: _roleController,
                decoration: const InputDecoration(
                  labelText: 'Role *',
                  hintText: 'Manager',
                  prefixIcon: Icon(Icons.work_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Role is required' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status *',
                  prefixIcon: Icon(Icons.circle_outlined),
                ),
                items: staffStatuses
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(capitalize(s)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _status = v ?? 'ACTIVE'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(_isEdit ? 'Update Staff' : 'Create Staff'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
