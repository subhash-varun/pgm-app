import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pgm_app/core/api_client.dart';
import 'package:pgm_app/screens/rooms/rooms_screen.dart';
import 'package:pgm_app/screens/tenants/tenants_screen.dart';
import 'package:pgm_app/services/api_services.dart';

class FakeAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final Map<String, Map<String, dynamic>> routes = {};

  void addRoute(String path, Map<String, dynamic> body) {
    routes[path] = body;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final path = options.path;
    final routesByLength = routes.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    final body = routesByLength
        .where((e) => path.startsWith(e.key))
        .firstOrNull
        ?.value;
    if (body == null) {
      return ResponseBody.fromString(
        jsonEncode({'status': 404, 'message': 'no route'}),
        404,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> pageData(List<Map<String, dynamic>> content) => {
      'status': 200,
      'message': 'ok',
      'data': {
        'content': content,
        'totalElements': content.length,
        'totalPages': 1,
        'size': 10,
        'number': 0,
        'first': true,
        'last': true,
        'empty': content.isEmpty,
      },
    };

Map<String, dynamic> tenant(int id, String name, String status) => {
      'id': id,
      'roomId': 1,
      'roomNumber': '101',
      'name': name,
      'email': '$name@test.com',
      'phone': '9999999999',
      'idProofType': 'AADHAR',
      'idProofNumber': '1234',
      'checkInDate': '2026-01-01',
      'depositAmount': 5000,
      'status': status,
      'createdAt': '2026-01-01T10:00:00',
    };

Map<String, dynamic> room(int id, String number, String type, String status) => {
      'id': id,
      'roomNumber': number,
      'roomType': type,
      'rentAmount': 6000,
      'status': status,
      'facilities': '',
      'createdAt': '2026-01-01T10:00:00',
    };

void main() {
  setUp(() {
    final adapter = FakeAdapter();
    ApiClient.dio.httpClientAdapter = adapter;
  });

  testWidgets('tapping ACTIVE filter sends status request', (tester) async {
    final adapter = FakeAdapter();
    ApiClient.dio.httpClientAdapter = adapter;
    adapter.addRoute(
      '/api/admin/tenants/status/ACTIVE',
      pageData([tenant(1, 'Active One', 'ACTIVE')]),
    );
    adapter.addRoute(
      '/api/admin/tenants',
      pageData([
        tenant(1, 'Active One', 'ACTIVE'),
        tenant(2, 'Tenant Moved', 'MOVED_OUT'),
      ]),
    );

    await tester.pumpWidget(
      const MaterialApp(home: TenantsScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Active One'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Active'));
    await tester.pumpAndSettle();

    final paths = adapter.requests.map((r) => r.path).toList();
    expect(
      paths,
      contains('/api/admin/tenants/status/ACTIVE'),
      reason: 'Expected a status-filtered request, got: $paths',
    );
    expect(find.text('Tenant Moved'), findsNothing);
  });

  testWidgets('rooms status chip calls /api/admin/rooms/status endpoint',
      (tester) async {
    final adapter = FakeAdapter();
    ApiClient.dio.httpClientAdapter = adapter;
    adapter.addRoute(
      '/api/admin/rooms/status/AVAILABLE',
      {
        'status': 'success',
        'message': 'ok',
        'data': [room(1, '101', 'SINGLE', 'AVAILABLE')],
      },
    );
    adapter.addRoute(
      '/api/admin/rooms',
      pageData([
        room(1, '101', 'SINGLE', 'AVAILABLE'),
        room(2, '102', 'DOUBLE', 'OCCUPIED'),
      ]),
    );

    await tester.pumpWidget(
      const MaterialApp(home: RoomsScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Room 101'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Available'));
    await tester.pumpAndSettle();

    final paths = adapter.requests.map((r) => r.path).toList();
    expect(
      paths,
      contains('/api/admin/rooms/status/AVAILABLE'),
      reason: 'Expected a status-filtered request, got: $paths',
    );
  });

  test('payments status filter hits /api/admin/payments/status endpoint',
      () async {
    final adapter = FakeAdapter();
    ApiClient.dio.httpClientAdapter = adapter;
    adapter.addRoute(
      '/api/admin/payments/status/PAID',
      pageData([
        {
          'id': 1,
          'tenantId': 1,
          'tenantName': 'Paying Person',
          'amount': 6000,
          'paymentDate': '2026-01-01',
          'paymentMonth': 'January-2026',
          'paymentMethod': 'UPI',
          'receiptNumber': 'RCP001',
          'status': 'PAID',
          'createdAt': '2026-01-01T10:00:00',
        },
      ]),
    );

    final data = await PaymentsService.list(status: 'PAID', page: 0, size: 10);

    expect(
      adapter.requests.last.path,
      '/api/admin/payments/status/PAID',
    );
    expect(data.content, hasLength(1));
    expect(data.content.first.status, 'PAID');
  });
}
