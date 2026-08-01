import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/tenant.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';
import '../../widgets/status_badge.dart';
import '../tenants/tenant_settlement_screen.dart';

class SecurityDepositScreen extends StatefulWidget {
  const SecurityDepositScreen({super.key});

  @override
  State<SecurityDepositScreen> createState() => _SecurityDepositScreenState();
}

class _SecurityDepositScreenState extends State<SecurityDepositScreen> {
  List<Tenant> _tenants = [];
  bool _loading = true;
  String? _error;
  String _filter = 'ALL';

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
      final page = await TenantsService.list(page: 0, size: 100);
      if (!mounted) return;
      setState(() => _tenants = page.content);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ApiClient.extractError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _totalDeposits => _tenants.fold(0.0, (sum, t) => sum + t.depositAmount);
  double get _activeDeposits => _tenants.where((t) => t.isActive).fold(0.0, (sum, t) => sum + t.depositAmount);
  double get _noticeDeposits => _tenants.where((t) => t.isInNotice).fold(0.0, (sum, t) => sum + t.depositAmount);

  List<Tenant> get _filteredTenants {
    if (_filter == 'ACTIVE') return _tenants.where((t) => t.isActive).toList();
    if (_filter == 'NOTICE') return _tenants.where((t) => t.isInNotice).toList();
    if (_filter == 'MOVED_OUT') return _tenants.where((t) => t.hasMovedOut).toList();
    return _tenants;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.scaffold,
      appBar: AppBar(
        title: const Text('Security Deposit Ledger'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(p),
      ),
    );
  }

  Widget _buildBody(AppPalette p) {
    if (_loading) return const LoadingList();
    if (_error != null) return ErrorRetry(message: _error!, onRetry: _load);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Metrics Cards
          Row(
            children: [
              _metricCard(p, 'Total Deposits', formatCurrency(_totalDeposits), Icons.account_balance, p.primary),
              const SizedBox(width: 10),
              _metricCard(p, 'Active Deposits', formatCurrency(_activeDeposits), Icons.shield_outlined, p.success),
              const SizedBox(width: 10),
              _metricCard(p, 'Notice Refunds', formatCurrency(_noticeDeposits), Icons.outbound_outlined, p.warning),
            ],
          ),
          const SizedBox(height: 16),

          // Filter Segment
          Row(
            children: [
              Text('Tenant Deposits', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.textPrimary)),
              const Spacer(),
              DropdownButton<String>(
                value: _filter,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('All Tenants')),
                  DropdownMenuItem(value: 'ACTIVE', child: Text('Active Only')),
                  DropdownMenuItem(value: 'NOTICE', child: Text('On Notice')),
                  DropdownMenuItem(value: 'MOVED_OUT', child: Text('Moved Out')),
                ],
                onChanged: (v) => setState(() => _filter = v!),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tenant Deposit List
          if (_filteredTenants.isEmpty)
            const EmptyState(icon: Icons.shield_moon_outlined, title: 'No deposits found', subtitle: 'No tenants match the selected filter.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredTenants.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (ctx, idx) {
                final tenant = _filteredTenants[idx];
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
                                Text(tenant.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.textPrimary)),
                                const SizedBox(height: 2),
                                Text('Room ${tenant.roomNumber} • Check-in: ${formatDate(tenant.checkInDate)}', style: TextStyle(fontSize: 12.5, color: p.textSecondary)),
                              ],
                            ),
                          ),
                          StatusBadge(status: tenant.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Security Deposit Paid', style: TextStyle(fontSize: 11, color: p.textTertiary, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(formatCurrency(tenant.depositAmount), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.success)),
                              ],
                            ),
                          ),
                          if (tenant.advanceBalance > 0)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Advance Credit', style: TextStyle(fontSize: 11, color: p.textTertiary, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(formatCurrency(tenant.advanceBalance), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.primary)),
                                ],
                              ),
                            ),
                          if (tenant.isActive || tenant.isInNotice)
                            OutlinedButton.icon(
                              onPressed: () async {
                                final res = await Navigator.of(context).push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) => TenantSettlementScreen(tenantId: tenant.id, tenantName: tenant.name),
                                  ),
                                );
                                if (res == true) _load();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: p.danger,
                                side: BorderSide(color: p.danger.withValues(alpha: 0.5)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(Icons.output_rounded, size: 16),
                              label: const Text('Refund / Exit'),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _metricCard(AppPalette p, String title, String value, IconData icon, Color color) {
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
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.textPrimary), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
          ],
        ),
      ),
    );
  }
}
