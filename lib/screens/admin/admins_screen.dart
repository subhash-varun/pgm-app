import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/payment.dart';
import '../../models/user.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';
import '../../widgets/infinite_scroll.dart';

class AdminsScreen extends StatefulWidget {
  const AdminsScreen({super.key});

  @override
  State<AdminsScreen> createState() => _AdminsScreenState();
}

class _AdminsScreenState extends State<AdminsScreen> with InfiniteScroll {
  PageData<Admin>? _data;
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
      final data = await AdminsService.list(page: _page, size: 12);
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
    final data = await AdminsService.list(page: next, size: 12);
    if (!mounted || _data == null) return;
    setState(() {
      _page = next;
      _data = PageData<Admin>(
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

  Future<void> _showForm({Admin? admin}) async {
    final nameController = TextEditingController(text: admin?.name ?? '');
    final emailController = TextEditingController(text: admin?.email ?? '');
    final passwordController = TextEditingController();
    final contactController =
        TextEditingController(text: admin?.contactNo ?? '');
    final formKey = GlobalKey<FormState>();
    final saved = await showBusyDialog(
      context: context,
      title: admin == null ? 'Create Admin' : 'Edit Admin',
      confirmLabel: admin == null ? 'Create' : 'Save',
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'John Doe',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'john@example.com',
                ),
                validator: (v) {
                  final email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (v == null || !email.hasMatch(v.trim())) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              if (admin == null) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: contactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  hintText: '1234567890',
                ),
              ),
            ],
          ),
        ),
      ),
      onConfirm: () async {
        if (!formKey.currentState!.validate()) return false;
        if (admin == null) {
          await AdminsService.create({
            'name': nameController.text.trim(),
            'email': emailController.text.trim(),
            'password': passwordController.text,
            'contactNo': contactController.text.trim(),
          });
        } else {
          await AdminsService.update(admin.id, {
            'name': nameController.text.trim(),
            'email': emailController.text.trim(),
            'contactNo': contactController.text.trim(),
          });
        }
        return true;
      },
    );
    if (!saved || !mounted) return;
    showSuccessSnack(
      context,
      admin == null ? 'Admin created successfully' : 'Admin updated successfully',
    );
    _load();
  }

  Future<void> _deleteAdmin(Admin admin) async {
    final ok = await showBusyDialog(
      context: context,
      title: 'Delete Admin',
      content: Text(
          'Are you sure you want to delete administrator ${admin.name}?'),
      confirmLabel: 'Delete',
      confirmColor: context.palette.danger,
      onConfirm: () async {
        await AdminsService.delete(admin.id);
        return true;
      },
    );
    if (!ok || !mounted) return;
    showSuccessSnack(context, 'Admin deleted');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.scaffold,
      appBar: AppBar(
        title: const Text('Admins'),
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
        label: const Text('Create Admin'),
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
                  label: 'Total Admins',
                  value: formatNumber(_data?.totalElements ?? 0),
                  color: context.palette.textPrimary,
                ),
                const SizedBox(width: 8),
                _statChip(
                  label: 'On This Page',
                  value: formatNumber(_data?.content.length ?? 0),
                  color: context.palette.primary,
                ),
                const SizedBox(width: 8),
                _statChip(
                  label: 'Pages',
                  value: formatNumber(_data?.totalPages ?? 0),
                  color: context.palette.purple,
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

  Widget _statChip({
    required String label,
    required String value,
    required Color color,
  }) {
    final p = context.palette;
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
                fontSize: 15,
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
        icon: Icons.admin_panel_settings_outlined,
        title: 'No admins found',
      );
    }
    return Column(
      children: [
        for (final admin in data.content) ...[
          _AdminCard(
            admin: admin,
            onEdit: () => _showForm(admin: admin),
            onDelete: () => _deleteAdmin(admin),
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

class _AdminCard extends StatelessWidget {
  final Admin admin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _AdminCard({
    required this.admin,
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
              CircleAvatar(
                radius: 22,
                backgroundColor: p.info.withValues(alpha: 0.12),
                child: Text(
                  toInitials(admin.name),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: p.info,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      admin.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${admin.id}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: p.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: p.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 12, color: p.info),
                    const SizedBox(width: 4),
                    Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: p.info,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(p, Icons.mail_outline, admin.email),
          const SizedBox(height: 6),
          _infoRow(p,
              Icons.phone_outlined, admin.contactNo.isEmpty ? '—' : admin.contactNo),
          const SizedBox(height: 6),
          _infoRow(p,
              Icons.calendar_today_outlined, 'Joined ${formatDate(admin.createdAt)}'),
          const SizedBox(height: 12),
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

  Widget _infoRow(AppPalette p, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: p.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: p.textPrimary),
          ),
        ),
      ],
    );
  }
}
