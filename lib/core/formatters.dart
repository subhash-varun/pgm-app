import 'package:intl/intl.dart';

final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final _numberFormat = NumberFormat('#,##,##0', 'en_IN');

String formatCurrency(num? value) {
  if (value == null) return '₹0';
  return _currencyFormat.format(value);
}

String formatNumber(num? value) {
  if (value == null) return '0';
  return _numberFormat.format(value);
}

String formatPercent(num? value) {
  return '${(value ?? 0).toStringAsFixed(1)}%';
}

String formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return 'N/A';
  final parsed = DateTime.tryParse(dateStr);
  if (parsed == null) return dateStr;
  return DateFormat('dd MMM yyyy').format(parsed);
}

String formatDateTime(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return 'N/A';
  final parsed = DateTime.tryParse(dateStr);
  if (parsed == null) return dateStr;
  return DateFormat('MMM d, yyyy, hh:mm a').format(parsed);
}

String formatRelativeTime(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return 'N/A';
  final parsed = DateTime.tryParse(dateStr);
  if (parsed == null) return dateStr;
  final now = DateTime.now();
  final diff = now.difference(parsed);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('dd MMM yyyy').format(parsed);
}

String relativeActivityDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return 'N/A';
  final parsed = DateTime.tryParse(dateStr);
  if (parsed == null) return dateStr;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final thatDay = DateTime(parsed.year, parsed.month, parsed.day);
  final diffDays = today.difference(thatDay).inDays;
  if (diffDays == 0) return 'Today';
  if (diffDays == 1) return 'Yesterday';
  if (diffDays <= 6) return '$diffDays days ago';
  return DateFormat('dd MMM yyyy').format(parsed);
}

String toInitials(String? name) {
  if (name == null || name.isEmpty) return '?';
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
}

String capitalize(String? value) {
  if (value == null || value.isEmpty) return value ?? '';
  return value
      .split('_')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}

String stripRolePrefix(String role) {
  return role.replaceFirst('ROLE_', '');
}

String formatMonthLabel(String month) {
  final parsed = DateTime.tryParse('$month-01');
  if (parsed == null) return month;
  return DateFormat('MMM').format(parsed);
}
