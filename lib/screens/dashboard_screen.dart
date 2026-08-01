import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/dashboard.dart';
import '../models/payment.dart';
import '../services/api_services.dart';
import '../widgets/common.dart';
import '../widgets/status_badge.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardSummary? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await DashboardService.getSummary();
      if (!mounted) return;
      setState(() => _summary = summary);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ApiClient.extractError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.scaffold,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: p.surfaceAlt,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              formatDateShort(),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: p.textSecondary,
              ),
            ),
          ),
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _summary == null) {
      return ListView(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _Shimmer(width: 200, height: 18),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LoadingList(),
        ],
      );
    }
    if (_error != null && _summary == null) {
      return ListView(
        children: [
          ErrorRetry(message: _error!, onRetry: _load),
        ],
      );
    }
    final s = _summary!;
    final occupancyRate = s.occupancy.totalRooms > 0
        ? (s.occupancy.occupiedRooms / s.occupancy.totalRooms) * 100
        : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _KpiCard(
              width: _kpiWidth(),
              label: 'Total Tenants',
              value: formatNumber(s.tenants.total),
              icon: Icons.people,
              color: context.palette.primary,
              footer: '+${formatNumber(s.tenants.newThisMonth)} this month',
              footerColor: context.palette.success,
            ),
            _KpiCard(
              width: _kpiWidth(),
              label: 'Occupancy Rate',
              value: formatPercent(occupancyRate),
              icon: Icons.apartment,
              color: context.palette.success,
              footer:
                  '${s.occupancy.occupiedRooms} occupied / ${s.occupancy.totalRooms} total',
              footerColor: context.palette.textSecondary,
              progress: (occupancyRate / 100).clamp(0.0, 1.0),
            ),
            _KpiCard(
              width: _kpiWidth(),
              label: 'Revenue',
              value: formatCurrency(s.revenue.rentCollected),
              icon: Icons.currency_rupee,
              color: context.palette.purple,
              footer: '${formatCurrency(s.revenue.pendingRent)} pending',
              footerColor: context.palette.warning,
            ),
            _KpiCard(
              width: _kpiWidth(),
              label: 'Maintenance',
              value: formatNumber(s.maintenance.pending),
              icon: Icons.report_problem_outlined,
              color: context.palette.warning,
              footer: '${formatNumber(s.maintenance.totalRequests)} total requests',
              footerColor: context.palette.textSecondary,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (s.revenueChart.isNotEmpty) ...[
          _RevenueChartCard(data: s.revenueChart),
          const SizedBox(height: 16),
        ],
        _RoomStatusCard(occupancy: s.occupancy),
        const SizedBox(height: 16),
        _PaymentPerformanceCard(
          payments: s.payments,
          totalTenants: s.tenants.total,
        ),
        const SizedBox(height: 16),
        _FinancialSummaryCard(revenue: s.revenue),
        if (s.recentActivities.isNotEmpty) ...[
          const SizedBox(height: 16),
          _RecentActivitiesCard(activities: s.recentActivities),
        ],
      ],
    );
  }

  double _kpiWidth() {
    final w = MediaQuery.of(context).size.width - 32;
    return (w - 12) / 2;
  }
}

String formatDateShort() {
  final now = DateTime.now();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  const days = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];
  return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
}

class _Shimmer extends StatelessWidget {
  final double width;
  final double height;
  const _Shimmer({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.palette.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String footer;
  final Color footerColor;
  final double? progress;
  const _KpiCard({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.footer,
    required this.footerColor,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: width,
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
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.textSecondary,
                  ),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: p.textPrimary,
              height: 1.1,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: p.surfaceAlt,
                color: color,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            footer,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: footerColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueChartCard extends StatelessWidget {
  final List<MonthlyRevenue> data;
  const _RevenueChartCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.trending_up,
            color: p.primary,
            title: 'Revenue Trend',
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: p.border,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (value, meta) {
                        final v = value.toInt();
                        return Text(
                          '₹${(v / 1000).round()}k',
                          style: TextStyle(fontSize: 11, color: p.textTertiary),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= data.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            formatMonthLabel(data[idx].month),
                            style: TextStyle(
                              fontSize: 11,
                              color: p.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < data.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: data[i].amount,
                          color: p.primary,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomStatusCard extends StatelessWidget {
  final Occupancy occupancy;
  const _RoomStatusCard({required this.occupancy});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.apartment,
            color: p.success,
            title: 'Room Status Overview',
          ),
          const SizedBox(height: 14),
          _statusRow(
            p: p,
            color: p.success,
            label: 'Available',
            value: occupancy.availableRooms,
          ),
          const SizedBox(height: 8),
          _statusRow(
            p: p,
            color: p.primary,
            label: 'Occupied',
            value: occupancy.occupiedRooms,
          ),
          const SizedBox(height: 8),
          _statusRow(
            p: p,
            color: p.warning,
            label: 'Maintenance',
            value: occupancy.maintenanceRooms,
          ),
        ],
      ),
    );
  }

  Widget _statusRow({
    required AppPalette p,
    required Color color,
    required String label,
    required int value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
            ),
          ),
          Text(
            formatNumber(value),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentPerformanceCard extends StatelessWidget {
  final PaymentStats payments;
  final int totalTenants;
  const _PaymentPerformanceCard({
    required this.payments,
    required this.totalTenants,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final onTimeRate = totalTenants > 0
        ? (payments.onTime / totalTenants) * 100
        : 0.0;
    final lateRate =
        totalTenants > 0 ? (payments.late / totalTenants) * 100 : 0.0;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.receipt_long,
            color: p.primary,
            title: 'Payment Performance',
          ),
          const SizedBox(height: 6),
          _metricRow(
            p: p,
            icon: Icons.check_circle_outline,
            iconColor: p.success,
            label: 'On Time',
            value: formatNumber(payments.onTime),
            rate: formatPercent(onTimeRate),
            rateColor: p.success,
          ),
          _metricRow(
            p: p,
            icon: Icons.schedule,
            iconColor: p.warning,
            label: 'Late',
            value: formatNumber(payments.late),
            rate: formatPercent(lateRate),
            rateColor: p.warning,
          ),
          _metricRow(
            p: p,
            icon: Icons.error_outline,
            iconColor: p.textSecondary,
            label: 'Avg Delay',
            value: '${formatNumber(payments.averageDelayDays)} days',
            rate: null,
            rateColor: p.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _metricRow({
    required AppPalette p,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? rate,
    required Color rateColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
          if (rate != null) ...[
            const SizedBox(width: 8),
            StatusBadge(status: rate),
          ],
        ],
      ),
    );
  }
}

class _FinancialSummaryCard extends StatelessWidget {
  final Revenue revenue;
  const _FinancialSummaryCard({required this.revenue});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.currency_rupee,
            color: p.purple,
            title: 'Financial Summary',
          ),
          const SizedBox(height: 6),
          _finRow(
            p: p,
            color: p.primary,
            label: 'Rent Collected',
            value: formatCurrency(revenue.rentCollected),
          ),
          _finRow(
            p: p,
            color: p.purple,
            label: 'Security Deposits',
            value: formatCurrency(revenue.deposits),
          ),
          _finRow(
            p: p,
            color: p.warning,
            label: 'Pending Rent',
            value: formatCurrency(revenue.pendingRent),
          ),
          _finRow(
            p: p,
            color: p.textSecondary,
            label: 'Expected Monthly',
            value: formatCurrency(revenue.expectedMonthlyRevenue),
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _finRow({
    required AppPalette p,
    required Color color,
    required String label,
    required String value,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: p.textPrimary,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
              color: bold ? p.textPrimary : p.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivitiesCard extends StatelessWidget {
  final List<RecentActivity> activities;
  const _RecentActivitiesCard({required this.activities});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.bolt,
            color: p.indigo,
            title: 'Recent Activities',
          ),
          const SizedBox(height: 6),
          for (final a in activities.take(8)) _activityRow(p, a),
        ],
      ),
    );
  }

  Widget _activityRow(AppPalette p, RecentActivity a) {
    final config = _activityConfig(p, a.type);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: config.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(config.icon, size: 20, color: config.color),
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
                        a.tenant.isEmpty ? 'Unknown Tenant' : a.tenant,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: p.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      config.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: config.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (a.room.isNotEmpty) ...[
                      Icon(Icons.meeting_room_outlined,
                          size: 13, color: p.textTertiary),
                      const SizedBox(width: 3),
                      Text(
                        'Room ${a.room}',
                        style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Icon(Icons.calendar_today_outlined,
                        size: 12, color: p.textTertiary),
                    const SizedBox(width: 3),
                    Text(
                      relativeActivityDate(a.date),
                      style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCurrency(a.amount),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: p.success,
                ),
              ),
              if (a.status != null)
                Text(
                  a.status!,
                  style: TextStyle(fontSize: 12, color: p.textTertiary),
                ),
            ],
          ),
        ],
      ),
    );
  }

  ({IconData icon, Color color, String label}) _activityConfig(
      AppPalette p, String type) {
    switch (type.toLowerCase()) {
      case 'payment':
      case 'rent':
        return (
          icon: Icons.receipt_long,
          color: p.success,
          label: 'Payment',
        );
      case 'check-in':
      case 'checkin':
        return (
          icon: Icons.login,
          color: p.primary,
          label: 'Check-in',
        );
      case 'check-out':
      case 'checkout':
        return (
          icon: Icons.logout,
          color: p.warning,
          label: 'Check-out',
        );
      case 'maintenance':
        return (
          icon: Icons.report_problem_outlined,
          color: p.warning,
          label: 'Maintenance',
        );
      default:
        return (
          icon: Icons.bolt,
          color: p.indigo,
          label: 'Activity',
        );
    }
  }
}
