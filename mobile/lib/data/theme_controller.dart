import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeController extends ChangeNotifier {
  static const _key = 'careerloop_theme_mode';
  final FlutterSecureStorage _storage;
  bool _isDark = false;

  ThemeController({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> load() async {
    final saved = await _storage.read(key: _key);
    if (saved != null) {
      _isDark = saved == 'dark';
      notifyListeners();
    }
  }

  Future<void> toggle() => setDark(!_isDark);

  Future<void> setDark(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    notifyListeners();
    await _storage.write(key: _key, value: value ? 'dark' : 'light');
  }
}
