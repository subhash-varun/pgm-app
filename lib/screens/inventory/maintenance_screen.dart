import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/maintenance_request.dart';
import '../../models/payment.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';
import '../../widgets/filters.dart';
import '../../widgets/infinite_scroll.dart';
import '../../widgets/status_badge.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen>
    with InfiniteScroll {
  final _searchController = TextEditingController();
  String _status = '';
  String _priority = '';
  int _page = 0;
  PageData<MaintenanceRequest>? _data;
  bool _loading = true;
  String? _error;
  final Set<int> _saving = {};

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
      final data = await MaintenanceService.list(
        status: _status,
        priority: _priority,
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
    final data = await MaintenanceService.list(
      status: _status,
      priority: _priority,
      search: _searchController.text.trim(),
      page: next,
      size: 10,
    );
    if (!mounted || _data == null) return;
    setState(() {
      _page = next;
      _data = PageData<MaintenanceRequest>(
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

  Future<void> _updateStatus(MaintenanceRequest request, String status) async {
    if (request.status == status) return;
    setState(() => _saving.add(request.id));
    try {
      await MaintenanceService.updateStatus(request.id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.extractError(e))),
      );
    } finally {
      if (mounted) setState(() => _saving.remove(request.id));
    }
  }

  Future<void> _assign(MaintenanceRequest request, String staffName) async {
    if (request.assignedTo == staffName) return;
    setState(() => _saving.add(request.id));
    try {
      await MaintenanceService.assignStaff(request.id, staffName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assigned to $staffName')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.extractError(e))),
      );
    } finally {
      if (mounted) setState(() => _saving.remove(request.id));
    }
  }

  void _showReportIssue() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => const _ReportIssueSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.scaffold,
      appBar: AppBar(
        title: const Text('Maintenance'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(148),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                SearchField(
                  controller: _searchController,
                  hint: 'Search tenant or issue...',
                  onChanged: (_) {
                    _page = 0;
                    _load();
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilterChips<String>(
                        options: ['', ...maintenanceStatuses],
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilterChips<String>(
                        options: ['', ...maintenancePriorities],
                        selected: _priority,
                        label: (v) => v.isEmpty ? 'All Priority' : capitalize(v),
                        onSelected: (v) {
                          setState(() {
                            _priority = v;
                            _page = 0;
                          });
                          _load();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _showReportIssue,
        icon: const Icon(Icons.add),
        label: const Text('Report Issue'),
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
              icon: Icons.build_outlined,
              title: 'No maintenance requests',
              subtitle: 'Try adjusting your filters.',
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
        final request = data.content[index];
        return _MaintenanceCard(
          request: request,
          saving: _saving.contains(request.id),
          onStatusChange: (s) => _updateStatus(request, s),
          onAssign: (name) => _assign(request, name),
        );
      },
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  final MaintenanceRequest request;
  final bool saving;
  final ValueChanged<String> onStatusChange;
  final ValueChanged<String> onAssign;
  const _MaintenanceCard({
    required this.request,
    required this.saving,
    required this.onStatusChange,
    required this.onAssign,
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
                  color: p.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.build_outlined,
                    size: 20, color: p.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.issueTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${request.tenantName} • Room ${request.roomNumber}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: p.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (request.imageUrl != null && request.imageUrl!.isNotEmpty)
                Icon(Icons.image_outlined, size: 18, color: p.primary),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            request.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: p.textPrimary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              StatusBadge(status: request.priority),
              const SizedBox(width: 8),
              StatusBadge(status: request.status),
              const Spacer(),
              Text(
                formatRelativeTime(request.createdAt),
                style: TextStyle(fontSize: 12.5, color: p.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: p.border),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DropdownField(
                  label: 'Status',
                  value: request.status,
                  options: maintenanceStatuses,
                  onChanged: onStatusChange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DropdownField(
                  label: 'Assigned To',
                  value: request.assignedTo ?? '',
                  options: assignableStaff,
                  placeholder: 'Unassigned',
                  onChanged: onAssign,
                ),
              ),
            ],
          ),
          if (saving) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 2),
          ],
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final String? placeholder;
  final ValueChanged<String> onChanged;
  const _DropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12.5, color: p.textSecondary),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: p.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value.isEmpty ? null : value,
              hint: Text(
                placeholder ?? 'Select',
                style: TextStyle(fontSize: 13, color: p.textTertiary),
              ),
              items: options
                  .map((o) => DropdownMenuItem(
                        value: o,
                        child: Text(
                          capitalize(o),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportIssueSheet extends StatefulWidget {
  const _ReportIssueSheet();

  @override
  State<_ReportIssueSheet> createState() => _ReportIssueSheetState();
}

class _ReportIssueSheetState extends State<_ReportIssueSheet> {
  final _formKey = GlobalKey<FormState>();
  final _roomController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _priority = 'MEDIUM';
  bool _submitting = false;

  @override
  void dispose() {
    _roomController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    Navigator.of(context).pop();
    showSuccessSnack(context, 'Request submitted successfully');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Report Maintenance Issue',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roomController,
                decoration: const InputDecoration(
                  labelText: 'Room Number',
                  hintText: '101',
                  prefixIcon: Icon(Icons.meeting_room_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Room number is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Issue Title',
                  hintText: 'AC not cooling',
                  prefixIcon: Icon(Icons.build_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Issue title is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Please describe the issue...',
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().length < 10)
                        ? 'Description must be at least 10 characters'
                        : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  prefixIcon: Icon(Icons.priority_high),
                ),
                items: maintenancePriorities
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p == 'HIGH'
                              ? 'HIGH (Urgent)'
                              : capitalize(p)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _priority = v ?? 'MEDIUM'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('Submit Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
