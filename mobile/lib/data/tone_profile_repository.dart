import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'api_client.dart';

class ToneProfileRepository extends ChangeNotifier {
  static const _directoryName = 'career_profile';
  static const _metadataName = 'writing_voice.json';

  final ApiClient api;

  List<String> questions = const [];
  Map<String, String> answers = const {};
  bool loading = false;
  bool saving = false;
  bool _syncedToSession = false;
  String? error;

  ToneProfileRepository({required this.api});

  bool get configured => answers.values.any((value) => value.trim().isNotEmpty);

  Future<void> loadLocal() async {
    try {
      final file = await _metadataFile();
      if (!await file.exists()) return;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return;
      answers = Map<String, String>.from(
        decoded.map((key, value) => MapEntry('$key', '$value')),
      );
    } catch (_) {
      error = 'Your saved writing voice could not be loaded.';
    }
    notifyListeners();
  }

  Future<void> load() async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      questions = await api.getList('/v1/career/tone/questions');
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'Writing voice questions could not be loaded.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> save(Map<String, String> values) async {
    if (saving) return false;
    final clean = Map<String, String>.fromEntries(
      values.entries
          .map((entry) => MapEntry(entry.key, entry.value.trim()))
          .where((entry) => entry.value.isNotEmpty),
    );
    if (clean.isEmpty) {
      error = 'Answer at least one question to set your writing voice.';
      notifyListeners();
      return false;
    }
    saving = true;
    error = null;
    notifyListeners();
    try {
      await api.post('/v1/career/tone/sync', body: {'answers': clean});
      answers = clean;
      _syncedToSession = true;
      final file = await _metadataFile();
      await file.writeAsString(jsonEncode(clean), flush: true);
      return true;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } catch (_) {
      error = 'Your writing voice could not be saved.';
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> ensureSynced() async {
    if (_syncedToSession || !configured) return _syncedToSession;
    try {
      await api.post('/v1/career/tone/sync', body: {'answers': answers});
      _syncedToSession = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> remove() async {
    try {
      await api.post('/v1/career/tone/remove');
    } catch (_) {
      // Local removal remains available if the university session expired.
    }
    final file = await _metadataFile();
    if (await file.exists()) await file.delete();
    answers = const {};
    _syncedToSession = false;
    error = null;
    notifyListeners();
  }

  void markSessionChanged() {
    _syncedToSession = false;
  }

  Future<File> _metadataFile() async {
    final root = await getApplicationSupportDirectory();
    final directory =
        Directory('${root.path}${Platform.pathSeparator}$_directoryName');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return File(
      '${directory.path}${Platform.pathSeparator}$_metadataName',
    );
  }
}
