import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/tenant.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';

class NoticePeriodDialog extends StatefulWidget {
  final Tenant tenant;
  const NoticePeriodDialog({super.key, required this.tenant});

  @override
  State<NoticePeriodDialog> createState() => _NoticePeriodDialogState();
}

class _NoticePeriodDialogState extends State<NoticePeriodDialog> {
  DateTime _noticeDate = DateTime.now();
  DateTime _expectedExitDate = DateTime.now().add(const Duration(days: 30));
  final _reasonController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isNotice) async {
    final initial = isNotice ? _noticeDate : _expectedExitDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (picked != null) {
      setState(() {
        if (isNotice) {
          _noticeDate = picked;
          _expectedExitDate = picked.add(const Duration(days: 30));
        } else {
          _expectedExitDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final payload = {
        'noticeDate': formatDateISO(_noticeDate),
        'expectedExitDate': formatDateISO(_expectedExitDate),
        'exitReason': _reasonController.text.trim(),
      };
      await TenantsService.initiateNotice(widget.tenant.id, payload);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, ApiClient.extractError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: p.warning.withValues(alpha: 0.15),
                  child: Icon(Icons.outbound_outlined, color: p.warning),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Initiate Notice Period',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                      Text(
                        widget.tenant.name,
                        style: TextStyle(fontSize: 13, color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _datePickerTile(
                    p,
                    label: 'Notice Date',
                    date: _noticeDate,
                    onTap: () => _selectDate(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _datePickerTile(
                    p,
                    label: 'Expected Exit',
                    date: _expectedExitDate,
                    onTap: () => _selectDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Moving Out (Optional)',
                hintText: 'e.g. Relocating to a new city, job change...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.warning,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Initiate Notice', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _datePickerTile(AppPalette p, {required String label, required DateTime date, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: p.border),
          borderRadius: BorderRadius.circular(12),
          color: p.surfaceAlt,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: p.textTertiary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_month, size: 16, color: p.primary),
                const SizedBox(width: 6),
                Text(formatDate(date), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
