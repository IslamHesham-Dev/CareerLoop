import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'api_client.dart';

/// The student's tone-of-voice onboarding: four fixed questions
/// (`GET /v1/career/tone/questions`) and their raw text answers
/// (`GET`/`POST /v1/career/tone`), which the backend turns into a style
/// reference for CV, cover letter, email, and (via `ToneMiddleware`) every
/// chat reply from CareerLoop Copilot.
///
/// Follows the same on-device-cache + ephemeral-session pattern as
/// [CareerProfileRepository]/[GithubProfileRepository]: answers are the
/// student's own words, so they're worth keeping locally and re-syncing
/// after every login rather than re-asking the same four questions.
class ToneRepository extends ChangeNotifier {
  static const _directoryName = 'career_profile';
  static const _metadataName = 'tone_profile.json';

  final ApiClient api;

  List<String> questions = const [];
  Map<String, String> answers = const {};
  bool loadingQuestions = false;
  bool saving = false;
  bool _syncedToSession = false;
  String? error;

  ToneRepository({required this.api});

  bool get hasProfile => answers.values.any((answer) => answer.trim().isNotEmpty);

  Future<void> loadLocal() async {
    try {
      final file = await _metadataFile();
      if (!await file.exists()) return;
      final json = jsonDecode(await file.readAsString());
      if (json is! Map) return;
      final saved = json['answers'];
      if (saved is Map) {
        answers = Map<String, String>.from(saved);
      }
    } catch (_) {
      error = 'The saved tone answers could not be loaded.';
    }
    notifyListeners();
  }

  Future<void> loadQuestions() async {
    if (loadingQuestions) return;
    loadingQuestions = true;
    error = null;
    notifyListeners();
    try {
      final raw = await api.getList('/v1/career/tone/questions');
      questions = raw.whereType<String>().toList();
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'The onboarding questions could not be loaded.';
    } finally {
      loadingQuestions = false;
      notifyListeners();
    }
  }

  Future<bool> save(Map<String, String> newAnswers) async {
    if (saving) return false;
    saving = true;
    error = null;
    notifyListeners();
    try {
      final cleaned = Map<String, String>.fromEntries(
        newAnswers.entries.where((entry) => entry.value.trim().isNotEmpty),
      );
      await api.post('/v1/career/tone/sync', body: {'answers': cleaned});
      answers = cleaned;
      _syncedToSession = true;
      await _saveLocal();
      return true;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } catch (_) {
      error = 'Your tone answers could not be saved.';
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> ensureSynced() async {
    if (_syncedToSession || !hasProfile || saving) {
      return _syncedToSession;
    }
    saving = true;
    notifyListeners();
    try {
      await api.post('/v1/career/tone/sync', body: {'answers': answers});
      _syncedToSession = true;
      return true;
    } catch (_) {
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> remove() async {
    try {
      await api.post('/v1/career/tone/remove');
    } catch (_) {
      // Local removal must still succeed if the university session expired.
    }
    try {
      final file = await _metadataFile();
      if (await file.exists()) await file.delete();
    } finally {
      answers = const {};
      _syncedToSession = false;
      error = null;
      notifyListeners();
    }
  }

  void markSessionChanged() {
    _syncedToSession = false;
  }

  Future<void> _saveLocal() async {
    final file = await _metadataFile();
    await file.writeAsString(
      jsonEncode({'answers': answers}),
      flush: true,
    );
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
