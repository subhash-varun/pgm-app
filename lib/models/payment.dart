class Payment {
  final int id;
  final int tenantId;
  final String tenantName;
  final double amount;
  final String paymentDate;
  final String paymentMonth;
  final String paymentMethod;
  final String? receiptNumber;
  final String status;
  final String createdAt;
  final String? roomNumber;
  final String? dueDate;

  Payment({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.amount,
    required this.paymentDate,
    required this.paymentMonth,
    required this.paymentMethod,
    this.receiptNumber,
    required this.status,
    required this.createdAt,
    this.roomNumber,
    this.dueDate,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: (json['id'] as num?)?.toInt() ?? 0,
        tenantId: (json['tenantId'] as num?)?.toInt() ?? 0,
        tenantName: json['tenantName']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        paymentDate: json['paymentDate']?.toString() ?? '',
        paymentMonth: json['paymentMonth']?.toString() ?? '',
        paymentMethod: json['paymentMethod']?.toString() ?? '',
        receiptNumber: json['receiptNumber']?.toString(),
        status: json['status']?.toString() ?? 'PENDING',
        createdAt: json['createdAt']?.toString() ?? '',
        roomNumber: json['roomNumber']?.toString(),
        dueDate: json['dueDate']?.toString(),
      );

  bool get isPaid => status == 'PAID';

  Map<String, dynamic> toMarkPaidPayload() => {
        'id': id,
        'tenantId': tenantId,
        'tenantName': tenantName,
        'amount': amount,
        'paymentDate': DateTime.now().toIso8601String(),
        'paymentMonth': paymentMonth,
        'paymentMethod': paymentMethod,
        'receiptNumber': receiptNumber,
        'status': 'PAID',
        'createdAt': createdAt,
        if (roomNumber != null) 'roomNumber': roomNumber,
      };
}

const paymentStatuses = ['PAID', 'PENDING', 'OVERDUE'];
const paymentMethods = ['CASH', 'UPI', 'BANK_TRANSFER', 'CARD'];

class PaymentSummary {
  final double totalCollected;
  final double totalPending;
  final double totalOverdue;
  final List<MonthlyRevenue> monthlyRevenue;

  PaymentSummary({
    required this.totalCollected,
    required this.totalPending,
    required this.totalOverdue,
    required this.monthlyRevenue,
  });

  factory PaymentSummary.compute(List<Payment> payments) {
    double sumBy(String status) => payments
        .where((p) => p.status == status)
        .fold(0.0, (s, p) => s + p.amount);

    final monthly = <String, double>{};
    for (final p in payments.where((p) => p.isPaid)) {
      final month = p.paymentMonth.isNotEmpty
          ? p.paymentMonth
          : (p.paymentDate.length >= 7 ? p.paymentDate.substring(0, 7) : p.paymentDate);
      monthly[month] = (monthly[month] ?? 0) + p.amount;
    }
    final entries = monthly.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final last6 = entries.length > 6 ? entries.sublist(entries.length - 6) : entries;

    return PaymentSummary(
      totalCollected: sumBy('PAID'),
      totalPending: sumBy('PENDING'),
      totalOverdue: sumBy('OVERDUE'),
      monthlyRevenue: last6
          .map((e) => MonthlyRevenue(month: e.key, amount: e.value))
          .toList(),
    );
  }
}

class MonthlyRevenue {
  final String month;
  final double amount;
  MonthlyRevenue({required this.month, required this.amount});
}

class PageData<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int pageNumber;
  final int pageSize;
  final bool first;
  final bool last;

  PageData({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.pageNumber,
    required this.pageSize,
    required this.first,
    required this.last,
  });

  factory PageData.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parse,
  ) {
    final content = (json['content'] as List<dynamic>? ?? [])
        .map((e) => parse(Map<String, dynamic>.from(e as Map)))
        .toList();
    return PageData(
      content: content,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      pageNumber: (json['number'] as num?)?.toInt() ?? 0,
      pageSize: (json['size'] as num?)?.toInt() ?? 10,
      first: json['first'] as bool? ?? true,
      last: json['last'] as bool? ?? true,
    );
  }
}
