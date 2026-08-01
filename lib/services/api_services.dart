import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/app_notification.dart';
import '../models/dashboard.dart';
import '../models/payment.dart';
import '../models/tenant.dart';
import '../models/room.dart';
import '../models/inventory_item.dart';
import '../models/maintenance_request.dart';
import '../models/staff.dart';
import '../models/user.dart';

typedef Json = Map<String, dynamic>;

Json _data(Response res) => (res.data as Map?)?['data'] as Json? ?? {};

PageData<T> _page<T>(Response res, T Function(Json) parse) {
  final raw = res.data is Map ? (res.data as Map)['data'] : null;
  final json = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  return PageData.fromJson(json, parse);
}

PageData<T> _list<T>(Response res, T Function(Json) parse) {
  final raw = res.data is Map ? (res.data as Map)['data'] : null;
  final items = raw is List
      ? raw.map((e) => parse(Map<String, dynamic>.from(e as Map))).toList()
      : <T>[];
  return PageData<T>(
    content: items,
    totalElements: items.length,
    totalPages: 1,
    pageNumber: 0,
    pageSize: items.length,
    first: true,
    last: true,
  );
}

class DashboardService {
  static Future<DashboardSummary> getSummary() async {
    final res = await ApiClient.dio.get<dynamic>('/api/admin/dashboard/summary');
    return DashboardSummary.fromJson(_data(res));
  }
}

class TenantsService {
  static Future<PageData<Tenant>> list({
    String? search,
    String? status,
    int page = 0,
    int size = 10,
  }) async {
    final res = await ApiClient.dio.get<dynamic>(
      status != null && status.isNotEmpty
          ? '/api/admin/tenants/status/$status'
          : '/api/admin/tenants',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'size': size,
      },
    );
    return _page(res, Tenant.fromJson);
  }

  static Future<Tenant> getById(int id) async {
    final res = await ApiClient.dio.get<dynamic>('/api/admin/tenants/$id');
    return Tenant.fromJson(_data(res));
  }

  static Future<void> create(Json payload) async {
    await ApiClient.dio.post<dynamic>('/api/admin/tenants', data: payload);
  }

  static Future<void> update(int id, Json payload) async {
    await ApiClient.dio.put<dynamic>('/api/admin/tenants/$id', data: payload);
  }

  static Future<void> delete(int id) async {
    await ApiClient.dio.delete<dynamic>('/api/admin/tenants/$id');
  }
}

class RoomsService {
  static Future<PageData<Room>> list({
    String? type,
    String? status,
    double? minRent,
    double? maxRent,
    int page = 0,
    int size = 10,
  }) async {
    final hasStatus = status != null && status.isNotEmpty;
    final hasType = type != null && type.isNotEmpty;
    if (hasStatus || hasType) {
      final path = hasStatus
          ? '/api/admin/rooms/status/$status'
          : '/api/admin/rooms/type/$type';
      final res = await ApiClient.dio.get<dynamic>(path);
      return _list(res, Room.fromJson);
    }
    final res = await ApiClient.dio.get<dynamic>(
      '/api/admin/rooms',
      queryParameters: {
        'minRent': ?minRent,
        'maxRent': ?maxRent,
        'page': page,
        'size': size,
      },
    );
    return _page(res, Room.fromJson);
  }

  static Future<Room> getById(int id) async {
    final res = await ApiClient.dio.get<dynamic>('/api/admin/rooms/$id');
    return Room.fromJson(_data(res));
  }

  static Future<void> create(Json payload) async {
    await ApiClient.dio.post<dynamic>('/api/admin/rooms', data: payload);
  }

  static Future<void> update(int id, Json payload) async {
    await ApiClient.dio.put<dynamic>('/api/admin/rooms/$id', data: payload);
  }

  static Future<void> delete(int id) async {
    await ApiClient.dio.delete<dynamic>('/api/admin/rooms/$id');
  }
}

class PaymentsService {
  static Future<PageData<Payment>> list({
    String? status,
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    final hasStatus = status != null && status.isNotEmpty && status != 'ALL';
    final effectiveStatus = status == 'OVERDUE' ? 'PENDING' : status;
    final res = await ApiClient.dio.get<dynamic>(
      hasStatus
          ? '/api/admin/payments/status/$effectiveStatus'
          : '/api/admin/payments',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'size': size,
      },
    );
    return _page(res, Payment.fromJson);
  }

  static Future<void> markAsPaid(Payment payment) async {
    await ApiClient.dio.put<dynamic>(
      '/api/admin/payments/${payment.id}',
      data: payment.toMarkPaidPayload(),
    );
  }

  static Future<void> delete(int id) async {
    await ApiClient.dio.delete<dynamic>('/api/admin/payments/$id');
  }
}

class InventoryService {
  static Future<PageData<InventoryItem>> list({
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    final res = await ApiClient.dio.get<dynamic>(
      '/api/admin/inventory',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'size': size,
      },
    );
    return _page(res, InventoryItem.fromJson);
  }

  static Future<void> create(Json payload) async {
    await ApiClient.dio.post<dynamic>('/api/admin/inventory', data: payload);
  }

  static Future<void> update(int id, Json payload) async {
    await ApiClient.dio.put<dynamic>('/api/admin/inventory/$id', data: payload);
  }

  static Future<void> delete(int id) async {
    await ApiClient.dio.delete<dynamic>('/api/admin/inventory/$id');
  }
}

class MaintenanceService {
  static Future<PageData<MaintenanceRequest>> list({
    String? status,
    String? priority,
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    final res = await ApiClient.dio.get<dynamic>(
      '/api/admin/maintenance',
      queryParameters: {
        if (status != null && status.isNotEmpty && status != 'ALL') 'status': status,
        if (priority != null && priority.isNotEmpty && priority != 'ALL')
          'priority': priority,
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'size': size,
      },
    );
    return _page(res, MaintenanceRequest.fromJson);
  }

  static Future<void> updateStatus(int id, String status) async {
    await ApiClient.dio.patch<dynamic>(
      '/api/admin/maintenance/$id/status',
      data: {'status': status},
    );
  }

  static Future<void> assignStaff(int id, String staffName) async {
    await ApiClient.dio.patch<dynamic>(
      '/api/admin/maintenance/$id/assign',
      data: {'assignedTo': staffName},
    );
  }
}

class StaffService {
  static Future<PageData<Staff>> list({int page = 0, int size = 10}) async {
    final res = await ApiClient.dio.get<dynamic>(
      '/api/admin/staff',
      queryParameters: {'page': page, 'size': size},
    );
    return _page(res, Staff.fromJson);
  }

  static Future<void> create(Json payload) async {
    await ApiClient.dio.post<dynamic>('/api/admin/staff', data: payload);
  }

  static Future<void> update(int id, Json payload) async {
    await ApiClient.dio.put<dynamic>('/api/admin/staff/$id', data: payload);
  }

  static Future<void> delete(int id) async {
    await ApiClient.dio.delete<dynamic>('/api/admin/staff/$id');
  }
}

class RolesService {
  static Future<PageData<Role>> list({int page = 0, int size = 10}) async {
    final res = await ApiClient.dio.get<dynamic>(
      '/api/admin/roles',
      queryParameters: {'page': page, 'size': size},
    );
    return _page(res, Role.fromJson);
  }

  static Future<List<Permission>> permissionsFor(int roleId) async {
    final res = await ApiClient.dio
        .get<dynamic>('/api/admin/roles/$roleId/permissions');
    final data = _data(res);
    final list = data['permissions'] as List<dynamic>? ?? [];
    return list
        .map((e) => Permission.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<void> create(Json payload) async {
    await ApiClient.dio.post<dynamic>('/api/admin/roles', data: payload);
  }

  static Future<void> update(int id, Json payload) async {
    await ApiClient.dio.put<dynamic>('/api/admin/roles/$id', data: payload);
  }

  static Future<void> delete(int id) async {
    await ApiClient.dio.delete<dynamic>('/api/admin/roles/$id');
  }

  static Future<void> assignPermissions(int roleId, List<int> permissionIds) async {
    await ApiClient.dio.post<dynamic>(
      '/api/admin/roles/$roleId/permissions',
      data: {'permissionIds': permissionIds},
    );
  }
}

class PermissionsService {
  static Future<PageData<Permission>> list({int page = 0, int size = 12}) async {
    final res = await ApiClient.dio.get<dynamic>(
      '/api/admin/permissions',
      queryParameters: {'page': page, 'size': size},
    );
    return _page(res, Permission.fromJson);
  }

  static Future<void> create(Json payload) async {
    await ApiClient.dio.post<dynamic>('/api/admin/permissions', data: payload);
  }

  static Future<void> update(int id, Json payload) async {
    await ApiClient.dio.put<dynamic>('/api/admin/permissions/$id', data: payload);
  }

  static Future<void> delete(int id) async {
    await ApiClient.dio.delete<dynamic>('/api/admin/permissions/$id');
  }
}

class AdminsService {
  static Future<PageData<Admin>> list({int page = 0, int size = 12}) async {
    final res = await ApiClient.dio.get<dynamic>(
      '/api/admin',
      queryParameters: {'page': page, 'size': size},
    );
    return _page(res, Admin.fromJson);
  }

  static Future<void> create(Json payload) async {
    await ApiClient.dio.post<dynamic>('/api/admin', data: payload);
  }

  static Future<void> update(int id, Json payload) async {
    await ApiClient.dio.put<dynamic>('/api/admin/$id', data: payload);
  }

  static Future<void> delete(int id) async {
    await ApiClient.dio.delete<dynamic>('/api/admin/$id');
  }
}

class NotificationsService {
  static Future<NotificationList> list({int page = 0, int size = 20}) async {
    final res = await ApiClient.dio.get<dynamic>(
      '/api/notifications',
      queryParameters: {'page': page, 'size': size},
    );
    final data = res.data is Map ? (res.data as Map)['data'] : null;
    final json = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    final list = (json['notifications'] as List<dynamic>? ?? [])
        .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return NotificationList(
      notifications: list,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      hasNext: json['hasNext'] as bool? ?? false,
    );
  }

  static Future<int> unreadCount() async {
    final res = await ApiClient.dio.get<dynamic>('/api/notifications/unread-count');
    final data = res.data is Map ? (res.data as Map)['data'] : null;
    if (data is num) return data.toInt();
    return 0;
  }

  static Future<void> markRead(int id) async {
    await ApiClient.dio.patch<dynamic>('/api/notifications/$id/read');
  }

  static Future<void> markAllRead() async {
    await ApiClient.dio.patch<dynamic>('/api/notifications/mark-all-read');
  }

  static Future<void> send(Json payload) async {
    await ApiClient.dio.post<dynamic>('/api/notifications/send', data: payload);
  }

  static Future<NotificationPreferences> getPreferences() async {
    final res = await ApiClient.dio.get<dynamic>('/api/notifications/preferences');
    return NotificationPreferences.fromJson(_data(res));
  }

  static Future<void> updatePreferences(Json payload) async {
    await ApiClient.dio.put<dynamic>('/api/notifications/preferences', data: payload);
  }

  static Future<bool> canCreateNotifications() async {
    final res = await ApiClient.dio.get<dynamic>(
      '/api/admin/users/access/check',
      queryParameters: {'permission': 'NOTIFICATION_CREATE'},
    );
    final data = _data(res);
    return data['allowed'] as bool? ?? false;
  }

  static Future<bool> hasPermission(String permission) async {
    final res = await ApiClient.dio.get<dynamic>(
      '/api/admin/users/access/check',
      queryParameters: {'permission': permission},
    );
    final data = _data(res);
    return data['allowed'] as bool? ?? false;
  }
}

class NotificationList {
  final List<AppNotification> notifications;
  final int totalElements;
  final int totalPages;
  final bool hasNext;
  NotificationList({
    required this.notifications,
    required this.totalElements,
    required this.totalPages,
    required this.hasNext,
  });
}
