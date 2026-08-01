import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/tenant.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';

class TenantSettlementScreen extends StatefulWidget {
  final int tenantId;
  final String tenantName;

  const TenantSettlementScreen({
    super.key,
    required this.tenantId,
    required this.tenantName,
  });

  @override
  State<TenantSettlementScreen> createState() => _TenantSettlementScreenState();
}

class _TenantSettlementScreenState extends State<TenantSettlementScreen> {
  TenantSettlementSummary? _summary;
  bool _loading = true;
  String? _error;
  bool _submitting = false;

  final _damageController = TextEditingController(text: '0');
  final _otherDeductionController = TextEditingController(text: '0');
  final _remarksController = TextEditingController();
  DateTime _exitDate = DateTime.now();
  String _paymentMethod = 'UPI';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _damageController.dispose();
    _otherDeductionController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await TenantsService.getSettlementSummary(widget.tenantId);
      if (!mounted) return;
      setState(() => _summary = summary);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ApiClient.extractError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _damage => double.tryParse(_damageController.text.trim()) ?? 0;
  double get _otherDeductions => double.tryParse(_otherDeductionController.text.trim()) ?? 0;

  double get _calculatedNetRefund {
    if (_summary == null) return 0;
    final totalCredits = _summary!.securityDepositPaid + _summary!.advanceBalance;
    final totalDebits = _summary!.outstandingRentDues + _damage + _otherDeductions;
    return totalCredits - totalDebits;
  }

  Future<void> _processExit() async {
    final netRefund = _calculatedNetRefund;
    final isRefund = netRefund >= 0;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final p = ctx.palette;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirm Move-Out & Settlement'),
          content: Text(
            'Are you sure you want to finalize move-out for ${widget.tenantName}?\n\n'
            '${isRefund ? 'Net Refund Amount:' : 'Net Outstanding Payable:'} ${formatCurrency(netRefund.abs())}\n'
            'This action will release room ${_summary?.roomNumber ?? ''} capacity.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: p.danger,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm & Vacate Room'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _submitting = true);
    try {
      final payload = {
        'actualExitDate': formatDateISO(_exitDate),
        'damageCharges': _damage,
        'otherDeductions': _otherDeductions,
        'paymentMethod': _paymentMethod,
        'remarks': _remarksController.text.trim(),
      };
      await TenantsService.completeExit(widget.tenantId, payload);
      if (!mounted) return;
      showSuccessSnack(context, 'Tenant checkout completed and room released.');
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
    return Scaffold(
      backgroundColor: p.scaffold,
      appBar: AppBar(
        title: Text('Exit Settlement: ${widget.tenantName}'),
      ),
      body: _buildBody(p),
    );
  }

  Widget _buildBody(AppPalette p) {
    if (_loading) return const LoadingList();
    if (_error != null) return ErrorRetry(message: _error!, onRetry: _load);
    final s = _summary!;
    final netRefund = _calculatedNetRefund;
    final isRefund = netRefund >= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: p.primary.withValues(alpha: 0.12),
                  child: Text(
                    toInitials(s.tenantName),
                    style: TextStyle(fontWeight: FontWeight.w700, color: p.primary),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.tenantName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.textPrimary)),
                      const SizedBox(height: 2),
                      Text('Room ${s.roomNumber} • Check-in: ${formatDate(s.checkInDate)}', style: TextStyle(fontSize: 12.5, color: p.textSecondary)),
                      if (s.noticeDate != null) ...[
                        const SizedBox(height: 2),
                        Text('Notice Date: ${formatDate(s.noticeDate!)}', style: TextStyle(fontSize: 12, color: p.warning, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Settlement Breakdown Statement
          Text('Financial Clearance Statement', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.textPrimary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.border),
            ),
            child: Column(
              children: [
                _summaryRow(p, 'Security Deposit Paid', formatCurrency(s.securityDepositPaid), isCredit: true),
                if (s.advanceBalance > 0)
                  _summaryRow(p, 'Advance Balance Credit', formatCurrency(s.advanceBalance), isCredit: true),
                const Divider(height: 20),
                _summaryRow(p, 'Outstanding Rent Dues (${s.unpaidLedgerCount} ledgers)', '- ${formatCurrency(s.outstandingRentDues)}', isDebit: true),
                const SizedBox(height: 12),
                TextField(
                  controller: _damageController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Damage / Maintenance Deductions (₹)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _otherDeductionController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Other Deductions (Key loss, cleaning, etc.) (₹)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const Divider(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isRefund ? p.success : p.danger).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(isRefund ? Icons.account_balance_wallet : Icons.warning_amber, color: isRefund ? p.success : p.danger),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isRefund ? 'NET REFUND TO TENANT' : 'NET OUTSTANDING PAYABLE BY TENANT',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isRefund ? p.success : p.danger),
                            ),
                            Text(
                              formatCurrency(netRefund.abs()),
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isRefund ? p.success : p.danger),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payment Details Form
          Text('Settlement Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.textPrimary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _exitDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 90)),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (picked != null) setState(() => _exitDate = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Actual Exit Date', border: OutlineInputBorder(), isDense: true),
                          child: Text(formatDate(_exitDate), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _paymentMethod,
                        decoration: const InputDecoration(labelText: 'Refund Method', border: OutlineInputBorder(), isDense: true),
                        items: ['UPI', 'CASH', 'BANK_TRANSFER']
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (v) => setState(() => _paymentMethod = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _remarksController,
                  decoration: const InputDecoration(
                    labelText: 'Settlement Remarks (Optional)',
                    hintText: 'e.g. Refund paid via UPI transaction ID...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _processExit,
              style: ElevatedButton.styleFrom(
                backgroundColor: p.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _submitting ? const SizedBox.shrink() : const Icon(Icons.check_circle_outline),
              label: _submitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Finalize Exit & Release Room', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _summaryRow(AppPalette p, String label, String value, {bool isCredit = false, bool isDebit = false}) {
    Color color = p.textPrimary;
    if (isCredit) color = p.success;
    if (isDebit) color = p.danger;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13.5, color: p.textSecondary)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
