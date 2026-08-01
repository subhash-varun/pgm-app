import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/payment.dart';
import '../../models/user.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';
import '../../widgets/infinite_scroll.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with InfiniteScroll {
  PageData<Permission>? _data;
  bool _loading = true;
  String? _error;
  int _page = 0;

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
      final data = await PermissionsService.list(page: _page, size: 12);
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
    final data = await PermissionsService.list(page: next, size: 12);
    if (!mounted || _data == null) return;
    setState(() {
      _page = next;
      _data = PageData<Permission>(
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

  Future<void> _showForm({Permission? permission}) async {
    final keyController =
        TextEditingController(text: permission?.key ?? '');
    final nameController =
        TextEditingController(text: permission?.name ?? '');
    final descriptionController =
        TextEditingController(text: permission?.description ?? '');
    final formKey = GlobalKey<FormState>();
    final saved = await showBusyDialog(
      context: context,
      title: permission == null ? 'Create Permission' : 'Edit Permission',
      confirmLabel: permission == null ? 'Create' : 'Save',
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: keyController,
              decoration: const InputDecoration(
                labelText: 'Permission Key',
                hintText: 'e.g., users.create',
                helperText: 'Use lowercase with dots (e.g., module.action)',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Permission key is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                hintText: 'e.g., Create Users',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Display name is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      onConfirm: () async {
        if (!formKey.currentState!.validate()) return false;
        final payload = {
          'key': keyController.text.trim(),
          'name': nameController.text.trim(),
          'description': descriptionController.text.trim(),
        };
        if (permission == null) {
          await PermissionsService.create(payload);
        } else {
          await PermissionsService.update(permission.id, payload);
        }
        return true;
      },
    );
    if (!saved || !mounted) return;
    showSuccessSnack(
      context,
      permission == null
          ? 'Permission created successfully'
          : 'Permission updated successfully',
    );
    _load();
  }

  Future<void> _deletePermission(Permission permission) async {
    final ok = await showBusyDialog(
      context: context,
      title: 'Delete Permission',
      content: const Text(
          'This will affect all roles using it. Are you sure you want to delete this permission?'),
      confirmLabel: 'Delete',
      confirmColor: context.palette.danger,
      onConfirm: () async {
        await PermissionsService.delete(permission.id);
        return true;
      },
    );
    if (!ok || !mounted) return;
    showSuccessSnack(context, 'Permission deleted');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.scaffold,
      appBar: AppBar(
        title: const Text('Permissions'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text('Create Permission'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _data == null) {
      return const LoadingList();
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
              icon: Icons.key_outlined,
              title: 'No permissions found',
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
        final permission = data.content[index];
        return _PermissionCard(
          permission: permission,
          onEdit: () => _showForm(permission: permission),
          onDelete: () => _deletePermission(permission),
        );
      },
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final Permission permission;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _PermissionCard({
    required this.permission,
    required this.onEdit,
    required this.onDelete,
  });

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
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: p.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.key_outlined,
                    size: 20, color: p.danger),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      permission.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: p.surfaceAlt,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        permission.key,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontFamily: 'monospace',
                          color: p.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit',
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline,
                    size: 20, color: p.danger),
                tooltip: 'Delete',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            permission.description.isEmpty
                ? 'No description'
                : permission.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: p.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Created ${formatDate(permission.createdAt)}',
            style: TextStyle(fontSize: 12.5, color: p.textTertiary),
          ),
        ],
      ),
    );
  }
}
