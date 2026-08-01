import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/payment.dart';
import '../../models/tenant.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';
import '../../widgets/filters.dart';
import '../../widgets/infinite_scroll.dart';
import '../../widgets/status_badge.dart';
import 'tenant_form_screen.dart';
import 'notice_period_dialog.dart';
import 'tenant_settlement_screen.dart';
import '../payments/tenant_rent_history_screen.dart';

class TenantsScreen extends StatefulWidget {
  const TenantsScreen({super.key});

  @override
  State<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen> with InfiniteScroll {
  final _searchController = TextEditingController();
  String _status = '';
  int _page = 0;
  PageData<Tenant>? _data;
  bool _loading = true;
  String? _error;

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
      final data = await TenantsService.list(
        search: _searchController.text.trim(),
        status: _status,
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
    final data = await TenantsService.list(
      search: _searchController.text.trim(),
      status: _status,
      page: next,
      size: 10,
    );
    if (!mounted || _data == null) return;
    setState(() {
      _page = next;
      _data = PageData<Tenant>(
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

  Future<void> _openForm({Tenant? tenant}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TenantFormScreen(tenant: tenant)),
    );
    if (changed == true) _load();
  }

  Future<void> _deleteTenant(Tenant tenant) async {
    final ok = await showBusyDialog(
      context: context,
      title: 'Delete Tenant',
      content: Text(
          'Are you sure you want to delete ${tenant.name}? This action cannot be undone.'),
      confirmLabel: 'Delete',
      confirmColor: context.palette.danger,
      onConfirm: () async {
        await TenantsService.delete(tenant.id);
        return true;
      },
    );
    if (!ok || !mounted) return;
    showSuccessSnack(context, 'Tenant deleted');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.scaffold,
      appBar: AppBar(
        title: const Text('Tenants'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: _loading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.palette.primary,
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh',
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
                  hint: 'Search tenants...',
                  onChanged: (_) {
                    _page = 0;
                    _load();
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilterChips<String>(
                    options: const ['', 'ACTIVE', 'NOTICE', 'MOVED_OUT'],
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Tenant'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Column(
          children: [
            if (_loading && _data != null)
              LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: Colors.transparent,
                color: context.palette.primary,
              ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _data == null) {
      return ListView(children: const [LoadingList()]);
    }
    if (_error != null && _data == null) {
      return ListView(children: [ErrorRetry(message: _error!, onRetry: _load)]);
    }
    final data = _data!;
    if (data.content.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            EmptyState(
              icon: Icons.people_outline,
              title: 'No tenants found',
              subtitle: 'Try adjusting your filters or add a new tenant.',
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      itemCount: data.content.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == data.content.length) {
          return LoadMoreFooter(
            hasMore: hasMore,
            loadingMore: loadingMore,
            error: loadMoreError,
            onRetry: retryLoadMore,
          );
        }
        final tenant = data.content[index];
        return _TenantCard(
          tenant: tenant,
          onEdit: () => _openForm(tenant: tenant),
          onDelete: () => _deleteTenant(tenant),
          onRefresh: _load,
        );
      },
    );
  }
}

class _TenantCard extends StatelessWidget {
  final Tenant tenant;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;
  const _TenantCard({
    required this.tenant,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: p.primary.withValues(alpha: 0.12),
                child: Text(
                  toInitials(tenant.name),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: p.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            tenant.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: p.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: p.surfaceAlt,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Room ${tenant.roomNumber}',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: p.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${tenant.phone} • ${tenant.email}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: p.textSecondary),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: tenant.status),
            ],
          ),
          const SizedBox(height: 10),

          // Key Info Grid
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: p.surfaceAlt.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoCol(p, 'Deposit', formatCurrency(tenant.depositAmount), p.success),
                _infoCol(p, 'Advance', formatCurrency(tenant.advanceBalance), p.primary),
                _infoCol(p, 'Check-in', formatDate(tenant.checkInDate), p.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Action Row
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TenantRentHistoryScreen(
                        tenantId: tenant.id,
                        tenantName: tenant.name,
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.history, size: 15),
                label: const Text('Ledger', style: TextStyle(fontSize: 12.5)),
              ),
              if (tenant.isActive) ...[
                const SizedBox(width: 6),
                OutlinedButton.icon(
                  onPressed: () async {
                    final res = await showDialog<bool>(
                      context: context,
                      builder: (_) => NoticePeriodDialog(tenant: tenant),
                    );
                    if (res == true) onRefresh();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: p.warning,
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    side: BorderSide(color: p.warning.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.outbound_outlined, size: 15),
                  label: const Text('Notice', style: TextStyle(fontSize: 12.5)),
                ),
              ],
              if (tenant.isActive || tenant.isInNotice) ...[
                const SizedBox(width: 6),
                OutlinedButton.icon(
                  onPressed: () async {
                    final res = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => TenantSettlementScreen(
                          tenantId: tenant.id,
                          tenantName: tenant.name,
                        ),
                      ),
                    );
                    if (res == true) onRefresh();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: p.danger,
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    side: BorderSide(color: p.danger.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.exit_to_app, size: 15),
                  label: const Text('Exit', style: TextStyle(fontSize: 12.5)),
                ),
              ],
              const Spacer(),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: p.textSecondary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Edit Tenant')])),
                  PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: p.danger), const SizedBox(width: 8), Text('Delete', style: TextStyle(color: p.danger))])),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoCol(AppPalette p, String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: p.textTertiary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 1),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor)),
      ],
    );
  }
}
