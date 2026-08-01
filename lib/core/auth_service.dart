import 'dart:convert';

import '../core/api_client.dart';

class AuthStore {
  AuthStore._();

  static final AuthStore instance = AuthStore._();

  String? token;
  bool get isAuthenticated => token != null;

  void setToken(String value) {
    token = value;
  }

  void clear() {
    token = null;
  }
}

class AuthService {
  static Future<void> login(String email, String password) async {
    final res = await ApiClient.dio.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = res.data?['data'] as Map<String, dynamic>?;
    final token = data?['token'] as String?;
    if (token == null) throw Exception('No token returned');
    await ApiClient.setToken(token);
    AuthStore.instance.setToken(token);
  }

  static Future<void> register({
    required String name,
    required String email,
    required String contactNo,
    required String password,
  }) async {
    await ApiClient.dio.post<Map<String, dynamic>>(
      '/api/auth/register',
      data: {
        'name': name,
        'email': email,
        'contactNo': contactNo,
        'password': password,
      },
    );
  }

  static Future<void> logout() async {
    try {
      await ApiClient.dio.post<Map<String, dynamic>>('/api/auth/logout');
    } catch (_) {
      // ignore network errors on logout
    }
    await ApiClient.clearToken();
    AuthStore.instance.clear();
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final res = await ApiClient.dio.get<dynamic>('/api/auth/profile');
    final data = res.data is Map ? (res.data as Map)['data'] : null;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  static Future<void> updateProfile({
    required String name,
    required String email,
    required String contactNo,
  }) async {
    await ApiClient.dio.put<Map<String, dynamic>>(
      '/api/auth/profile',
      data: {'name': name, 'email': email, 'contactNo': contactNo},
    );
  }
}

class JsonUtil {
  static Map<String, dynamic> decodeMap(dynamic data) {
    if (data is String) return jsonDecode(data) as Map<String, dynamic>;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  static List<dynamic> decodeList(dynamic data) {
    if (data is String) return jsonDecode(data) as List<dynamic>;
    if (data is List) return data;
    return [];
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
