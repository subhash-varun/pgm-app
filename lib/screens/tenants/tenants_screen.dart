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
            icon: const Icon(Icons.refresh),
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
                    options: ['', 'ACTIVE', 'MOVED_OUT'],
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
        child: _buildBody(),
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
        );
      },
    );
  }
}

class _TenantCard extends StatelessWidget {
  final Tenant tenant;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _TenantCard({
    required this.tenant,
    required this.onEdit,
    required this.onDelete,
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
              CircleAvatar(
                radius: 20,
                backgroundColor: p.primary.withValues(alpha: 0.12),
                child: Text(
                  toInitials(tenant.name),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: p.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Room ${tenant.roomNumber} • ${tenant.email}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: p.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: tenant.status),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _meta(p, Icons.phone_outlined, tenant.phone),
              _meta(p, Icons.badge_outlined,
                  '${tenant.idProofType}: ${tenant.idProofNumber}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 14, color: p.textTertiary),
              const SizedBox(width: 4),
              Text(
                'Check-in ${formatDate(tenant.checkInDate)}',
                style: TextStyle(fontSize: 12.5, color: p.textSecondary),
              ),
              const Spacer(),
              Text(
                'Deposit: ${formatCurrency(tenant.depositAmount)}',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: p.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: p.border),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: onDelete,
                style: TextButton.styleFrom(
                  foregroundColor: p.danger,
                ),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(AppPalette p, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: p.textTertiary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, color: p.textPrimary),
          ),
        ),
      ],
    );
  }
}
