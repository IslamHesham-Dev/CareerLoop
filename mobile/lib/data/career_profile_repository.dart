import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'api_client.dart';
import 'models.dart';

class CareerProfileRepository extends ChangeNotifier {
  static const _directoryName = 'career_profile';
  static const _pdfName = 'linkedin_profile.pdf';
  static const _metadataName = 'linkedin_profile.json';
  static const _maxBytes = 10 * 1024 * 1024;

  final ApiClient api;

  LinkedInPdfProfile? profile;
  String? localPdfPath;
  bool importing = false;
  bool syncing = false;
  bool _syncedToSession = false;
  String? error;

  CareerProfileRepository({required this.api});

  bool get hasProfile => profile != null && localPdfPath != null;

  Future<void> loadLocal() async {
    try {
      final directory = await _profileDirectory();
      final metadata =
          File('${directory.path}${Platform.pathSeparator}$_metadataName');
      final pdf = File('${directory.path}${Platform.pathSeparator}$_pdfName');
      if (!await metadata.exists() || !await pdf.exists()) return;
      final json = jsonDecode(await metadata.readAsString());
      if (json is! Map) return;
      profile = LinkedInPdfProfile.fromJson(
        Map<String, dynamic>.from(json),
      );
      localPdfPath = pdf.path;
    } catch (_) {
      error = 'The saved LinkedIn profile could not be loaded.';
    }
    notifyListeners();
  }

  Future<bool> pickAndImport() async {
    if (importing) return false;
    error = null;
    notifyListeners();
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return false;
    final selected = result.files.first;
    if (selected.size > _maxBytes) {
      error = 'Choose a LinkedIn PDF that is 10 MB or smaller.';
      notifyListeners();
      return false;
    }
    final path = selected.path;
    if (path == null) {
      error = 'CareerLoop could not read the selected PDF.';
      notifyListeners();
      return false;
    }
    return importFile(path, fileName: selected.name);
  }

  @visibleForTesting
  Future<bool> importFile(
    String sourcePath, {
    required String fileName,
  }) async {
    importing = true;
    error = null;
    notifyListeners();
    try {
      final source = File(sourcePath);
      if (!await source.exists()) {
        error = 'The selected PDF is no longer available.';
        return false;
      }
      final length = await source.length();
      if (length == 0 || length > _maxBytes) {
        error = 'Choose a non-empty LinkedIn PDF up to 10 MB.';
        return false;
      }
      final json = await api.uploadFile(
        '/v1/career/linkedin-profile/import',
        fieldName: 'file',
        filePath: source.path,
        filename: fileName,
      );
      final profileJson = json['profile'];
      if (profileJson is! Map) {
        error = 'No professional profile was found in this PDF.';
        return false;
      }
      final imported = LinkedInPdfProfile.fromJson(
        Map<String, dynamic>.from(profileJson),
      );
      final directory = await _profileDirectory();
      final destination =
          File('${directory.path}${Platform.pathSeparator}$_pdfName');
      if (source.absolute.path != destination.absolute.path) {
        await source.copy(destination.path);
      }
      final metadata =
          File('${directory.path}${Platform.pathSeparator}$_metadataName');
      await metadata.writeAsString(jsonEncode(imported.toJson()), flush: true);
      profile = imported;
      localPdfPath = destination.path;
      _syncedToSession = true;
      return true;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } catch (_) {
      error = 'The LinkedIn PDF could not be imported.';
      return false;
    } finally {
      importing = false;
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
        '/v1/career/linkedin-profile/sync',
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
      await api.post('/v1/career/linkedin-profile/remove');
    } catch (_) {
      // Local removal must still succeed if the university session expired.
    }
    try {
      final directory = await _profileDirectory();
      final pdf = File('${directory.path}${Platform.pathSeparator}$_pdfName');
      final metadata =
          File('${directory.path}${Platform.pathSeparator}$_metadataName');
      if (await pdf.exists()) await pdf.delete();
      if (await metadata.exists()) await metadata.delete();
    } finally {
      profile = null;
      localPdfPath = null;
      _syncedToSession = false;
      error = null;
      notifyListeners();
    }
  }

  void markSessionChanged() {
    _syncedToSession = false;
  }

  Future<Directory> _profileDirectory() async {
    final root = await getApplicationSupportDirectory();
    final directory =
        Directory('${root.path}${Platform.pathSeparator}$_directoryName');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }
}
