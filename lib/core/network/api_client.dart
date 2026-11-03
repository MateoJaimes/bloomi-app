import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

int? parseApiInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

class ApiClient {
  ApiClient({http.Client? client, FlutterSecureStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  final http.Client _client;
  final FlutterSecureStorage _storage;
  static const _accessKey = 'bloomi.access_token';
  static const _refreshKey = 'bloomi.refresh_token';
  static const _configuredUrl = String.fromEnvironment('BLOOMI_API_BASE_URL');
  static String get defaultBaseUrl {
    if (_configuredUrl.isNotEmpty) return _configuredUrl;
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3000/v1'
        : 'http://localhost:3000/v1';
  }

  final String baseUrl = defaultBaseUrl.replaceFirst(RegExp(r'/$'), '');
  String? _accessToken;
  String? get accessToken => _accessToken;
  bool get hasSession => _accessToken != null;

  Future<void> restoreSession() async {
    _accessToken = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    if (refresh == null && _accessToken != null) {
      await clearSession();
      return;
    }
    if (refresh == null) return;
    if (_accessToken == null) {
      final result = await _raw('POST', '/auth/refresh', body: {'refreshToken': refresh});
      await _storeSession(result['session'] as Map<String, dynamic>);
      return;
    }
    try {
      await get('/me');
    } on ApiException catch (error) {
      if (error.statusCode == 404) return;
      if (error.statusCode != 401) rethrow;
      final result = await _raw('POST', '/auth/refresh', body: {'refreshToken': refresh});
      await _storeSession(result['session'] as Map<String, dynamic>);
    }
  }

  Future<Map<String, dynamic>> register({required String email, required String password, required String documentNumber, required String documentType}) async {
    final result = await _raw('POST', '/auth/register', body: {
      'email': email.trim(), 'password': password,
      'documentNumber': documentNumber.trim(), 'documentType': documentType,
    });
    final session = result['session'];
    if (session is Map<String, dynamic>) await _storeSession(session);
    return result;
  }

  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final result = await _raw('POST', '/auth/login', body: {'email': email.trim(), 'password': password});
    await _storeSession(result['session'] as Map<String, dynamic>);
    return result;
  }

  Future<void> logout() async {
    try { await post('/auth/logout', authenticated: true); } finally { await clearSession(); }
  }

  Future<void> forgotPassword(String email) async {
    await _raw('POST', '/auth/forgot-password', body: {'email': email.trim()});
  }

  Future<void> clearSession() async {
    _accessToken = null;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  Future<void> _storeSession(Map<String, dynamic> session) async {
    final access = session['accessToken'] as String?;
    final refresh = session['refreshToken'] as String?;
    if (access == null || refresh == null) throw const ApiException('La API no devolvió una sesión válida.');
    _accessToken = access;
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) => _request('GET', path, query: query);
  Future<dynamic> post(String path, {Object? body, bool authenticated = true}) => _request('POST', path, body: body, authenticated: authenticated);
  Future<dynamic> patch(String path, {Object? body}) => _request('PATCH', path, body: body);

  Future<dynamic> _request(String method, String path, {Object? body, Map<String, String>? query, bool authenticated = true, bool retried = false}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (authenticated && _accessToken != null) headers['Authorization'] = 'Bearer $_accessToken';
    final response = await _client.send(http.Request(method, uri)..headers.addAll(headers)..body = body == null ? '' : jsonEncode(body)).timeout(const Duration(seconds: 20));
    final text = await response.stream.bytesToString().timeout(const Duration(seconds: 20));
    dynamic decoded;
    if (text.isNotEmpty) { try { decoded = jsonDecode(text); } catch (_) { decoded = null; } }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401 && authenticated && !retried) {
        final refresh = await _storage.read(key: _refreshKey);
        if (refresh != null) {
          try {
            final refreshed = await _raw('POST', '/auth/refresh', body: {'refreshToken': refresh});
            await _storeSession(refreshed['session'] as Map<String, dynamic>);
            return _request(method, path, body: body, query: query, authenticated: authenticated, retried: true);
          } catch (_) {
            await clearSession();
          }
        }
      }
      final message = decoded is Map ? decoded['message'] : null;
      throw ApiException(message is String ? message : message is List ? message.join(', ') : 'Error de conexión con Bloomi (${response.statusCode}).', statusCode: response.statusCode);
    }
    return decoded;
  }

  Future<Map<String, dynamic>> _raw(String method, String path, {Object? body}) async {
    final result = await _request(method, path, body: body, authenticated: false);
    if (result is! Map<String, dynamic>) throw const ApiException('Respuesta no válida del servidor.');
    return result;
  }
}
