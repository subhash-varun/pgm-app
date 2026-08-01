import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/inventory_item.dart';
import '../../models/room.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';

class InventoryItemFormScreen extends StatefulWidget {
  final InventoryItem? item;
  const InventoryItemFormScreen({super.key, this.item});

  @override
  State<InventoryItemFormScreen> createState() =>
      _InventoryItemFormScreenState();
}

class _InventoryItemFormScreenState extends State<InventoryItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _itemNameController;
  late final TextEditingController _quantityController;
  late String _condition;
  int? _selectedRoomId;
  List<Room> _rooms = [];
  bool _loadingRooms = true;
  bool _submitting = false;
  String? _roomsError;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _itemNameController = TextEditingController(text: item?.itemName ?? '');
    _quantityController = TextEditingController(
        text: item == null ? '1' : item.quantity.toString());
    _condition = item?.conditionStatus ?? 'GOOD';
    _selectedRoomId = item?.roomId;
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _loadingRooms = true;
      _roomsError = null;
    });
    try {
      final data = await RoomsService.list(size: 100);
      if (!mounted) return;
      setState(() => _rooms = data.content);
    } catch (e) {
      if (!mounted) return;
      setState(() => _roomsError = ApiClient.extractError(e));
    } finally {
      if (mounted) setState(() => _loadingRooms = false);
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a room')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final payload = {
        'roomId': _selectedRoomId!,
        'itemName': _itemNameController.text.trim(),
        'quantity': int.tryParse(_quantityController.text) ?? 1,
        'conditionStatus': _condition,
      };
      if (_isEdit) {
        await InventoryService.update(widget.item!.id, payload);
      } else {
        await InventoryService.create(payload);
      }
      if (!mounted) return;
      showSuccessSnack(
        context,
        _isEdit ? 'Item updated successfully' : 'Item added successfully',
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.extractError(e))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.scaffold,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Item' : 'Add Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_loadingRooms)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_roomsError != null)
                ErrorRetry(message: _roomsError!, onRetry: _loadRooms)
              else
                DropdownButtonFormField<int>(
                  initialValue: _selectedRoomId,
                  decoration: const InputDecoration(
                    labelText: 'Room *',
                    prefixIcon: Icon(Icons.meeting_room_outlined),
                  ),
                  items: _rooms
                      .map((r) => DropdownMenuItem(
                            value: r.id,
                            child: Text('${r.roomNumber} (${capitalize(r.roomType)})'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedRoomId = v),
                ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _itemNameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name *',
                  hintText: 'e.g., Bed, Chair, Table, Fan',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Item name is required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity *',
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (v) {
                  final val = int.tryParse(v ?? '');
                  if (val == null || val < 1) {
                    return 'Quantity must be at least 1';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _condition,
                decoration: const InputDecoration(
                  labelText: 'Condition Status *',
                  prefixIcon: Icon(Icons.verified_outlined),
                ),
                items: inventoryConditions
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(capitalize(c)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _condition = v ?? 'GOOD'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(_isEdit ? 'Update Item' : 'Add Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
