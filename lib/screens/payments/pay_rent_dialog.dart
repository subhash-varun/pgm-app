import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/rent_ledger.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';

class PayRentDialog extends StatefulWidget {
  final RentLedger ledger;
  final VoidCallback onSuccess;

  const PayRentDialog({
    super.key,
    required this.ledger,
    required this.onSuccess,
  });

  @override
  State<PayRentDialog> createState() => _PayRentDialogState();
}

class _PayRentDialogState extends State<PayRentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _remarksController;
  String _paymentMethod = 'UPI';
  bool _applyAdvance = false;
  bool _isFullPayment = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.ledger.balanceDue.toStringAsFixed(2),
    );
    _remarksController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0 && !_applyAdvance) {
      showErrorSnack(context, 'Please enter a valid payment amount');
      return;
    }

    setState(() => _submitting = true);
    try {
      await RentLedgerService.payRent(widget.ledger.id, {
        'amount': amount,
        'paymentMethod': _paymentMethod,
        'applyAdvance': _applyAdvance,
        'remarks': _remarksController.text.trim(),
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessSnack(context, 'Payment recorded successfully!');
      widget.onSuccess();
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
    final ledger = widget.ledger;

    return Dialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: p.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.receipt_long, color: p.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Record Rent Payment',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: p.textPrimary,
                            ),
                          ),
                          Text(
                            '${ledger.tenantName} • Room ${ledger.roomNumber}',
                            style: TextStyle(fontSize: 13, color: p.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Amount Breakdown Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.border),
                  ),
                  child: Column(
                    children: [
                      _rowDetail('Total Rent Billed', formatCurrency(ledger.totalAmount), p.textPrimary),
                      const SizedBox(height: 6),
                      _rowDetail('Already Paid', formatCurrency(ledger.paidAmount), p.success),
                      const SizedBox(height: 6),
                      _rowDetail('Remaining Balance Due', formatCurrency(ledger.balanceDue), p.danger, isBold: true),
                      if (ledger.advanceBalance > 0) ...[
                        const Divider(height: 16),
                        _rowDetail('Available Advance Credit', formatCurrency(ledger.advanceBalance), p.purple),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Advance Credit Toggle
                if (ledger.advanceBalance > 0) ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Apply Advance Balance'),
                    subtitle: Text(
                      'Use up to ${formatCurrency(ledger.advanceBalance)} from tenant\'s credit',
                      style: TextStyle(fontSize: 12, color: p.textSecondary),
                    ),
                    value: _applyAdvance,
                    onChanged: (val) => setState(() => _applyAdvance = val),
                  ),
                  const SizedBox(height: 8),
                ],

                // Payment Type Toggle (Full vs Partial)
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Full Payment')),
                    ButtonSegment(value: false, label: Text('Partial Payment')),
                  ],
                  selected: {_isFullPayment},
                  onSelectionChanged: (set) {
                    setState(() {
                      _isFullPayment = set.first;
                      if (_isFullPayment) {
                        _amountController.text = ledger.balanceDue.toStringAsFixed(2);
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Payment Amount Field
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Payment Amount (₹)',
                    prefixIcon: const Icon(Icons.currency_rupee),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  enabled: !_isFullPayment,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter amount';
                    final num = double.tryParse(val);
                    if (num == null || num <= 0) return 'Enter valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Payment Method Radio Group
                Text(
                  'Payment Method',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.textSecondary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['UPI', 'CASH', 'BANK_TRANSFER', 'CARD'].map((method) {
                    final isSelected = _paymentMethod == method;
                    return ChoiceChip(
                      label: Text(method == 'BANK_TRANSFER' ? 'Bank Transfer' : method),
                      selected: isSelected,
                      onSelected: (sel) {
                        if (sel) setState(() => _paymentMethod = method);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Remarks
                TextFormField(
                  controller: _remarksController,
                  decoration: InputDecoration(
                    labelText: 'Remarks / Transaction Reference (Optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: p.success,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: Text(_submitting ? 'Recording...' : 'Confirm Payment'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rowDetail(String label, String value, Color valueColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
