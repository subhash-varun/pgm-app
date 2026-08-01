class RentLedger {
  final int id;
  final int tenantId;
  final String tenantName;
  final String roomNumber;
  final String billingMonth;
  final double baseRent;
  final double utilityCharges;
  final double lateFee;
  final double totalAmount;
  final double paidAmount;
  final double balanceDue;
  final double advanceBalance;
  final String dueDate;
  final String status;
  final String createdAt;

  RentLedger({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.roomNumber,
    required this.billingMonth,
    required this.baseRent,
    required this.utilityCharges,
    required this.lateFee,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceDue,
    required this.advanceBalance,
    required this.dueDate,
    required this.status,
    required this.createdAt,
  });

  factory RentLedger.fromJson(Map<String, dynamic> json) => RentLedger(
        id: (json['id'] as num?)?.toInt() ?? 0,
        tenantId: (json['tenantId'] as num?)?.toInt() ?? 0,
        tenantName: json['tenantName']?.toString() ?? '',
        roomNumber: json['roomNumber']?.toString() ?? 'N/A',
        billingMonth: json['billingMonth']?.toString() ?? '',
        baseRent: (json['baseRent'] as num?)?.toDouble() ?? 0,
        utilityCharges: (json['utilityCharges'] as num?)?.toDouble() ?? 0,
        lateFee: (json['lateFee'] as num?)?.toDouble() ?? 0,
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
        paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
        balanceDue: (json['balanceDue'] as num?)?.toDouble() ?? 0,
        advanceBalance: (json['advanceBalance'] as num?)?.toDouble() ?? 0,
        dueDate: json['dueDate']?.toString() ?? '',
        status: json['status']?.toString() ?? 'UNPAID',
        createdAt: json['createdAt']?.toString() ?? '',
      );

  bool get isPaid => status == 'PAID';
  bool get isPartial => status == 'PARTIAL';
  bool get isOverdue => status == 'OVERDUE';
}

class RentLedgerSummary {
  final String billingMonth;
  final double totalBilled;
  final double totalCollected;
  final double totalPending;
  final int totalOverdueCount;
  final int totalTenantsCount;

  RentLedgerSummary({
    required this.billingMonth,
    required this.totalBilled,
    required this.totalCollected,
    required this.totalPending,
    required this.totalOverdueCount,
    required this.totalTenantsCount,
  });

  factory RentLedgerSummary.fromJson(Map<String, dynamic> json) =>
      RentLedgerSummary(
        billingMonth: json['billingMonth']?.toString() ?? '',
        totalBilled: (json['totalBilled'] as num?)?.toDouble() ?? 0,
        totalCollected: (json['totalCollected'] as num?)?.toDouble() ?? 0,
        totalPending: (json['totalPending'] as num?)?.toDouble() ?? 0,
        totalOverdueCount: (json['totalOverdueCount'] as num?)?.toInt() ?? 0,
        totalTenantsCount: (json['totalTenantsCount'] as num?)?.toInt() ?? 0,
      );
}
