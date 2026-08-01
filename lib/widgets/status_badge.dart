import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final IconData? icon;
  const StatusBadge({super.key, required this.status, this.icon});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            capitalize(status),
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(BuildContext context, String status) {
    final p = context.palette;
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
      case 'ACTIVE':
      case 'PAID':
      case 'GOOD':
      case 'RESOLVED':
      case 'LOW':
      case 'ON_TIME':
      case 'ON-TIME':
        return p.success;
      case 'OCCUPIED':
      case 'OVERDUE':
      case 'IN_PROGRESS':
      case 'HIGH':
        return p.danger;
      case 'MAINTENANCE':
      case 'PENDING':
      case 'NEEDS_REPAIR':
      case 'OPEN':
      case 'MEDIUM':
      case 'INACTIVE':
      case 'REPLACED':
      case 'MOVED_OUT':
      case 'LATE':
        return p.warning;
      case 'SINGLE':
        return p.primary;
      case 'DOUBLE':
        return p.purple;
      case 'SHARED':
        return p.info;
      default:
        return p.textSecondary;
    }
  }
}
