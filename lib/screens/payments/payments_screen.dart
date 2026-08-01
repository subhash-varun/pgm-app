import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/payment.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';
import '../../widgets/filters.dart';
import '../../widgets/infinite_scroll.dart';
import '../../widgets/status_badge.dart';
import 'receipt_screen.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> with InfiniteScroll {
  final _searchController = TextEditingController();
  String _status = '';
  int _page = 0;
  PageData<Payment>? _data;
  bool _loading = true;
  String? _error;
  final Set<int> _processing = {};

  @override
  bool get hasMore => _data != null && !_data!.last && _error == null;

  @override
  void initState() {
    super.initState();
    initInfiniteScroll();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    disposeInfiniteScroll();
    super.dispose();
  }

  Future<void> _load() async {
    if (scrollController.hasClients) scrollController.jumpTo(0);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await PaymentsService.list(
        status: _status,
        search: _searchController.text.trim(),
        page: _page,
        size: 10,
      );
      if (!mounted) return;
      setState(() => _data = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ApiClient.extractError(e));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        checkForMore();
      }
    }
  }

  @override
  Future<void> loadMorePage() async {
    final next = _page + 1;
    final data = await PaymentsService.list(
      status: _status,
      search: _searchController.text.trim(),
      page: next,
      size: 10,
    );
    if (!mounted || _data == null) return;
    setState(() {
      _page = next;
      _data = PageData<Payment>(
        content: [..._data!.content, ...data.content],
        totalElements: data.totalElements,
        totalPages: data.totalPages,
        pageNumber: next,
        pageSize: data.pageSize,
        first: data.first,
        last: data.last,
      );
    });
  }

  Future<void> _markAsPaid(Payment payment) async {
    setState(() => _processing.add(payment.id));
    try {
      await PaymentsService.markAsPaid(payment);
      if (!mounted) return;
      showSuccessSnack(context, 'Payment marked as paid');
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.extractError(e))),
      );
    } finally {
      if (mounted) setState(() => _processing.remove(payment.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.scaffold,
      appBar: AppBar(
        title: const Text('Payments'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                SearchField(
                  controller: _searchController,
                  hint: 'Search tenant name or receipt...',
                  onChanged: (_) {
                    _page = 0;
                    _load();
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilterChips<String>(
                    options: ['', ...paymentStatuses],
                    selected: _status,
                    label: (v) => v.isEmpty ? 'All' : capitalize(v),
                    onSelected: (v) {
                      setState(() {
                        _status = v;
                        _page = 0;
                      });
                      _load();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            _SummaryRow(payments: _data?.content ?? []),
            const SizedBox(height: 16),
            if (_data != null && _data!.content.isNotEmpty)
              _RevenueMiniChart(payments: _data!.content),
            const SizedBox(height: 16),
            _buildList(),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading && _data == null) {
      return const LoadingList();
    }
    if (_error != null && _data == null) {
      return ErrorRetry(message: _error!, onRetry: _load);
    }
    final data = _data!;
    if (data.content.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No payments found',
        subtitle: 'Try adjusting your filters.',
      );
    }
    return Column(
      children: [
        for (final payment in data.content) ...[
          _PaymentCard(
            payment: payment,
            processing: _processing.contains(payment.id),
            onMarkPaid: () => _markAsPaid(payment),
          ),
          const SizedBox(height: 10),
        ],
        LoadMoreFooter(
          hasMore: hasMore,
          loadingMore: loadingMore,
          error: loadMoreError,
          onRetry: retryLoadMore,
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final List<Payment> payments;
  const _SummaryRow({required this.payments});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final summary = PaymentSummary.compute(payments);
    return Row(
      children: [
        _summaryCard(
          p,
          icon: Icons.check_circle_outline,
          color: p.success,
          label: 'Collected',
          value: formatCurrency(summary.totalCollected),
        ),
        const SizedBox(width: 10),
        _summaryCard(
          p,
          icon: Icons.schedule,
          color: p.warning,
          label: 'Pending',
          value: formatCurrency(summary.totalPending),
        ),
        const SizedBox(width: 10),
        _summaryCard(
          p,
          icon: Icons.error_outline,
          color: p.danger,
          label: 'Overdue',
          value: formatCurrency(summary.totalOverdue),
        ),
      ],
    );
  }

  Widget _summaryCard(
    AppPalette p, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: p.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueMiniChart extends StatelessWidget {
  final List<Payment> payments;
  const _RevenueMiniChart({required this.payments});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final summary = PaymentSummary.compute(payments);
    if (summary.monthlyRevenue.isEmpty) return const SizedBox.shrink();
    final maxAmount = summary.monthlyRevenue
        .map((e) => e.amount)
        .fold(0.0, (a, b) => a > b ? a : b);
    final months = summary.monthlyRevenue;

    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Trend (Last 6 Months)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < months.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${(months[i].amount / 1000).round()}k',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: p.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: FractionallySizedBox(
                              alignment: Alignment.bottomCenter,
                              heightFactor: maxAmount == 0
                                  ? 0.04
                                  : (months[i].amount / maxAmount)
                                      .clamp(0.02, 1.0),
                              widthFactor: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: p.primary,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formatMonthLabel(months[i].month),
                            style: TextStyle(
                              fontSize: 12.5,
                              color: p.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Payment payment;
  final bool processing;
  final VoidCallback onMarkPaid;
  const _PaymentCard({
    required this.payment,
    required this.processing,
    required this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.tenantName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      payment.roomNumber == null
                          ? 'Receipt: ${payment.receiptNumber ?? 'N/A'}'
                          : 'Room ${payment.roomNumber} • Receipt: ${payment.receiptNumber ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: p.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: payment.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatCurrency(payment.amount),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: p.success,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${payment.paymentMethod.isEmpty ? '—' : capitalize(payment.paymentMethod)} • ${payment.paymentMonth.isNotEmpty ? formatMonthLabel(payment.paymentMonth) : 'N/A'}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: p.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (payment.isPaid)
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReceiptScreen(payment: payment),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      icon: const Icon(Icons.receipt, size: 16),
                      label: const Text('Receipt'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: processing ? null : onMarkPaid,
                      style: FilledButton.styleFrom(
                        backgroundColor: p.success,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      icon: processing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check, size: 16),
                      label: Text(processing ? 'Processing...' : 'Mark Paid'),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 12, color: p.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Paid on ${formatDate(payment.paymentDate.isNotEmpty ? payment.paymentDate : payment.createdAt)}',
                style: TextStyle(
                  fontSize: 12.5,
                  color: p.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
