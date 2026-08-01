import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/rent_ledger.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';
import '../../widgets/status_badge.dart';

class TenantRentHistoryScreen extends StatefulWidget {
  final int tenantId;
  final String tenantName;

  const TenantRentHistoryScreen({
    super.key,
    required this.tenantId,
    required this.tenantName,
  });

  @override
  State<TenantRentHistoryScreen> createState() => _TenantRentHistoryScreenState();
}

class _TenantRentHistoryScreenState extends State<TenantRentHistoryScreen> {
  List<RentLedger>? _ledgers;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await RentLedgerService.getLedgersByTenant(widget.tenantId);
      if (!mounted) return;
      setState(() => _ledgers = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ApiClient.extractError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.scaffold,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rent History Ledger', style: TextStyle(fontSize: 18)),
            Text(widget.tenantName, style: TextStyle(fontSize: 12, color: p.textSecondary)),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingList();
    if (_error != null) return ErrorRetry(message: _error!, onRetry: _load);
    final items = _ledgers ?? [];
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.history,
        title: 'No Rent Ledger Records',
        subtitle: 'No monthly billing statements generated yet for this tenant.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final item = items[i];
        return _LedgerHistoryCard(ledger: item);
      },
    );
  }
}

class _LedgerHistoryCard extends StatelessWidget {
  final RentLedger ledger;
  const _LedgerHistoryCard({required this.ledger});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_month, color: p.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    formatMonthLabel(ledger.billingMonth),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: p.textPrimary),
                  ),
                ],
              ),
              StatusBadge(status: ledger.status),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _colMetric('Total Billed', formatCurrency(ledger.totalAmount), p.textPrimary),
              _colMetric('Paid Amount', formatCurrency(ledger.paidAmount), p.success),
              _colMetric('Balance Due', formatCurrency(ledger.balanceDue), p.danger),
            ],
          ),
          if (ledger.utilityCharges > 0 || ledger.lateFee > 0) ...[
            const SizedBox(height: 10),
            Text(
              'Includes: ${ledger.utilityCharges > 0 ? 'Utilities ₹${ledger.utilityCharges}  ' : ''}${ledger.lateFee > 0 ? 'Late Fee ₹${ledger.lateFee}' : ''}',
              style: TextStyle(fontSize: 11.5, color: p.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _colMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
