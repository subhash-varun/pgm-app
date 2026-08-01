import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Generic API debug logging for every dio request/response.
///
/// Logs: method + URL, sanitized request payload (passwords/tokens masked),
/// response status + body, and error details. Enabled automatically in debug
/// builds; can be forced on/off via [enabled].
class ApiLog {
  /// Set to `true` to log in release builds too, or `false` to silence.
  static bool enabled = kDebugMode;

  static void _line(String tag, String message) {
    if (!enabled) return;
    for (final chunk in _chunks(message)) {
      debugPrint('[$tag] $chunk');
    }
  }

  static List<String> _chunks(String message, {int width = 900}) {
    if (message.length <= width) return [message];
    final chunks = <String>[];
    for (var i = 0; i < message.length; i += width) {
      chunks.add(message.substring(i, i + width > message.length ? message.length : i + width));
    }
    return chunks;
  }

  static String _format(Object? data) {
    if (data == null) return '';
    final sanitized = _sanitize(data);
    try {
      return const JsonEncoder.withIndent('  ').convert(sanitized);
    } catch (_) {
      return sanitized.toString();
    }
  }

  /// Recursively masks sensitive keys (password, token, secret, authorization)
  /// so secrets never hit the log.
  static Object? _sanitize(Object? value) {
    if (value is Map) {
      return value.map((k, v) {
        final key = k.toString().toLowerCase();
        final sensitive = key.contains('password') ||
            key.contains('token') ||
            key.contains('secret') ||
            key.contains('authorization');
        return MapEntry(k.toString(), sensitive ? '***' : _sanitize(v));
      });
    }
    if (value is List) {
      return value.map(_sanitize).toList();
    }
    return value;
  }

  static String _truncate(String body, {int maxChars = 6000}) {
    if (body.length <= maxChars) return body;
    return '${body.substring(0, maxChars)}\n... [truncated ${body.length - maxChars} chars]';
  }
}

class ApiLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (ApiLog.enabled) {
      final method = options.method.toUpperCase();
      ApiLog._line('API REQ', '$method ${options.uri}');
      final body = ApiLog._format(options.data);
      if (body.isNotEmpty) ApiLog._line('API REQ BODY', body);
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (ApiLog.enabled) {
      final method = response.requestOptions.method.toUpperCase();
      final uri = response.requestOptions.uri;
      ApiLog._line('API RES', '$method $uri -> ${response.statusCode}');
      final body = ApiLog._format(response.data);
      if (body.isNotEmpty) ApiLog._line('API RES BODY', ApiLog._truncate(body));
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (ApiLog.enabled) {
      final method = err.requestOptions.method.toUpperCase();
      final uri = err.requestOptions.uri;
      final status = err.response?.statusCode;
      ApiLog._line(
        'API ERR',
        '$method $uri -> ${status ?? 'NO RESPONSE'} (${err.type.name})',
      );
      final data = err.response?.data;
      if (data != null) {
        ApiLog._line('API ERR BODY', ApiLog._truncate(ApiLog._format(data)));
      }
    }
    handler.next(err);
  }
}
