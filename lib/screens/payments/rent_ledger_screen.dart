import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/payment.dart';
import '../../models/rent_ledger.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';
import '../../widgets/filters.dart';
import '../../widgets/status_badge.dart';
import 'pay_rent_dialog.dart';
import 'tenant_rent_history_screen.dart';

class RentLedgerScreen extends StatefulWidget {
  const RentLedgerScreen({super.key});

  @override
  State<RentLedgerScreen> createState() => _RentLedgerScreenState();
}

class _RentLedgerScreenState extends State<RentLedgerScreen> {
  late DateTime _selectedMonth;
  String _status = '';
  RentLedgerSummary? _summary;
  PageData<RentLedger>? _data;
  bool _loading = true;
  bool _generating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _load();
  }

  String get _monthString =>
      '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await RentLedgerService.getSummary(month: _monthString);
      final data = await RentLedgerService.getLedgers(
        month: _monthString,
        status: _status,
        page: 0,
        size: 50,
      );
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _data = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ApiClient.extractError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generateLedger() async {
    setState(() => _generating = true);
    try {
      await RentLedgerService.generateLedger(month: _monthString);
      if (!mounted) return;
      showSuccessSnack(context, 'Monthly rent ledger generated!');
      _load();
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, ApiClient.extractError(e));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta, 1);
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.scaffold,
      appBar: AppBar(
        title: const Text('Monthly Rent Ledger'),
        actions: [
          IconButton(
            icon: _loading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: p.primary,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Column(
          children: [
            if (_loading && _data != null)
              LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: Colors.transparent,
                color: p.primary,
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Month Selector & Generate Action
                  _MonthSelector(
                    monthLabel: formatMonthLabel(_monthString),
                    onPrev: () => _changeMonth(-1),
                    onNext: () => _changeMonth(1),
                    generating: _generating,
                    onGenerate: _generateLedger,
                  ),
                  const SizedBox(height: 16),

                  // Summary Metrics Row
                  if (_summary != null) _SummaryCards(summary: _summary!),
                  const SizedBox(height: 12),

                  // Late Fee Rules Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: p.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: p.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: p.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Rent Rules: Grace period until 5th of each month. Late fees auto-apply on overdue balances.',
                            style: TextStyle(fontSize: 11.5, color: p.textPrimary, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status Filter Chips
                  FilterChips<String>(
                    options: const ['', 'UNPAID', 'PARTIAL', 'PAID', 'OVERDUE'],
                    selected: _status,
                    label: (v) => v.isEmpty ? 'All' : capitalize(v),
                    onSelected: (v) {
                      setState(() => _status = v);
                      _load();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Ledger List
                  _buildList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading && _data == null) return const LoadingList();
    if (_error != null && _data == null) {
      return ErrorRetry(message: _error!, onRetry: _load);
    }
    final items = _data?.content ?? [];
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No Rent Entries',
        subtitle: 'Tap "Generate Rent" to create dues for active tenants.',
      );
    }

    return Column(
      children: [
        for (final item in items) ...[
          _LedgerCard(
            ledger: item,
            onPay: () => _showPayDialog(item),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TenantRentHistoryScreen(
                    tenantId: item.tenantId,
                    tenantName: item.tenantName,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  void _showPayDialog(RentLedger ledger) {
    showDialog(
      context: context,
      builder: (_) => PayRentDialog(
        ledger: ledger,
        onSuccess: _load,
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final String monthLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool generating;
  final VoidCallback onGenerate;

  const _MonthSelector({
    required this.monthLabel,
    required this.onPrev,
    required this.onNext,
    required this.generating,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: onPrev,
              ),
              Text(
                monthLabel,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: p.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: onNext,
              ),
            ],
          ),
          FilledButton.icon(
            onPressed: generating ? null : onGenerate,
            style: FilledButton.styleFrom(
              backgroundColor: p.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: generating
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.auto_mode, size: 16),
            label: Text(generating ? 'Generating...' : 'Generate Rent'),
          ),
        ],
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final RentLedgerSummary summary;
  const _SummaryCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Row(
      children: [
        _metricBox(p, 'Billed', formatCurrency(summary.totalBilled), p.primary),
        const SizedBox(width: 8),
        _metricBox(p, 'Collected', formatCurrency(summary.totalCollected), p.success),
        const SizedBox(width: 8),
        _metricBox(p, 'Pending', formatCurrency(summary.totalPending), p.warning),
        const SizedBox(width: 8),
        _metricBox(p, 'Overdue', '${summary.totalOverdueCount}', p.danger),
      ],
    );
  }

  Widget _metricBox(AppPalette p, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: p.textSecondary)),
            const SizedBox(height: 4),
            Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerCard extends StatelessWidget {
  final RentLedger ledger;
  final VoidCallback onPay;
  final VoidCallback onTap;

  const _LedgerCard({
    required this.ledger,
    required this.onPay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ledger.tenantName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: p.textPrimary,
                          ),
                        ),
                        Text(
                          'Room ${ledger.roomNumber}',
                          style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: ledger.status),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Total Rent: ${formatCurrency(ledger.totalAmount)}',
                            style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                          ),
                          if (ledger.lateFee > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: p.danger.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '+ ${formatCurrency(ledger.lateFee)} Late Fee',
                                style: TextStyle(fontSize: 11, color: p.danger, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'Paid: ${formatCurrency(ledger.paidAmount)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: p.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Due: ${formatCurrency(ledger.balanceDue)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: ledger.balanceDue > 0 ? p.danger : p.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (ledger.balanceDue > 0)
                    FilledButton.icon(
                      onPressed: onPay,
                      style: FilledButton.styleFrom(
                        backgroundColor: p.success,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.payment, size: 16),
                      label: const Text('Record Pay'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
