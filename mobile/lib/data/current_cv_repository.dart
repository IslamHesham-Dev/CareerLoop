import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'api_client.dart';
import 'application_models.dart';

class CurrentCvRepository extends ChangeNotifier {
  static const _directoryName = 'career_profile';
  static const _pdfName = 'current_cv.pdf';
  static const _metadataName = 'current_cv.json';
  static const _maxBytes = 10 * 1024 * 1024;

  final ApiClient api;

  CurrentCv? currentCv;
  ResumeProfile? profile;
  bool selecting = false;
  bool syncing = false;
  bool _syncedToSession = false;
  String? error;

  CurrentCvRepository({required this.api});

  bool get hasCv => currentCv != null;
  bool get hasProfile => currentCv != null && profile != null;

  Future<void> loadLocal() async {
    try {
      final directory = await _directory();
      final pdf = File('${directory.path}${Platform.pathSeparator}$_pdfName');
      final metadata =
          File('${directory.path}${Platform.pathSeparator}$_metadataName');
      if (!await pdf.exists() || !await metadata.exists()) return;
      final decoded = jsonDecode(await metadata.readAsString());
      if (decoded is! Map) return;
      final payload = Map<String, dynamic>.from(decoded);
      final cvJson = payload['cv'];
      currentCv = CurrentCv.fromJson(
        cvJson is Map ? Map<String, dynamic>.from(cvJson) : payload,
        localPath: pdf.path,
      );
      final profileJson = payload['profile'];
      if (profileJson is Map) {
        profile = ResumeProfile.fromJson(
          Map<String, dynamic>.from(profileJson),
        );
      }
    } catch (_) {
      error = 'The saved resume could not be loaded.';
    }
    notifyListeners();
  }

  Future<bool> pick() async {
    if (selecting) return false;
    selecting = true;
    error = null;
    notifyListeners();
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        allowMultiple: false,
        withData: false,
      );
      if (result == null || result.files.isEmpty) return false;
      final selected = result.files.first;
      if (selected.path == null) {
        error = 'CareerLoop could not read the selected resume.';
        return false;
      }
      return _importFile(
        selected.path!,
        fileName: selected.name,
        expectedSize: selected.size,
      );
    } finally {
      selecting = false;
      notifyListeners();
    }
  }

  @visibleForTesting
  Future<bool> importFile(
    String filePath, {
    required String fileName,
  }) async {
    if (selecting) return false;
    selecting = true;
    error = null;
    notifyListeners();
    try {
      return _importFile(filePath, fileName: fileName);
    } finally {
      selecting = false;
      notifyListeners();
    }
  }

  Future<bool> _importFile(
    String filePath, {
    required String fileName,
    int? expectedSize,
  }) async {
    try {
      final source = File(filePath);
      if (!await source.exists()) {
        error = 'The selected resume is no longer available.';
        return false;
      }
      final size =
          (expectedSize ?? 0) > 0 ? expectedSize! : await source.length();
      if (size == 0 || size > _maxBytes) {
        error = 'Choose a non-empty resume PDF up to 10 MB.';
        return false;
      }
      final header = await source.openRead(0, 4).fold<List<int>>(
        <int>[],
        (bytes, part) => bytes..addAll(part),
      );
      if (ascii.decode(header, allowInvalid: true) != '%PDF') {
        error = 'The selected file is not a valid PDF.';
        return false;
      }
      final json = await api.uploadFile(
        '/v1/career/resume/import',
        fieldName: 'file',
        filePath: source.path,
        filename: fileName,
      );
      final profileJson = json['profile'];
      if (profileJson is! Map) {
        error = 'CareerLoop could not extract a profile from this resume.';
        return false;
      }
      final extracted = ResumeProfile.fromJson(
        Map<String, dynamic>.from(profileJson),
      );
      final directory = await _directory();
      final destination =
          File('${directory.path}${Platform.pathSeparator}$_pdfName');
      if (source.absolute.path != destination.absolute.path) {
        await source.copy(destination.path);
      }
      currentCv = CurrentCv(
        fileName: fileName,
        localPath: destination.path,
        sizeBytes: size,
        importedAt: extracted.importedAt,
      );
      profile = extracted;
      _syncedToSession = true;
      await _saveMetadata();
      notifyListeners();
      return true;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } catch (_) {
      error = 'The resume could not be extracted and saved.';
      return false;
    }
  }

  Future<bool> ensureSynced() async {
    if (_syncedToSession || currentCv == null || syncing) {
      return _syncedToSession;
    }
    syncing = true;
    error = null;
    notifyListeners();
    try {
      if (profile == null) {
        final json = await api.uploadFile(
          '/v1/career/resume/import',
          fieldName: 'file',
          filePath: currentCv!.localPath,
          filename: currentCv!.fileName,
        );
        final profileJson = json['profile'];
        if (profileJson is! Map) return false;
        profile = ResumeProfile.fromJson(
          Map<String, dynamic>.from(profileJson),
        );
        await _saveMetadata();
        notifyListeners();
      } else {
        await api.post(
          '/v1/career/resume/sync',
          body: profile!.toJson(),
        );
      }
      _syncedToSession = true;
      return true;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } catch (_) {
      error = 'The saved resume could not be loaded into agent context.';
      return false;
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  Future<void> remove() async {
    try {
      await api.post('/v1/career/resume/remove');
    } catch (_) {
      // Local removal still succeeds if the university session expired.
    }
    final directory = await _directory();
    for (final name in [_pdfName, _metadataName]) {
      final file = File('${directory.path}${Platform.pathSeparator}$name');
      if (await file.exists()) await file.delete();
    }
    currentCv = null;
    profile = null;
    _syncedToSession = false;
    error = null;
    notifyListeners();
  }

  void markSessionChanged() {
    _syncedToSession = false;
  }

  Future<void> _saveMetadata() async {
    final cv = currentCv;
    if (cv == null) return;
    final directory = await _directory();
    final metadata =
        File('${directory.path}${Platform.pathSeparator}$_metadataName');
    await metadata.writeAsString(
      jsonEncode({
        'cv': cv.toJson(),
        'profile': profile?.toJson(),
      }),
      flush: true,
    );
  }

  Future<Directory> _directory() async {
    final root = await getApplicationSupportDirectory();
    final directory =
        Directory('${root.path}${Platform.pathSeparator}$_directoryName');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }
}
