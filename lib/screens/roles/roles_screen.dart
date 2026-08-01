import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/payment.dart';
import '../../models/user.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';
import '../../widgets/infinite_scroll.dart';

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> with InfiniteScroll {
  PageData<Role>? _data;
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
      final data = await RolesService.list(page: _page, size: 10);
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
    final data = await RolesService.list(page: next, size: 10);
    if (!mounted || _data == null) return;
    setState(() {
      _page = next;
      _data = PageData<Role>(
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

  Future<void> _showForm({Role? role}) async {
    final nameController =
        TextEditingController(text: role?.name ?? '');
    final descriptionController =
        TextEditingController(text: role?.description ?? '');
    final formKey = GlobalKey<FormState>();
    final saved = await showBusyDialog(
      context: context,
      title: role == null ? 'Create Role' : 'Edit Role',
      confirmLabel: role == null ? 'Create' : 'Save',
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Role Name',
                hintText: 'e.g., Manager',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Role name is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descriptionController,
              maxLines: 3,
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
          'name': nameController.text.trim(),
          'description': descriptionController.text.trim(),
        };
        if (role == null) {
          await RolesService.create(payload);
        } else {
          await RolesService.update(role.id, payload);
        }
        return true;
      },
    );
    if (!saved || !mounted) return;
    showSuccessSnack(
      context,
      role == null ? 'Role created successfully' : 'Role updated successfully',
    );
    _load();
  }

  Future<void> _deleteRole(Role role) async {
    final ok = await showBusyDialog(
      context: context,
      title: 'Delete Role',
      content: Text(
          'Are you sure you want to delete "${role.name}"? This action cannot be undone.'),
      confirmLabel: 'Delete',
      confirmColor: context.palette.danger,
      onConfirm: () async {
        await RolesService.delete(role.id);
        return true;
      },
    );
    if (!ok || !mounted) return;
    showSuccessSnack(context, 'Role deleted');
    _load();
  }

  Future<void> _managePermissions(Role role) async {
    List<Permission> allPermissions = [];
    Set<int> assigned = {};
    var loading = true;
    String? error;

    try {
      final results = await Future.wait([
        PermissionsService.list(page: 0, size: 100),
        RolesService.permissionsFor(role.id),
      ]);
      allPermissions =
          (results[0] as PageData<Permission>).content;
      assigned =
          (results[1] as List<Permission>).map((p) => p.id).toSet();
    } catch (e) {
      error = ApiClient.extractError(e);
    } finally {
      loading = false;
    }

    if (!mounted) return;
    var saving = false;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          if (loading) {
            return const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (error != null) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(error),
            );
          }
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 4,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage Permissions - ${role.name}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: ctx.palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: allPermissions.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final p = allPermissions[i];
                        final checked = assigned.contains(p.id);
                        return CheckboxListTile(
                          value: checked,
                          onChanged: saving
                              ? null
                              : (v) {
                                  setSheetState(() {
                                    if (v == true) {
                                      assigned.add(p.id);
                                    } else {
                                      assigned.remove(p.id);
                                    }
                                  });
                                },
                          title: Text(
                            p.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ctx.palette.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            p.description.isEmpty ? p.key : p.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: ctx.palette.textSecondary,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            setSheetState(() => saving = true);
                            try {
                              await RolesService.assignPermissions(
                                role.id,
                                assigned.toList(),
                              );
                              if (ctx.mounted) Navigator.of(ctx).pop(true);
                            } catch (e) {
                              if (!ctx.mounted) return;
                              setSheetState(() => saving = false);
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text(ApiClient.extractError(e))),
                              );
                            }
                          },
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('Save Permissions'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (saved == true && mounted) {
      showSuccessSnack(context, 'Permissions updated successfully');
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.scaffold,
      appBar: AppBar(
        title: const Text('Roles'),
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
        label: const Text('Create Role'),
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
              icon: Icons.lock_outline,
              title: 'No roles found',
              subtitle: 'Create your first role to get started.',
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
        final role = data.content[index];
        return _RoleCard(
          role: role,
          onPermissions: () => _managePermissions(role),
          onEdit: () => _showForm(role: role),
          onDelete: role.isDefault ? null : () => _deleteRole(role),
        );
      },
    );
  }
}

class _RoleCard extends StatelessWidget {
  final Role role;
  final VoidCallback onPermissions;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  const _RoleCard({
    required this.role,
    required this.onPermissions,
    required this.onEdit,
    this.onDelete,
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
                  color: p.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.shield_outlined,
                    size: 20, color: p.success),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            role.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: p.textPrimary,
                            ),
                          ),
                        ),
                        if (role.isDefault) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: p.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle,
                                    size: 12, color: p.success),
                                const SizedBox(width: 3),
                                Text(
                                  'Default',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: p.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Created ${formatDate(role.createdAt)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: p.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            role.description.isEmpty ? 'No description' : role.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: p.border),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPermissions,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  icon: const Icon(Icons.key_outlined, size: 16),
                  label: const Text('Permissions'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit',
              ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline,
                      size: 20, color: p.danger),
                  tooltip: 'Delete',
                ),
            ],
          ),
        ],
      ),
    );
  }
}
