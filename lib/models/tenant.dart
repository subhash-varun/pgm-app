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
  final double depositAmount;
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
    required this.depositAmount,
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
        depositAmount: (json['depositAmount'] as num?)?.toDouble() ?? 0,
        status: json['status']?.toString() ?? 'ACTIVE',
        createdAt: json['createdAt']?.toString() ?? '',
      );

  bool get isActive => status == 'ACTIVE';

  Map<String, dynamic> toCreatePayload({
    int? roomId,
    String? name,
    String? email,
    String? phone,
    String? idProofType,
    String? idProofNumber,
    String? checkInDate,
    double? depositAmount,
  }) => {
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
