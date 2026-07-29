import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class QuickLoginCredentials {
  final String username;
  final String password;
  final int enrollmentYear;
  final String institution;

  const QuickLoginCredentials({
    required this.username,
    required this.password,
    required this.enrollmentYear,
    required this.institution,
  });
}

class SessionStorage {
  static const _tokenKey = 'careerloop_session_token';
  static const _usernameKey = 'careerloop_portal_username';
  static const _quickLoginEnabledKey = 'careerloop_quick_login_enabled';
  static const _quickLoginPasswordKey = 'careerloop_quick_login_password';
  static const _quickLoginEnrollmentKey =
      'careerloop_quick_login_enrollment_year';
  static const _quickLoginInstitutionKey = 'careerloop_quick_login_institution';
  final FlutterSecureStorage _storage;

  SessionStorage()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  Future<String?> readUsername() => _storage.read(key: _usernameKey);

  Future<void> saveUsername(String username) =>
      _storage.write(key: _usernameKey, value: username.trim());

  Future<bool> hasQuickLogin() async =>
      await _storage.read(key: _quickLoginEnabledKey) == 'true';

  Future<QuickLoginCredentials?> readQuickLogin() async {
    if (!await hasQuickLogin()) return null;
    final values = await Future.wait([
      _storage.read(key: _usernameKey),
      _storage.read(key: _quickLoginPasswordKey),
      _storage.read(key: _quickLoginEnrollmentKey),
      _storage.read(key: _quickLoginInstitutionKey),
    ]);
    final enrollmentYear = int.tryParse(values[2] ?? '');
    if (values[0] == null ||
        values[1] == null ||
        enrollmentYear == null ||
        values[3] == null) {
      return null;
    }
    return QuickLoginCredentials(
      username: values[0]!,
      password: values[1]!,
      enrollmentYear: enrollmentYear,
      institution: values[3]!,
    );
  }

  Future<void> saveQuickLogin(QuickLoginCredentials credentials) async {
    await saveUsername(credentials.username);
    await _storage.write(
      key: _quickLoginPasswordKey,
      value: credentials.password,
    );
    await _storage.write(
      key: _quickLoginEnrollmentKey,
      value: credentials.enrollmentYear.toString(),
    );
    await _storage.write(
      key: _quickLoginInstitutionKey,
      value: credentials.institution,
    );
    // Write the marker last so partially written credentials are never used.
    await _storage.write(key: _quickLoginEnabledKey, value: 'true');
  }

  Future<void> clearQuickLogin() async {
    await _storage.delete(key: _quickLoginEnabledKey);
    await Future.wait([
      _storage.delete(key: _quickLoginPasswordKey),
      _storage.delete(key: _quickLoginEnrollmentKey),
      _storage.delete(key: _quickLoginInstitutionKey),
    ]);
  }
}
