class InventoryItem {
  final int id;
  final int roomId;
  final String roomNumber;
  final String itemName;
  final int quantity;
  final String conditionStatus;
  final String lastUpdated;

  InventoryItem({
    required this.id,
    required this.roomId,
    required this.roomNumber,
    required this.itemName,
    required this.quantity,
    required this.conditionStatus,
    required this.lastUpdated,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        id: (json['id'] as num?)?.toInt() ?? 0,
        roomId: (json['roomId'] as num?)?.toInt() ?? 0,
        roomNumber: json['roomNumber']?.toString() ?? '',
        itemName: json['itemName']?.toString() ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        conditionStatus: json['conditionStatus']?.toString() ?? 'GOOD',
        lastUpdated: json['lastUpdated']?.toString() ?? '',
      );

  bool get isLowStock => quantity < 5;

  Map<String, dynamic> toPayload({
    int? roomId,
    String? itemName,
    int? quantity,
    String? conditionStatus,
  }) => {
        'roomId': roomId ?? this.roomId,
        'itemName': itemName ?? this.itemName,
        'quantity': quantity ?? this.quantity,
        'conditionStatus': conditionStatus ?? this.conditionStatus,
      };
}

const inventoryConditions = ['GOOD', 'NEEDS_REPAIR', 'REPLACED'];
