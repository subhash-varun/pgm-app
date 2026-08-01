import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/app_notification.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  NotificationList? _data;
  int _unread = 0;
  bool _loading = true;
  String? _error;
  bool _canSend = false;
  bool _prefsLoading = true;
  NotificationPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadNotifications(), _loadCanSend(), _loadPrefs()]);
  }

  Future<void> _loadNotifications() async {
    try {
      final results = await Future.wait([
        NotificationsService.list(page: 0, size: 20),
        NotificationsService.unreadCount(),
      ]);
      if (!mounted) return;
      setState(() {
        _data = results[0] as NotificationList;
        _unread = results[1] as int;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ApiClient.extractError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadCanSend() async {
    try {
      final can = await NotificationsService.canCreateNotifications();
      if (!mounted) return;
      setState(() => _canSend = can);
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadPrefs() async {
    setState(() => _prefsLoading = true);
    try {
      final prefs = await NotificationsService.getPreferences();
      if (!mounted) return;
      setState(() => _prefs = prefs);
    } catch (e) {
      if (!mounted) return;
      setState(() => _prefsLoading = false);
    } finally {
      if (mounted) setState(() => _prefsLoading = false);
    }
  }

  Future<void> _markRead(AppNotification n) async {
    try {
      await NotificationsService.markRead(n.id);
      if (!mounted) return;
      setState(() {
        _unread = (_unread - 1).clamp(0, 1 << 31);
        final list = _data?.notifications ?? <AppNotification>[];
        for (final x in list) {
          if (x.id == n.id) x.isRead = true;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.extractError(e))),
      );
    }
  }

  Future<void> _markAllRead() async {
    try {
      await NotificationsService.markAllRead();
      if (!mounted) return;
      setState(() {
        _unread = 0;
        for (final n in _data?.notifications ?? <AppNotification>[]) {
          n.isRead = true;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.extractError(e))),
      );
    }
  }

  Future<void> _togglePref(String key, bool value) async {
    try {
      await NotificationsService.updatePreferences({key: value});
      if (!mounted) return;
      setState(() {
        final p = _prefs;
        if (p == null) return;
        switch (key) {
          case 'emailEnabled':
            _prefs = NotificationPreferences(
              id: p.id,
              userId: p.userId,
              emailEnabled: value,
              pushEnabled: p.pushEnabled,
              smsEnabled: p.smsEnabled,
              webEnabled: p.webEnabled,
              createdAt: p.createdAt,
            );
          case 'pushEnabled':
            _prefs = NotificationPreferences(
              id: p.id,
              userId: p.userId,
              emailEnabled: p.emailEnabled,
              pushEnabled: value,
              smsEnabled: p.smsEnabled,
              webEnabled: p.webEnabled,
              createdAt: p.createdAt,
            );
          case 'smsEnabled':
            _prefs = NotificationPreferences(
              id: p.id,
              userId: p.userId,
              emailEnabled: p.emailEnabled,
              pushEnabled: p.pushEnabled,
              smsEnabled: value,
              webEnabled: p.webEnabled,
              createdAt: p.createdAt,
            );
          case 'webEnabled':
            _prefs = NotificationPreferences(
              id: p.id,
              userId: p.userId,
              emailEnabled: p.emailEnabled,
              pushEnabled: p.pushEnabled,
              smsEnabled: p.smsEnabled,
              webEnabled: value,
              createdAt: p.createdAt,
            );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.extractError(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.scaffold,
      appBar: AppBar(
        title: const Text('Notifications'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Notifications'),
            Tab(text: 'Send'),
            Tab(text: 'Preferences'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _NotificationsTab(
            data: _data,
            unread: _unread,
            loading: _loading,
            error: _error,
            onRefresh: _loadNotifications,
            onMarkRead: _markRead,
            onMarkAllRead: _markAllRead,
          ),
          if (_canSend) _SendTab() else const _NoPermissionTab(),
          _PreferencesTab(
            prefs: _prefs,
            loading: _prefsLoading,
            onToggle: _togglePref,
          ),
        ],
      ),
    );
  }
}

class _NotificationsTab extends StatelessWidget {
  final NotificationList? data;
  final int unread;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  final ValueChanged<AppNotification> onMarkRead;
  final VoidCallback onMarkAllRead;
  const _NotificationsTab({
    required this.data,
    required this.unread,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onMarkRead,
    required this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (unread > 0)
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.palette.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$unread unread',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: context.palette.danger,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onMarkAllRead,
                  icon: const Icon(Icons.done_all, size: 16),
                  label: const Text('Mark All Read'),
                ),
              ],
            ),
          if (loading && data == null)
            const LoadingList()
          else if (error != null && data == null)
            ErrorRetry(message: error!, onRetry: onRefresh)
          else if (data == null || data!.notifications.isEmpty)
            const EmptyState(
              icon: Icons.notifications_none,
              title: 'No notifications yet',
              subtitle: "You're all caught up!",
            )
          else
            for (final n in data!.notifications) ...[
              _NotificationItem(
                notification: n,
                onMarkRead: () => onMarkRead(n),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onMarkRead;
  const _NotificationItem({
    required this.notification,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (icon, color) = _typeConfig(p, notification.type);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: notification.isRead
            ? p.surface
            : p.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead ? p.border : p.primary,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: notification.isRead
                              ? p.textPrimary
                              : p.primary,
                        ),
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: p.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      formatRelativeTime(notification.createdAt),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: p.textTertiary,
                      ),
                    ),
                    if (notification.targetRole.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: p.surfaceAlt,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          notification.targetRole,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: p.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (!notification.isRead)
            IconButton(
              onPressed: onMarkRead,
              icon: const Icon(Icons.check, size: 18),
              tooltip: 'Mark as read',
            ),
        ],
      ),
    );
  }

  (IconData, Color) _typeConfig(AppPalette p, String type) {
    switch (type.toLowerCase()) {
      case 'payment':
      case 'rent':
        return (Icons.check_circle_outline, p.success);
      case 'maintenance':
        return (Icons.report_problem_outlined, p.warning);
      case 'warning':
      case 'alert':
        return (Icons.warning_amber_outlined, p.warning);
      case 'error':
      case 'critical':
        return (Icons.cancel_outlined, p.danger);
      default:
        return (Icons.info_outline, p.primary);
    }
  }
}

class _SendTab extends StatefulWidget {
  const _SendTab();

  @override
  State<_SendTab> createState() => _SendTabState();
}

class _SendTabState extends State<_SendTab> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _targetUserIdController = TextEditingController();
  String _type = 'info';
  String _targetRole = '';
  String _priority = 'normal';
  bool _sending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _targetUserIdController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_titleController.text.trim().isEmpty ||
        _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Title and body are required to send a notification')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final targetUserId = int.tryParse(_targetUserIdController.text.trim());
      await NotificationsService.send({
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'type': _type,
        'targetUserId': ?targetUserId,
        if (_targetRole.isNotEmpty) 'targetRole': _targetRole,
        'priority': _priority,
      });
      if (!mounted) return;
      showSuccessSnack(context, 'Notification sent successfully!');
      _titleController.clear();
      _bodyController.clear();
      _targetUserIdController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.extractError(e))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Title *',
            hintText: 'Rent due',
            prefixIcon: Icon(Icons.title),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bodyController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Message *',
            hintText: 'Write your message...',
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.notes),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _type,
          decoration: const InputDecoration(
            labelText: 'Type',
            prefixIcon: Icon(Icons.label_outline),
          ),
          items: const [
            DropdownMenuItem(value: 'info', child: Text('Info')),
            DropdownMenuItem(value: 'success', child: Text('Success')),
            DropdownMenuItem(value: 'warning', child: Text('Warning')),
            DropdownMenuItem(value: 'error', child: Text('Error')),
            DropdownMenuItem(value: 'payment', child: Text('Payment')),
            DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
          ],
          onChanged: (v) => setState(() => _type = v ?? 'info'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _targetRole,
          decoration: const InputDecoration(
            labelText: 'Target Role',
            prefixIcon: Icon(Icons.groups_outlined),
          ),
          items: const [
            DropdownMenuItem(value: '', child: Text('All Roles')),
            DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
            DropdownMenuItem(value: 'MANAGER', child: Text('Manager')),
            DropdownMenuItem(value: 'STAFF', child: Text('Staff')),
            DropdownMenuItem(value: 'TENANT', child: Text('Tenant')),
          ],
          onChanged: (v) => setState(() => _targetRole = v ?? ''),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _priority,
          decoration: const InputDecoration(
            labelText: 'Priority',
            prefixIcon: Icon(Icons.priority_high),
          ),
          items: const [
            DropdownMenuItem(value: 'low', child: Text('Low')),
            DropdownMenuItem(value: 'normal', child: Text('Normal')),
            DropdownMenuItem(value: 'high', child: Text('High')),
          ],
          onChanged: (v) => setState(() => _priority = v ?? 'normal'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _targetUserIdController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Target User ID (optional)',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _sending ? null : _send,
          child: _sending
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : const Text('Send Notification'),
        ),
      ],
    );
  }
}

class _NoPermissionTab extends StatelessWidget {
  const _NoPermissionTab();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.lock_outline,
      title: 'No permission',
      subtitle: 'You do not have permission to send notifications.',
    );
  }
}

class _PreferencesTab extends StatelessWidget {
  final NotificationPreferences? prefs;
  final bool loading;
  final void Function(String key, bool value) onToggle;
  const _PreferencesTab({
    required this.prefs,
    required this.loading,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && prefs == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (prefs == null) {
      return const EmptyState(
        icon: Icons.settings_outlined,
        title: 'Unable to load preferences',
      );
    }
    final p = prefs!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _toggleRow(
          context,
          icon: Icons.mail_outline,
          title: 'Email Notifications',
          value: p.emailEnabled,
          onChanged: (v) => onToggle('emailEnabled', v),
        ),
        _toggleRow(
          context,
          icon: Icons.notifications_active_outlined,
          title: 'Push Notifications',
          value: p.pushEnabled,
          onChanged: (v) => onToggle('pushEnabled', v),
        ),
        _toggleRow(
          context,
          icon: Icons.sms_outlined,
          title: 'SMS Notifications',
          value: p.smsEnabled,
          onChanged: (v) => onToggle('smsEnabled', v),
        ),
        _toggleRow(
          context,
          icon: Icons.language_outlined,
          title: 'Web Notifications',
          value: p.webEnabled,
          onChanged: (v) => onToggle('webEnabled', v),
        ),
      ],
    );
  }

  Widget _toggleRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: p.primary),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: p.textPrimary,
          ),
        ),
      ),
    );
  }
}
