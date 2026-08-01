import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../models/tenant.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';

class TenantFormScreen extends StatefulWidget {
  final Tenant? tenant;
  const TenantFormScreen({super.key, this.tenant});

  @override
  State<TenantFormScreen> createState() => _TenantFormScreenState();
}

class _TenantFormScreenState extends State<TenantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _roomNumberController;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _idProofTypeController;
  late final TextEditingController _idProofNumberController;
  late final TextEditingController _depositController;
  DateTime _checkInDate = DateTime.now();
  bool _loading = false;

  bool get _isEdit => widget.tenant != null;

  @override
  void initState() {
    super.initState();
    final t = widget.tenant;
    _roomNumberController = TextEditingController(
        text: t == null ? '' : t.roomId.toString());
    _nameController = TextEditingController(text: t?.name ?? '');
    _emailController = TextEditingController(text: t?.email ?? '');
    _phoneController = TextEditingController(text: t?.phone ?? '');
    _idProofTypeController =
        TextEditingController(text: t?.idProofType ?? 'Aadhar');
    _idProofNumberController = TextEditingController(text: t?.idProofNumber ?? '');
    _depositController = TextEditingController(
        text: t == null ? '' : t.depositAmount.toStringAsFixed(0));
    if (t?.checkInDate != null && t!.checkInDate.isNotEmpty) {
      _checkInDate =
          DateTime.tryParse(t.checkInDate) ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _idProofTypeController.dispose();
    _idProofNumberController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _checkInDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final dateStr = _checkInDate.toIso8601String().substring(0, 10);
      if (_isEdit) {
        await TenantsService.update(widget.tenant!.id, {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'depositAmount': double.tryParse(_depositController.text) ?? 0,
        });
      } else {
        await TenantsService.create({
          'roomNumber': int.tryParse(_roomNumberController.text) ?? 0,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'idProofType': _idProofTypeController.text.trim(),
          'idProofNumber': _idProofNumberController.text.trim(),
          'checkInDate': dateStr,
          'depositAmount': double.tryParse(_depositController.text) ?? 0,
        });
      }
      if (!mounted) return;
      showSuccessSnack(
        context,
        _isEdit
            ? 'Tenant updated successfully'
            : 'Tenant created successfully',
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
      appBar: AppBar(title: Text(_isEdit ? 'Edit Tenant' : 'Add New Tenant')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isEdit)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: p.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Room: ${widget.tenant!.roomNumber}  |  Status: ${widget.tenant!.status}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: p.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (!_isEdit) ...[
                TextFormField(
                  controller: _roomNumberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Room ID *',
                    hintText: 'e.g. 101',
                    prefixIcon: Icon(Icons.meeting_room_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Room ID is required'
                      : null,
                ),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'Rahul Sharma',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().length < 2)
                        ? 'Name must be at least 2 characters'
                        : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  hintText: 'rahul@gmail.com',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: (v) {
                  final email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (v == null || !email.hasMatch(v.trim())) {
                    return 'Invalid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Phone *',
                  hintText: '9876543210',
                  counterText: '',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) =>
                    (v == null || !RegExp(r'^\d{10}$').hasMatch(v.trim()))
                        ? 'Phone must be 10 digits'
                        : null,
              ),
              const SizedBox(height: 14),
              if (!_isEdit) ...[
                TextFormField(
                  controller: _idProofTypeController,
                  decoration: const InputDecoration(
                    labelText: 'ID Proof Type *',
                    hintText: 'Aadhar / Passport / Driving License',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'ID proof type is required'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _idProofNumberController,
                  decoration: const InputDecoration(
                    labelText: 'ID Proof Number *',
                    hintText: '1234 5678 9012',
                    prefixIcon: Icon(Icons.credit_card_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'ID proof number is required'
                      : null,
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(10),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Check-in Date *',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      _formatDate(_checkInDate),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: _depositController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Deposit Amount (₹) *',
                  hintText: '12000',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                validator: (v) {
                  final val = double.tryParse(v ?? '');
                  if (v == null || v.trim().isEmpty || val == null) {
                    return 'Deposit is required';
                  }
                  if (val <= 0) return 'Deposit must be positive';
                  return null;
                },
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
                    : Text(_isEdit ? 'Save Changes' : 'Add Tenant'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}
