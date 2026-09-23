import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  static const _tokenKey = 'api_token';

  final http.Client _client = http.Client();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static final ApiClient instance = ApiClient._();

  ApiClient._();

  String get baseUrl => AppConfig.apiBaseUrl;

  Future<String?> get token => _secureStorage.read(key: _tokenKey);

  Future<void> setToken(String? value) async {
    if (value == null || value.isEmpty) {
      await _secureStorage.delete(key: _tokenKey);
    } else {
      await _secureStorage.write(key: _tokenKey, value: value);
    }
  }

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    return headers;
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    try {
      final res = await request().timeout(const Duration(seconds: 30));
      final body = res.body.isEmpty ? null : jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) return body;
      final message = _extractError(body) ?? 'Request failed (${res.statusCode})';
      throw ApiException(message, statusCode: res.statusCode);
    } on ApiException {
      rethrow;
    } on Exception catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  String? _extractError(dynamic body) {
    if (body is Map) {
      if (body['error'] is String) return body['error'] as String;
      if (body['message'] is String) return body['message'] as String;
    }
    return null;
  }

  Future<dynamic> get(String path, {bool withAuth = true}) {
    return _send(() async {
      final token = await this.token;
      final headers = _headers();
      if (withAuth && token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      return _client.get(Uri.parse('$baseUrl$path'), headers: headers);
    });
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body, bool withAuth = true}) {
    return _send(() async {
      final token = await this.token;
      final headers = _headers();
      if (withAuth && token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      return _client.post(
        Uri.parse('$baseUrl$path'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    });
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body, bool withAuth = true}) {
    return _send(() async {
      final token = await this.token;
      final headers = _headers();
      if (withAuth && token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      return _client.put(
        Uri.parse('$baseUrl$path'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    });
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body, bool withAuth = true}) {
    return _send(() async {
      final token = await this.token;
      final headers = _headers();
      if (withAuth && token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      return _client.patch(
        Uri.parse('$baseUrl$path'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    });
  }

  Future<dynamic> delete(String path, {bool withAuth = true}) {
    return _send(() async {
      final token = await this.token;
      final headers = _headers();
      if (withAuth && token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      return _client.delete(Uri.parse('$baseUrl$path'), headers: headers);
    });
  }

  void dispose() => _client.close();
}
