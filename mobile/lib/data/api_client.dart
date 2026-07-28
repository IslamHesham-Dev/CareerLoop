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

class DownloadedFile {
  final String path;
  final String filename;
  final String contentType;

  const DownloadedFile({
    required this.path,
    required this.filename,
    required this.contentType,
  });

  bool get isPdf =>
      contentType.toLowerCase().contains('pdf') ||
      filename.toLowerCase().endsWith('.pdf');
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

  Future<Map<String, dynamic>> uploadFile(
    String path, {
    required String fieldName,
    required String filePath,
    required String filename,
    Map<String, String> fields = const {},
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    request.headers.addAll({
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    });
    request.fields.addAll(fields);
    request.files.add(
      await http.MultipartFile.fromPath(
        fieldName,
        filePath,
        filename: filename,
      ),
    );
    final streamed =
        await _client.send(request).timeout(const Duration(minutes: 4));
    final response = await http.Response.fromStream(streamed);
    return _decode(response);
  }

  Future<DownloadedFile> download(
    String path, {
    required String filename,
  }) async {
    final request = http.Request('GET', _uri(path));
    request.headers.addAll(_headers()..remove('Content-Type'));
    final response =
        await _client.send(request).timeout(const Duration(minutes: 5));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await response.stream.bytesToString();
      var message = 'The file could not be downloaded.';
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
    final disposition = response.headers['content-disposition'] ?? '';
    final encodedName = RegExp(
      r"filename\*=UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(disposition)?.group(1);
    final quotedName = RegExp(
      r'filename="?([^";]+)"?',
      caseSensitive: false,
    ).firstMatch(disposition)?.group(1);
    var resolvedName = filename;
    if (encodedName != null && encodedName.isNotEmpty) {
      resolvedName = Uri.decodeComponent(encodedName);
    } else if (quotedName != null && quotedName.isNotEmpty) {
      resolvedName = quotedName;
    }
    final contentType =
        response.headers['content-type'] ?? 'application/octet-stream';
    if (contentType.toLowerCase().contains('pdf') &&
        !resolvedName.toLowerCase().endsWith('.pdf')) {
      resolvedName = '$resolvedName.pdf';
    }
    final directory = await getTemporaryDirectory();
    final safeName = resolvedName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final file = File('${directory.path}${Platform.pathSeparator}$safeName');
    await response.stream.pipe(file.openWrite());
    return DownloadedFile(
      path: file.path,
      filename: safeName,
      contentType: contentType,
    );
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
