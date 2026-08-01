class MaintenanceRequest {
  final int id;
  final int tenantId;
  final String tenantName;
  final String roomNumber;
  final String issueTitle;
  final String description;
  final String? imageUrl;
  final String status;
  final String priority;
  final String createdAt;
  final String? resolvedAt;
  final String? assignedTo;

  MaintenanceRequest({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.roomNumber,
    required this.issueTitle,
    required this.description,
    this.imageUrl,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.resolvedAt,
    this.assignedTo,
  });

  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) =>
      MaintenanceRequest(
        id: (json['id'] as num?)?.toInt() ?? 0,
        tenantId: (json['tenantId'] as num?)?.toInt() ?? 0,
        tenantName: json['tenantName']?.toString() ?? '',
        roomNumber: json['roomNumber']?.toString() ?? '',
        issueTitle: json['issueTitle']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        imageUrl: json['imageUrl']?.toString(),
        status: json['status']?.toString() ?? 'OPEN',
        priority: json['priority']?.toString() ?? 'MEDIUM',
        createdAt: json['createdAt']?.toString() ?? '',
        resolvedAt: json['resolvedAt']?.toString(),
        assignedTo: json['assignedTo']?.toString(),
      );
}

const maintenanceStatuses = ['OPEN', 'IN_PROGRESS', 'RESOLVED'];
const maintenancePriorities = ['LOW', 'MEDIUM', 'HIGH'];
const assignableStaff = ['Ramesh', 'Suresh', 'Mahesh'];
