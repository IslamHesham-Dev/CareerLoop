import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'api_client.dart';
import 'models.dart';

class GithubProfileRepository extends ChangeNotifier {
  static const _directoryName = 'career_profile';
  static const _metadataName = 'github_profile.json';

  final ApiClient api;

  GithubProfileEvidence? profile;
  GithubDeviceAuthorization? authorization;
  bool configured = false;
  bool loading = false;
  bool polling = false;
  bool syncing = false;
  bool _syncedToSession = false;
  String authorizationStatus = 'idle';
  String? configurationMessage;
  String? error;

  GithubProfileRepository({required this.api});

  bool get hasProfile => profile != null;

  Future<void> loadLocal() async {
    try {
      final file = await _metadataFile();
      if (!await file.exists()) return;
      final json = jsonDecode(await file.readAsString());
      if (json is! Map) return;
      profile = GithubProfileEvidence.fromJson(
        Map<String, dynamic>.from(json),
      );
    } catch (_) {
      error = 'The saved GitHub profile could not be loaded.';
    }
    notifyListeners();
  }

  Future<bool> refreshStatus() async {
    try {
      final json = await api.get('/v1/career/github-profile');
      configured = json['configured'] as bool? ?? false;
      configurationMessage = json['message'] as String?;
      final profileJson = json['profile'];
      if (profileJson is Map) {
        profile = GithubProfileEvidence.fromJson(
          Map<String, dynamic>.from(profileJson),
        );
        _syncedToSession = true;
        await _saveLocal();
      }
      return configured;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } catch (_) {
      error = 'The GitHub connection could not be checked.';
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<GithubDeviceAuthorization?> beginConnection() async {
    if (loading) return authorization;
    loading = true;
    error = null;
    authorizationStatus = 'starting';
    notifyListeners();
    try {
      final json = await api.post('/v1/career/github/connect/start');
      authorization = GithubDeviceAuthorization.fromJson(json);
      authorizationStatus = 'pending';
      configured = true;
      return authorization;
    } on ApiException catch (exception) {
      error = exception.message;
      authorizationStatus = 'error';
      return null;
    } catch (_) {
      error = 'GitHub authorization could not be started.';
      authorizationStatus = 'error';
      return null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String> pollConnection() async {
    if (polling) return authorizationStatus;
    polling = true;
    error = null;
    notifyListeners();
    try {
      final json = await api.post('/v1/career/github/connect/poll');
      authorizationStatus = json['status'] as String? ?? 'pending';
      final profileJson = json['profile'];
      if (authorizationStatus == 'connected' && profileJson is Map) {
        profile = GithubProfileEvidence.fromJson(
          Map<String, dynamic>.from(profileJson),
        );
        authorization = null;
        _syncedToSession = true;
        await _saveLocal();
      } else if (authorizationStatus == 'expired' ||
          authorizationStatus == 'denied') {
        error = json['message'] as String? ??
            'GitHub authorization was not completed.';
        authorization = null;
      }
      return authorizationStatus;
    } on ApiException catch (exception) {
      error = exception.message;
      authorizationStatus = 'error';
      return authorizationStatus;
    } catch (_) {
      error = 'GitHub authorization could not be checked.';
      authorizationStatus = 'error';
      return authorizationStatus;
    } finally {
      polling = false;
      notifyListeners();
    }
  }

  Future<bool> refreshProfile() async {
    if (loading) return false;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final json = await api.post('/v1/career/github-profile/refresh');
      final profileJson = json['profile'];
      if (profileJson is! Map) {
        error = 'GitHub returned no portfolio evidence.';
        return false;
      }
      profile = GithubProfileEvidence.fromJson(
        Map<String, dynamic>.from(profileJson),
      );
      _syncedToSession = true;
      await _saveLocal();
      return true;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } catch (_) {
      error = 'The GitHub profile could not be refreshed.';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> ensureSynced() async {
    if (_syncedToSession || profile == null || syncing) {
      return _syncedToSession;
    }
    syncing = true;
    notifyListeners();
    try {
      await api.post(
        '/v1/career/github-profile/sync',
        body: profile!.toJson(),
      );
      _syncedToSession = true;
      return true;
    } catch (_) {
      return false;
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  Future<void> remove() async {
    try {
      await api.post('/v1/career/github-profile/remove');
    } catch (_) {
      // Local removal remains available if the university session expired.
    }
    final file = await _metadataFile();
    if (await file.exists()) await file.delete();
    profile = null;
    authorization = null;
    authorizationStatus = 'idle';
    _syncedToSession = false;
    error = null;
    notifyListeners();
  }

  void markSessionChanged() {
    _syncedToSession = false;
    authorization = null;
    authorizationStatus = 'idle';
  }

  Future<void> _saveLocal() async {
    final value = profile;
    if (value == null) return;
    final file = await _metadataFile();
    await file.writeAsString(jsonEncode(value.toJson()), flush: true);
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
