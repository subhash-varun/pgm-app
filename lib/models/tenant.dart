class Tenant {
  final int id;
  final int roomId;
  final String roomNumber;
  final String name;
  final String email;
  final String phone;
  final String idProofType;
  final String idProofNumber;
  final String checkInDate;
  final String? checkOutDate;
  final String? noticeDate;
  final String? expectedExitDate;
  final String? actualExitDate;
  final String? exitReason;
  final String? bedNumber;
  final double depositAmount;
  final double advanceBalance;
  final String status;
  final String createdAt;

  Tenant({
    required this.id,
    required this.roomId,
    required this.roomNumber,
    required this.name,
    required this.email,
    required this.phone,
    required this.idProofType,
    required this.idProofNumber,
    required this.checkInDate,
    this.checkOutDate,
    this.noticeDate,
    this.expectedExitDate,
    this.actualExitDate,
    this.exitReason,
    this.bedNumber,
    required this.depositAmount,
    this.advanceBalance = 0,
    required this.status,
    required this.createdAt,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) => Tenant(
        id: (json['id'] as num?)?.toInt() ?? 0,
        roomId: (json['roomId'] as num?)?.toInt() ?? 0,
        roomNumber: json['roomNumber']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        idProofType: json['idProofType']?.toString() ?? '',
        idProofNumber: json['idProofNumber']?.toString() ?? '',
        checkInDate: json['checkInDate']?.toString() ?? '',
        checkOutDate: json['checkOutDate']?.toString(),
        noticeDate: json['noticeDate']?.toString(),
        expectedExitDate: json['expectedExitDate']?.toString(),
        actualExitDate: json['actualExitDate']?.toString(),
        exitReason: json['exitReason']?.toString(),
        bedNumber: json['bedNumber']?.toString(),
        depositAmount: (json['depositAmount'] as num?)?.toDouble() ?? 0,
        advanceBalance: (json['advanceBalance'] as num?)?.toDouble() ?? 0,
        status: json['status']?.toString() ?? 'ACTIVE',
        createdAt: json['createdAt']?.toString() ?? '',
      );

  bool get isActive => status == 'ACTIVE';
  bool get isInNotice => status == 'NOTICE';
  bool get hasMovedOut => status == 'MOVED_OUT';

  Map<String, dynamic> toCreatePayload({
    int? roomId,
    String? name,
    String? email,
    String? phone,
    String? idProofType,
    String? idProofNumber,
    String? checkInDate,
    double? depositAmount,
  }) =>
      {
        'roomId': roomId ?? this.roomId,
        'name': name ?? this.name,
        'email': email ?? this.email,
        'phone': phone ?? this.phone,
        'idProofType': idProofType ?? this.idProofType,
        'idProofNumber': idProofNumber ?? this.idProofNumber,
        'checkInDate': checkInDate ?? this.checkInDate,
        'depositAmount': depositAmount ?? this.depositAmount,
      };
}

class TenantSettlementSummary {
  final int tenantId;
  final String tenantName;
  final String roomNumber;
  final String checkInDate;
  final String? noticeDate;
  final String? expectedExitDate;
  final double securityDepositPaid;
  final double advanceBalance;
  final double outstandingRentDues;
  final int unpaidLedgerCount;
  final double suggestedDamageCharges;
  final double estimatedNetRefund;

  TenantSettlementSummary({
    required this.tenantId,
    required this.tenantName,
    required this.roomNumber,
    required this.checkInDate,
    this.noticeDate,
    this.expectedExitDate,
    required this.securityDepositPaid,
    required this.advanceBalance,
    required this.outstandingRentDues,
    required this.unpaidLedgerCount,
    required this.suggestedDamageCharges,
    required this.estimatedNetRefund,
  });

  factory TenantSettlementSummary.fromJson(Map<String, dynamic> json) => TenantSettlementSummary(
        tenantId: (json['tenantId'] as num?)?.toInt() ?? 0,
        tenantName: json['tenantName']?.toString() ?? '',
        roomNumber: json['roomNumber']?.toString() ?? '',
        checkInDate: json['checkInDate']?.toString() ?? '',
        noticeDate: json['noticeDate']?.toString(),
        expectedExitDate: json['expectedExitDate']?.toString(),
        securityDepositPaid: (json['securityDepositPaid'] as num?)?.toDouble() ?? 0,
        advanceBalance: (json['advanceBalance'] as num?)?.toDouble() ?? 0,
        outstandingRentDues: (json['outstandingRentDues'] as num?)?.toDouble() ?? 0,
        unpaidLedgerCount: (json['unpaidLedgerCount'] as num?)?.toInt() ?? 0,
        suggestedDamageCharges: (json['suggestedDamageCharges'] as num?)?.toDouble() ?? 0,
        estimatedNetRefund: (json['estimatedNetRefund'] as num?)?.toDouble() ?? 0,
      );
}

class TenantSettlementResult {
  final int settlementId;
  final int tenantId;
  final String tenantName;
  final String? noticeDate;
  final String actualExitDate;
  final double securityDepositPaid;
  final double outstandingRentDues;
  final double damageCharges;
  final double otherDeductions;
  final double netRefundAmount;
  final String? paymentMethod;
  final String? remarks;
  final String status;

  TenantSettlementResult({
    required this.settlementId,
    required this.tenantId,
    required this.tenantName,
    this.noticeDate,
    required this.actualExitDate,
    required this.securityDepositPaid,
    required this.outstandingRentDues,
    required this.damageCharges,
    required this.otherDeductions,
    required this.netRefundAmount,
    this.paymentMethod,
    this.remarks,
    required this.status,
  });

  factory TenantSettlementResult.fromJson(Map<String, dynamic> json) => TenantSettlementResult(
        settlementId: (json['settlementId'] as num?)?.toInt() ?? 0,
        tenantId: (json['tenantId'] as num?)?.toInt() ?? 0,
        tenantName: json['tenantName']?.toString() ?? '',
        noticeDate: json['noticeDate']?.toString(),
        actualExitDate: json['actualExitDate']?.toString() ?? '',
        securityDepositPaid: (json['securityDepositPaid'] as num?)?.toDouble() ?? 0,
        outstandingRentDues: (json['outstandingRentDues'] as num?)?.toDouble() ?? 0,
        damageCharges: (json['damageCharges'] as num?)?.toDouble() ?? 0,
        otherDeductions: (json['otherDeductions'] as num?)?.toDouble() ?? 0,
        netRefundAmount: (json['netRefundAmount'] as num?)?.toDouble() ?? 0,
        paymentMethod: json['paymentMethod']?.toString(),
        remarks: json['remarks']?.toString(),
        status: json['status']?.toString() ?? 'SETTLED',
      );
}
