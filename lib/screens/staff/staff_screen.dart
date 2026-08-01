import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/payment.dart';
import '../../models/staff.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';
import '../../widgets/filters.dart';
import '../../widgets/infinite_scroll.dart';
import '../../widgets/status_badge.dart';
import 'staff_form_screen.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> with InfiniteScroll {
  final _searchController = TextEditingController();
  String _status = '';
  int _page = 0;
  PageData<Staff>? _data;
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
      final data = await StaffService.list(page: _page, size: 10);
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
    final data = await StaffService.list(page: next, size: 10);
    if (!mounted || _data == null) return;
    setState(() {
      _page = next;
      _data = PageData<Staff>(
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

  List<Staff> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return (_data?.content ?? [])
        .where((s) {
          final matchesStatus =
              _status.isEmpty || s.status == _status;
          final matchesQuery = query.isEmpty ||
              s.name.toLowerCase().contains(query) ||
              s.email.toLowerCase().contains(query);
          return matchesStatus && matchesQuery;
        })
        .toList();
  }

  Future<void> _openForm({Staff? staff}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => StaffFormScreen(staff: staff)),
    );
    if (changed == true) _load();
  }

  Future<void> _deleteStaff(Staff staff) async {
    final ok = await showBusyDialog(
      context: context,
      title: 'Delete Staff',
      content: Text('Are you sure you want to delete ${staff.name}?'),
      confirmLabel: 'Delete',
      confirmColor: context.palette.danger,
      onConfirm: () async {
        await StaffService.delete(staff.id);
        return true;
      },
    );
    if (!ok || !mounted) return;
    showSuccessSnack(context, 'Staff deleted');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final total = _data?.totalElements ?? 0;
    final active = _data?.content.where((s) => s.isActive).length ?? 0;
    final inactive = _data?.content.where((s) => !s.isActive).length ?? 0;

    return Scaffold(
      backgroundColor: context.palette.scaffold,
      appBar: AppBar(
        title: const Text('Staff'),
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
                  hint: 'Search by name or email...',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilterChips<String>(
                    options: ['', ...staffStatuses],
                    selected: _status,
                    label: (v) => v.isEmpty ? 'All' : capitalize(v),
                    onSelected: (v) => setState(() => _status = v),
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
        label: const Text('Add Staff'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                _statChip(
                  context.palette,
                  label: 'Total',
                  value: formatNumber(total),
                  color: context.palette.textPrimary,
                ),
                const SizedBox(width: 8),
                _statChip(
                  context.palette,
                  label: 'Active',
                  value: formatNumber(active),
                  color: context.palette.success,
                ),
                const SizedBox(width: 8),
                _statChip(
                  context.palette,
                  label: 'Inactive',
                  value: formatNumber(inactive),
                  color: context.palette.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildList(),
          ],
        ),
      ),
    );
  }

  Widget _statChip(
    AppPalette p, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 12.5, color: p.textSecondary),
            ),
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
    final items = _filtered;
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.badge_outlined,
        title: 'No staff members found',
        subtitle: 'Try adjusting your search.',
      );
    }
    return Column(
      children: [
        for (final staff in items) ...[
          _StaffCard(
            staff: staff,
            onEdit: () => _openForm(staff: staff),
            onDelete: () => _deleteStaff(staff),
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

class _StaffCard extends StatelessWidget {
  final Staff staff;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _StaffCard({
    required this.staff,
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
                backgroundColor: p.purple.withValues(alpha: 0.12),
                child: Text(
                  toInitials(staff.name),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: p.purple,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      staff.email,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: p.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: staff.status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: p.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  capitalize(staff.role),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Admin ID: ${staff.adminId}',
                style: TextStyle(
                  fontSize: 12.5,
                  color: p.textSecondary,
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
}
