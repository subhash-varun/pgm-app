import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/payment.dart';
import '../../models/room.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';
import '../../widgets/filters.dart';
import '../../widgets/infinite_scroll.dart';
import '../../widgets/status_badge.dart';
import 'room_form_screen.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> with InfiniteScroll {
  String _type = '';
  String _status = '';
  int _page = 0;
  PageData<Room>? _data;
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
      final data = await RoomsService.list(
        type: _type,
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
    final data = await RoomsService.list(
      type: _type,
      status: _status,
      page: next,
      size: 10,
    );
    if (!mounted || _data == null) return;
    setState(() {
      _page = next;
      _data = PageData<Room>(
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

  Future<void> _openForm({Room? room}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => RoomFormScreen(room: room)),
    );
    if (changed == true) _load();
  }

  Future<void> _deleteRoom(Room room) async {
    final ok = await showBusyDialog(
      context: context,
      title: 'Delete Room',
      content: Text(
          'Are you sure you want to delete room ${room.roomNumber}? This action cannot be undone.'),
      confirmLabel: 'Delete',
      confirmColor: context.palette.danger,
      onConfirm: () async {
        await RoomsService.delete(room.id);
        return true;
      },
    );
    if (!ok || !mounted) return;
    showSuccessSnack(context, 'Room deleted');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final current = _data;
    final available = current?.content
            .where((r) => r.status == 'AVAILABLE')
            .length ??
        0;
    final occupied =
        current?.content.where((r) => r.status == 'OCCUPIED').length ?? 0;
    final maintenance =
        current?.content.where((r) => r.status == 'MAINTENANCE').length ?? 0;

    return Scaffold(
      backgroundColor: context.palette.scaffold,
      appBar: AppBar(
        title: const Text('Rooms'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: FilterChips<String>(
                    options: ['', ...roomTypes],
                    selected: _type,
                    label: (v) => v.isEmpty ? 'All Types' : capitalize(v),
                    onSelected: (v) {
                      setState(() {
                        _type = v;
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
        label: const Text('Add Room'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                _StatChip(
                  label: 'Total',
                  value: formatNumber(current?.totalElements ?? 0),
                  color: context.palette.textPrimary,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Available',
                  value: formatNumber(available),
                  color: context.palette.success,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Occupied',
                  value: formatNumber(occupied),
                  color: context.palette.danger,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Maint.',
                  value: formatNumber(maintenance),
                  color: context.palette.warning,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  FilterChips<String>(
                    options: ['', ...roomStatuses],
                    selected: _status,
                    label: (v) => v.isEmpty ? 'All Status' : capitalize(v),
                    onSelected: (v) {
                      setState(() {
                        _status = v;
                        _page = 0;
                      });
                      _load();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
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
        icon: Icons.meeting_room_outlined,
        title: 'No rooms found',
        subtitle: 'Try adjusting your filters or add a new room.',
      );
    }
    return Column(
      children: [
        for (final room in data.content) ...[
          _RoomCard(
            room: room,
            onEdit: () => _openForm(room: room),
            onDelete: () => _deleteRoom(room),
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

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
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

class _RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _RoomCard({
    required this.room,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final statusColor = switch (room.status) {
      'AVAILABLE' => p.success,
      'OCCUPIED' => p.danger,
      _ => p.warning,
    };
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
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.meeting_room, size: 20, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room ${room.roomNumber}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${capitalize(room.roomType)} Room',
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
                  Text(
                    formatCurrency(room.rentAmount),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: p.success,
                    ),
                  ),
                  const SizedBox(height: 4),
                  StatusBadge(status: room.status),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 13, color: p.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  room.facilities.isEmpty
                      ? 'No facilities listed'
                      : room.facilities,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: p.textPrimary,
                  ),
                ),
              ),
              Text(
                'Since ${formatDate(room.createdAt)}',
                style: TextStyle(
                  fontSize: 12.5,
                  color: p.textTertiary,
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
