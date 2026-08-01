import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/room.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';

class RoomFormScreen extends StatefulWidget {
  final Room? room;
  const RoomFormScreen({super.key, this.room});

  @override
  State<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends State<RoomFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _roomNumberController;
  late final TextEditingController _rentController;
  late final TextEditingController _facilitiesController;
  late String _roomType;
  late String _status;
  bool _loading = false;

  bool get _isEdit => widget.room != null;

  @override
  void initState() {
    super.initState();
    final r = widget.room;
    _roomNumberController =
        TextEditingController(text: r?.roomNumber ?? '');
    _rentController = TextEditingController(
        text: r == null ? '' : r.rentAmount.toStringAsFixed(0));
    _facilitiesController =
        TextEditingController(text: r?.facilities ?? '');
    _roomType = r?.roomType ?? 'SINGLE';
    _status = r?.status ?? 'AVAILABLE';
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    _rentController.dispose();
    _facilitiesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final payload = {
        'roomNumber': _roomNumberController.text.trim(),
        'roomType': _roomType,
        'rentAmount': double.tryParse(_rentController.text) ?? 0,
        'status': _status,
        if (_facilitiesController.text.trim().isNotEmpty)
          'facilities': _facilitiesController.text.trim(),
      };
      if (_isEdit) {
        await RoomsService.update(widget.room!.id, payload);
      } else {
        await RoomsService.create(payload);
      }
      if (!mounted) return;
      showSuccessSnack(
        context,
        _isEdit ? 'Room updated successfully' : 'Room created successfully',
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
      appBar: AppBar(title: Text(_isEdit ? 'Edit Room' : 'Add Room')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _roomNumberController,
                decoration: const InputDecoration(
                  labelText: 'Room Number *',
                  hintText: '101',
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Room Number is required'
                    : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _roomType,
                decoration: const InputDecoration(
                  labelText: 'Room Type *',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: roomTypes
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(capitalize(t)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _roomType = v ?? 'SINGLE'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _rentController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Rent Amount (₹) *',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                validator: (v) {
                  final val = double.tryParse(v ?? '');
                  if (val == null || val <= 0) {
                    return 'Enter a positive rent amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status *',
                  prefixIcon: Icon(Icons.circle_outlined),
                ),
                items: roomStatuses
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(capitalize(s)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _status = v ?? 'AVAILABLE'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _facilitiesController,
                decoration: const InputDecoration(
                  labelText: 'Facilities (optional)',
                  hintText: 'AC, WiFi, Bed',
                  prefixIcon: Icon(Icons.workspaces_outline),
                ),
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
                    : Text(_isEdit ? 'Update Room' : 'Create Room'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
