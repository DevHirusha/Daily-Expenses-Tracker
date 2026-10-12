import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StoredSession {
  final String email;
  final String token;
  final DateTime expiresAt;

  const StoredSession({
    required this.email,
    required this.token,
    required this.expiresAt,
  });
}

class AuthStorage {
  AuthStorage._();

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _emailKey = 'auth_email';
  static const _expiresAtKey = 'auth_expires_at';

  static Future<void> saveSession({
    required String email,
    required String token,
  }) async {
    final expiresAt = _addMonths(DateTime.now(), 3);
    await Future.wait([
      _storage.write(key: _tokenKey, value: token),
      _storage.write(key: _emailKey, value: email),
      _storage.write(
        key: _expiresAtKey,
        value: expiresAt.millisecondsSinceEpoch.toString(),
      ),
    ]);
  }

  static Future<StoredSession?> readSession() async {
    final values = await Future.wait([
      _storage.read(key: _tokenKey),
      _storage.read(key: _emailKey),
      _storage.read(key: _expiresAtKey),
    ]);

    final token = values[0];
    final email = values[1];
    final expiryText = values[2];
    final expiryMillis = int.tryParse(expiryText ?? '');

    if (token == null ||
        token.isEmpty ||
        email == null ||
        email.isEmpty ||
        expiryMillis == null) {
      await clearSession();
      return null;
    }

    final expiresAt = DateTime.fromMillisecondsSinceEpoch(expiryMillis);
    if (!expiresAt.isAfter(DateTime.now())) {
      await clearSession();
      return null;
    }

    return StoredSession(email: email, token: token, expiresAt: expiresAt);
  }

  static Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _emailKey),
      _storage.delete(key: _expiresAtKey),
    ]);
  }

  static DateTime _addMonths(DateTime date, int months) {
    final monthIndex = date.year * 12 + date.month - 1 + months;
    final year = monthIndex ~/ 12;
    final month = monthIndex % 12 + 1;
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final day = date.day < lastDayOfMonth ? date.day : lastDayOfMonth;

    return DateTime(
      year,
      month,
      day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }
}
