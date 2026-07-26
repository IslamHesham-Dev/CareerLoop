import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'models.dart';

class PracticeRepository extends ChangeNotifier {
  final List<PracticeSet> _sets = [];

  List<PracticeSet> get sets => List.unmodifiable(_sets);

  Future<void> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return;
      final decoded = jsonDecode(await file.readAsString()) as List;
      _sets
        ..clear()
        ..addAll(
          decoded.map(
            (item) => PracticeSet.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          ),
        );
      notifyListeners();
    } catch (_) {
      // A damaged optional cache must never prevent the app from starting.
    }
  }

  Future<void> save(PracticeSet practiceSet) async {
    _sets.removeWhere((item) => item.id == practiceSet.id);
    _sets.insert(0, practiceSet);
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    _sets.removeWhere((item) => item.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final file = await _file();
    await file.writeAsString(
      jsonEncode(_sets.map((item) => item.toJson()).toList()),
      flush: true,
    );
  }

  Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}${Platform.pathSeparator}practice_sets.json');
  }
}
