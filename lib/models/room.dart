class Room {
  final int id;
  final String roomNumber;
  final String roomType;
  final double rentAmount;
  final String status;
  final String facilities;
  final String createdAt;

  Room({
    required this.id,
    required this.roomNumber,
    required this.roomType,
    required this.rentAmount,
    required this.status,
    required this.facilities,
    required this.createdAt,
  });

  factory Room.fromJson(Map<String, dynamic> json) => Room(
        id: (json['id'] as num?)?.toInt() ?? 0,
        roomNumber: json['roomNumber']?.toString() ?? '',
        roomType: json['roomType']?.toString() ?? 'SINGLE',
        rentAmount: (json['rentAmount'] as num?)?.toDouble() ?? 0,
        status: json['status']?.toString() ?? 'AVAILABLE',
        facilities: json['facilities']?.toString() ?? '',
        createdAt: json['createdAt']?.toString() ?? '',
      );

  Map<String, dynamic> toPayload({
    String? roomNumber,
    String? roomType,
    double? rentAmount,
    String? status,
    String? facilities,
  }) => {
        'roomNumber': roomNumber ?? this.roomNumber,
        'roomType': roomType ?? this.roomType,
        'rentAmount': rentAmount ?? this.rentAmount,
        'status': status ?? this.status,
        if ((facilities ?? this.facilities).isNotEmpty)
          'facilities': facilities ?? this.facilities,
      };
}

const roomTypes = ['SINGLE', 'DOUBLE', 'SHARED'];
const roomStatuses = ['AVAILABLE', 'OCCUPIED', 'MAINTENANCE'];
