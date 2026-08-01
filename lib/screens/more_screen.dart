import 'package:flutter/material.dart';

import '../core/auth_service.dart';
import '../core/theme.dart';
import 'admin/admins_screen.dart';
import 'auth/login_screen.dart';
import 'inventory/inventory_screen.dart';
import 'inventory/maintenance_screen.dart';
import 'notifications/notifications_screen.dart';
import 'permissions/permissions_screen.dart';
import 'profile_screen.dart';
import 'roles/roles_screen.dart';
import 'staff/staff_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.scaffold,
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _SectionLabel('Property Management'),
          _MenuItem(
            icon: Icons.inventory_2_outlined,
            color: context.palette.primary,
            title: 'Inventory',
            subtitle: 'Manage room items & stock',
            onTap: () => _push(context, const InventoryScreen()),
          ),
          _MenuItem(
            icon: Icons.build_outlined,
            color: context.palette.warning,
            title: 'Maintenance',
            subtitle: 'Track repair requests',
            onTap: () => _push(context, const MaintenanceScreen()),
          ),
          _MenuItem(
            icon: Icons.badge_outlined,
            color: context.palette.purple,
            title: 'Staff',
            subtitle: 'Manage staff members',
            onTap: () => _push(context, const StaffScreen()),
          ),
          const SizedBox(height: 18),
          const _SectionLabel('Administration'),
          _MenuItem(
            icon: Icons.admin_panel_settings_outlined,
            color: context.palette.info,
            title: 'Admins',
            subtitle: 'Manage administrators',
            onTap: () => _push(context, const AdminsScreen()),
          ),
          _MenuItem(
            icon: Icons.admin_panel_settings_outlined,
            color: context.palette.success,
            title: 'Roles & Permissions',
            subtitle: 'Control user access',
            onTap: () => _push(context, const RolesScreen()),
          ),
          _MenuItem(
            icon: Icons.key_outlined,
            color: context.palette.danger,
            title: 'Permission Keys',
            subtitle: 'Define permission keys',
            onTap: () => _push(context, const PermissionsScreen()),
          ),
          const SizedBox(height: 18),
          const _SectionLabel('Account'),
          _MenuItem(
            icon: Icons.notifications_outlined,
            color: context.palette.warning,
            title: 'Notifications',
            subtitle: 'View, send & preferences',
            onTap: () => _push(context, const NotificationsScreen()),
          ),
          _MenuItem(
            icon: Icons.person_outline,
            color: context.palette.primary,
            title: 'Profile',
            subtitle: 'View and edit your profile',
            onTap: () => _push(context, const ProfileScreen()),
          ),
          const SizedBox(height: 18),
          _MenuItem(
            icon: Icons.logout,
            color: context.palette.danger,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await AuthService.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: context.palette.textTertiary,
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: p.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: p.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
