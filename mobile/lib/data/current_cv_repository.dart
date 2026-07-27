import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'application_models.dart';

class CurrentCvRepository extends ChangeNotifier {
  static const _directoryName = 'career_profile';
  static const _pdfName = 'current_cv.pdf';
  static const _metadataName = 'current_cv.json';
  static const _maxBytes = 10 * 1024 * 1024;

  CurrentCv? currentCv;
  bool selecting = false;
  String? error;

  bool get hasCv => currentCv != null;

  Future<void> loadLocal() async {
    try {
      final directory = await _directory();
      final pdf = File('${directory.path}${Platform.pathSeparator}$_pdfName');
      final metadata =
          File('${directory.path}${Platform.pathSeparator}$_metadataName');
      if (!await pdf.exists() || !await metadata.exists()) return;
      final payload = jsonDecode(await metadata.readAsString());
      if (payload is Map) {
        currentCv = CurrentCv.fromJson(
          Map<String, dynamic>.from(payload),
          localPath: pdf.path,
        );
      }
    } catch (_) {
      error = 'The saved CV could not be loaded.';
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
      if (selected.path == null || selected.size == 0) {
        error = 'CareerLoop could not read the selected CV.';
        return false;
      }
      if (selected.size > _maxBytes) {
        error = 'Choose a CV that is 10 MB or smaller.';
        return false;
      }
      final source = File(selected.path!);
      final header = await source.openRead(0, 4).fold<List<int>>(
        <int>[],
        (bytes, part) => bytes..addAll(part),
      );
      if (ascii.decode(header, allowInvalid: true) != '%PDF') {
        error = 'The selected file is not a valid PDF.';
        return false;
      }
      final directory = await _directory();
      final destination =
          File('${directory.path}${Platform.pathSeparator}$_pdfName');
      if (source.absolute.path != destination.absolute.path) {
        await source.copy(destination.path);
      }
      currentCv = CurrentCv(
        fileName: selected.name,
        localPath: destination.path,
        sizeBytes: selected.size,
        importedAt: DateTime.now(),
      );
      final metadata =
          File('${directory.path}${Platform.pathSeparator}$_metadataName');
      await metadata.writeAsString(
        jsonEncode(currentCv!.toJson()),
        flush: true,
      );
      return true;
    } catch (_) {
      error = 'The CV could not be saved on this device.';
      return false;
    } finally {
      selecting = false;
      notifyListeners();
    }
  }

  Future<void> remove() async {
    final directory = await _directory();
    for (final name in [_pdfName, _metadataName]) {
      final file = File('${directory.path}${Platform.pathSeparator}$name');
      if (await file.exists()) await file.delete();
    }
    currentCv = null;
    error = null;
    notifyListeners();
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
