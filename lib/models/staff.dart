class Staff {
  final int id;
  final String name;
  final String email;
  final int adminId;
  final String role;
  final String status;
  final String createdAt;

  Staff({
    required this.id,
    required this.name,
    required this.email,
    required this.adminId,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  factory Staff.fromJson(Map<String, dynamic> json) => Staff(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        adminId: (json['adminId'] as num?)?.toInt() ?? 0,
        role: json['role']?.toString() ?? '',
        status: json['status']?.toString() ?? 'ACTIVE',
        createdAt: json['createdAt']?.toString() ?? '',
      );

  bool get isActive => status == 'ACTIVE';
}

const staffStatuses = ['ACTIVE', 'INACTIVE'];
