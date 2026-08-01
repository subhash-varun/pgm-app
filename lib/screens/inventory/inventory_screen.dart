import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/inventory_item.dart';
import '../../models/payment.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';
import '../../widgets/filters.dart';
import '../../widgets/infinite_scroll.dart';
import '../../widgets/status_badge.dart';
import 'inventory_item_form_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with InfiniteScroll {
  final _searchController = TextEditingController();
  int _page = 0;
  PageData<InventoryItem>? _data;
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
      final data = await InventoryService.list(
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
    final data = await InventoryService.list(
      search: _searchController.text.trim(),
      page: next,
      size: 10,
    );
    if (!mounted || _data == null) return;
    setState(() {
      _page = next;
      _data = PageData<InventoryItem>(
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

  Future<void> _openForm({InventoryItem? item}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => InventoryItemFormScreen(item: item)),
    );
    if (changed == true) _load();
  }

  Future<void> _deleteItem(InventoryItem item) async {
    final ok = await showBusyDialog(
      context: context,
      title: 'Delete Item',
      content: Text(
          'This will permanently delete ${item.itemName} from room ${item.roomNumber}. This action cannot be undone.'),
      confirmLabel: 'Delete',
      confirmColor: context.palette.danger,
      onConfirm: () async {
        await InventoryService.delete(item.id);
        return true;
      },
    );
    if (!ok || !mounted) return;
    showSuccessSnack(context, 'Item deleted');
    _load();
  }

  void _showLowStock() {
    final items = _data?.content.where((i) => i.isLowStock).toList() ?? [];
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.report_problem, color: context.palette.warning),
                const SizedBox(width: 8),
                Text(
                  'Low Stock Alert!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.palette.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${items.length} item(s) have low stock: ${items.map((i) => '${i.itemName} (${i.quantity})').join(', ')}',
              style: TextStyle(fontSize: 13, color: context.palette.textPrimary),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lowStockCount =
        _data?.content.where((i) => i.isLowStock).length ?? 0;

    return Scaffold(
      backgroundColor: context.palette.scaffold,
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          if (lowStockCount > 0)
            IconButton(
              onPressed: _showLowStock,
              icon: Badge(
                label: Text('$lowStockCount'),
                child: Icon(Icons.report_problem_outlined,
                    color: context.palette.warning),
              ),
              tooltip: 'Low stock alert',
            ),
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchField(
              controller: _searchController,
              hint: 'Search items...',
              onChanged: (_) {
                _page = 0;
                _load();
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
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
                  label: 'Total Items',
                  value: formatNumber(_data?.totalElements ?? 0),
                  color: context.palette.textPrimary,
                ),
                const SizedBox(width: 8),
                _statChip(
                  context.palette,
                  label: 'Low Stock',
                  value: formatNumber(lowStockCount),
                  color: lowStockCount > 0
                      ? context.palette.warning
                      : context.palette.textSecondary,
                ),
                const SizedBox(width: 8),
                _statChip(
                  context.palette,
                  label: 'On This Page',
                  value: formatNumber(_data?.content.length ?? 0),
                  color: context.palette.primary,
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
              textAlign: TextAlign.center,
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
    final data = _data!;
    if (data.content.isEmpty) {
      return const EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No items found',
        subtitle: 'Try adjusting your search or add a new item.',
      );
    }
    return Column(
      children: [
        for (final item in data.content) ...[
          _ItemCard(
            item: item,
            onEdit: () => _openForm(item: item),
            onDelete: () => _deleteItem(item),
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

class _ItemCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ItemCard({
    required this.item,
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.inventory_2_outlined,
                    size: 20, color: p.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Room ${item.roomNumber}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: p.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.isLowStock)
                const StatusBadge(
                  status: 'LOW',
                  icon: Icons.error_outline,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Qty: ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: item.isLowStock ? p.danger : p.textPrimary,
                ),
              ),
              Text(
                '${item.quantity}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: item.isLowStock ? p.danger : p.textPrimary,
                ),
              ),
              const Spacer(),
              StatusBadge(status: item.conditionStatus),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.update, size: 12, color: p.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Updated ${formatDateTime(item.lastUpdated)}',
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
