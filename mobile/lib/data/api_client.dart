import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'session_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  final String baseUrl;
  final SessionStorage storage;
  final http.Client _client;
  String? _token;

  ApiClient({
    required this.baseUrl,
    required this.storage,
    http.Client? client,
  }) : _client = client ?? http.Client();

  set accessToken(String? value) => _token = value;

  Uri _uri(String path, [Map<String, String?>? query]) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final values = query == null
        ? null
        : Map<String, String>.fromEntries(
            query.entries
                .where((entry) => entry.value?.isNotEmpty ?? false)
                .map((entry) => MapEntry(entry.key, entry.value!)),
          );
    return Uri.parse('$normalizedBase$path').replace(queryParameters: values);
  }

  Map<String, String> _headers({bool authenticated = true}) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authenticated && _token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String?>? query,
    bool authenticated = true,
  }) async {
    final response = await _client
        .get(
          _uri(path, query),
          headers: _headers(authenticated: authenticated),
        )
        .timeout(const Duration(minutes: 3));
    return _decode(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final response = await _client
        .post(
          _uri(path),
          headers: _headers(authenticated: authenticated),
          body: jsonEncode(body ?? const {}),
        )
        .timeout(const Duration(minutes: 4));
    return _decode(response);
  }

  Future<String> download(
    String path, {
    required String filename,
  }) async {
    final request = http.Request('GET', _uri(path));
    request.headers.addAll(_headers()..remove('Content-Type'));
    final response =
        await _client.send(request).timeout(const Duration(minutes: 5));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await response.stream.bytesToString();
      var message = 'The CMS file could not be downloaded.';
      try {
        final payload = jsonDecode(body);
        if (payload is Map && payload['detail'] is String) {
          message = payload['detail'] as String;
        }
      } catch (_) {
        // Keep the safe fallback when the upstream returns HTML.
      }
      throw ApiException(message, statusCode: response.statusCode);
    }
    final directory = await getTemporaryDirectory();
    final safeName = filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final file = File('${directory.path}${Platform.pathSeparator}$safeName');
    await response.stream.pipe(file.openWrite());
    return file.path;
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> payload = const {};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        payload = Map<String, dynamic>.from(decoded);
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = payload['detail'];
      throw ApiException(
        detail is String ? detail : 'The request could not be completed.',
        statusCode: response.statusCode,
      );
    }
    return payload;
  }
}
