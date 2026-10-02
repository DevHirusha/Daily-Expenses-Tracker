import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static final String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  ).isNotEmpty
      ? const String.fromEnvironment('API_BASE_URL')
      : kIsWeb || defaultTargetPlatform != TargetPlatform.android
          ? 'http://localhost:3030/api/v1.0'
          : 'http://10.0.2.2:3030/api/v1.0';

  // ---------- REGISTER ----------
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _postJson(
      Uri.parse('$baseUrl/register'),
      {'name': name, 'email': email, 'password': password},
      tag: 'REGISTER',
    );
  }

  // ---------- LOGIN ----------
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return _postJson(
      Uri.parse('$baseUrl/login'),
      {'email': email, 'password': password},
      tag: 'LOGIN',
    );
  }

  // ---------- SEND RESET OTP ----------
  // Backend: @PostMapping("/send-reset-otp") with @RequestParam String email
  static Future<void> sendResetOtp({required String email}) async {
    final url = Uri.parse(
      '$baseUrl/send-reset-otp?email=${Uri.encodeQueryComponent(email)}',
    );

    try {
      final response = await http
          .post(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 15));

      print('=== SEND OTP DEBUG ===');
      print('URL     : $url');
      print('STATUS  : ${response.statusCode}');
      print('BODY    : ${response.body}');
      print('======================');

      // Backend returns void -> 200 with empty body on success
      if (response.statusCode == 200 || response.statusCode == 204) return;

      String message = 'Failed to send OTP (${response.statusCode})';
      try {
        final body = jsonDecode(response.body);
        if (body is Map) {
          message = body['message']?.toString() ?? body.toString();
        }
      } catch (_) {}
      throw Exception(message);
    } on http.ClientException {
      throw Exception('Cannot reach server. Is backend running on port 3030?');
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on Exception catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ---------- RESET PASSWORD ----------
  // Backend: @PostMapping("/reset-password") with @RequestBody ResetPasswordRequest
  static Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/reset-password');

    try {
      final response = await http
          .post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      )
          .timeout(const Duration(seconds: 15));

      print('=== RESET PWD DEBUG ===');
      print('URL     : $url');
      print('STATUS  : ${response.statusCode}');
      print('BODY    : ${response.body}');
      print('=======================');

      if (response.statusCode == 200 || response.statusCode == 204) return;

      String message = 'Failed to reset password (${response.statusCode})';
      try {
        final body = jsonDecode(response.body);
        if (body is Map) {
          message = body['message']?.toString() ?? body.toString();
        }
      } catch (_) {}
      throw Exception(message);
    } on http.ClientException {
      throw Exception('Cannot reach server. Is backend running on port 3030?');
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on Exception catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ---------- shared POST helper ----------
  static Future<Map<String, dynamic>> _postJson(
      Uri url,
      Map<String, dynamic> payload, {
        required String tag,
      }) async {
    try {
      final response = await http
          .post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      )
          .timeout(const Duration(seconds: 15));

      print('=== $tag DEBUG ===');
      print('URL     : $url');
      print('STATUS  : ${response.statusCode}');
      print('BODY    : ${response.body}');
      print('====================');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        throw Exception('Unexpected response format');
      }

      // Try to extract backend error message
      String message = 'Request failed (${response.statusCode})';
      try {
        final body = jsonDecode(response.body);
        if (body is Map) {
          message = body['message']?.toString() ??
              body['error']?.toString() ??
              body.toString();
        }
      } catch (_) {}
      throw Exception(message);
    } on http.ClientException catch (e) {
      print('SOCKET ERROR: $e');
      throw Exception('Cannot reach server. Is backend running on port 3030?');
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on FormatException catch (e) {
      throw Exception('Bad JSON from server: ${e.message}');
    } on Exception catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}