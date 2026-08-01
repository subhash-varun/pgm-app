import 'payment.dart';

class DashboardSummary {
  final Occupancy occupancy;
  final TenantStats tenants;
  final Revenue revenue;
  final PaymentStats payments;
  final MaintenanceStats maintenance;
  final List<RecentActivity> recentActivities;
  final List<MonthlyRevenue> revenueChart;

  DashboardSummary({
    required this.occupancy,
    required this.tenants,
    required this.revenue,
    required this.payments,
    required this.maintenance,
    required this.recentActivities,
    required this.revenueChart,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final occupancyJson = (json['occupancy'] as Map?) ?? {};
    final tenantsJson = (json['tenants'] as Map?) ?? {};
    final revenueJson = (json['revenue'] as Map?) ?? {};
    final paymentsJson = (json['payments'] as Map?) ?? {};
    final maintenanceJson = (json['maintenance'] as Map?) ?? {};

    return DashboardSummary(
      occupancy: Occupancy(
        totalRooms: (occupancyJson['totalRooms'] as num?)?.toInt() ?? 0,
        occupiedRooms: (occupancyJson['occupiedRooms'] as num?)?.toInt() ?? 0,
        availableRooms: (occupancyJson['availableRooms'] as num?)?.toInt() ?? 0,
        maintenanceRooms: (occupancyJson['maintenanceRooms'] as num?)?.toInt() ?? 0,
      ),
      tenants: TenantStats(
        total: (tenantsJson['total'] as num?)?.toInt() ?? 0,
        newThisMonth: (tenantsJson['newThisMonth'] as num?)?.toInt() ?? 0,
        checkoutsThisMonth: (tenantsJson['checkoutsThisMonth'] as num?)?.toInt() ?? 0,
      ),
      revenue: Revenue(
        rentCollected: (revenueJson['rentCollected'] as num?)?.toDouble() ?? 0,
        pendingRent: (revenueJson['pendingRent'] as num?)?.toDouble() ?? 0,
        deposits: (revenueJson['deposits'] as num?)?.toDouble() ?? 0,
        expectedMonthlyRevenue:
            (revenueJson['expectedMonthlyRevenue'] as num?)?.toDouble() ?? 0,
      ),
      payments: PaymentStats(
        onTime: (paymentsJson['onTime'] as num?)?.toInt() ?? 0,
        late: (paymentsJson['late'] as num?)?.toInt() ?? 0,
        averageDelayDays: (paymentsJson['averageDelayDays'] as num?)?.toDouble() ?? 0,
      ),
      maintenance: MaintenanceStats(
        totalRequests: (maintenanceJson['totalRequests'] as num?)?.toInt() ?? 0,
        pending: (maintenanceJson['pending'] as num?)?.toInt() ?? 0,
        resolved: (maintenanceJson['resolved'] as num?)?.toInt() ?? 0,
      ),
      recentActivities: (json['recentActivities'] as List<dynamic>? ?? [])
          .map((e) => RecentActivity.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      revenueChart: (json['revenueChart'] as List<dynamic>? ?? [])
          .map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            return MonthlyRevenue(
              month: m['month']?.toString() ?? '',
              amount: (m['amount'] as num?)?.toDouble() ?? 0,
            );
          })
          .toList(),
    );
  }
}

class Occupancy {
  final int totalRooms;
  final int occupiedRooms;
  final int availableRooms;
  final int maintenanceRooms;
  Occupancy({
    required this.totalRooms,
    required this.occupiedRooms,
    required this.availableRooms,
    required this.maintenanceRooms,
  });
}

class TenantStats {
  final int total;
  final int newThisMonth;
  final int checkoutsThisMonth;
  TenantStats({
    required this.total,
    required this.newThisMonth,
    required this.checkoutsThisMonth,
  });
}

class Revenue {
  final double rentCollected;
  final double pendingRent;
  final double deposits;
  final double expectedMonthlyRevenue;
  Revenue({
    required this.rentCollected,
    required this.pendingRent,
    required this.deposits,
    required this.expectedMonthlyRevenue,
  });
}

class PaymentStats {
  final int onTime;
  final int late;
  final double averageDelayDays;
  PaymentStats({
    required this.onTime,
    required this.late,
    required this.averageDelayDays,
  });
}

class MaintenanceStats {
  final int totalRequests;
  final int pending;
  final int resolved;
  MaintenanceStats({
    required this.totalRequests,
    required this.pending,
    required this.resolved,
  });
}

class RecentActivity {
  final String type;
  final String tenant;
  final double amount;
  final String room;
  final String date;
  final String? status;

  RecentActivity({
    required this.type,
    required this.tenant,
    required this.amount,
    required this.room,
    required this.date,
    this.status,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) => RecentActivity(
        type: json['type']?.toString() ?? '',
        tenant: json['tenant']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        room: json['room']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        status: json['status']?.toString(),
      );
}
