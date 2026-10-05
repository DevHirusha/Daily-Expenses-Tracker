import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static final String baseUrl =
      const String.fromEnvironment('API_BASE_URL', defaultValue: '').isNotEmpty
      ? const String.fromEnvironment('API_BASE_URL')
        : 'https://daily-expenses-tracker-g3l0.onrender.com/api/v1.0';

      // Local development URLs:
      // Web/desktop: http://localhost:3030/api/v1.0
      // Android emulator: http://10.0.2.2:3030/api/v1.0

  // ---------- REGISTER ----------
  static Future<Map<String, dynamic>> register({
    required String name,
    String? username,
    required String email,
    required String password,
  }) {
    return _postJson(Uri.parse('$baseUrl/register'), {
      'name': name,
      if (username != null && username.trim().isNotEmpty)
        'username': username.trim(),
      'email': email,
      'password': password,
    }, tag: 'REGISTER');
  }

  // ---------- LOGIN ----------
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return _postJson(Uri.parse('$baseUrl/login'), {
      'email': email,
      'password': password,
    }, tag: 'LOGIN');
  }

  // ---------- FRIENDS ----------
  static Future<List<Map<String, dynamic>>> searchUsers({
    required String token,
    required String username,
  }) async {
    final result = await _authorizedJson(
      method: 'GET',
      url: Uri.parse(
        '$baseUrl/friends/search?username=${Uri.encodeQueryComponent(username)}',
      ),
      token: token,
    );
    return _mapList(result);
  }

  static Future<Map<String, dynamic>> sendFriendRequest({
    required String token,
    required String username,
  }) async {
    final result = await _authorizedJson(
      method: 'POST',
      url: Uri.parse(
        '$baseUrl/friends/requests/${Uri.encodeComponent(username)}',
      ),
      token: token,
    );
    return Map<String, dynamic>.from(result as Map);
  }

  static Future<List<Map<String, dynamic>>> getFriendRequests({
    required String token,
  }) async {
    final result = await _authorizedJson(
      method: 'GET',
      url: Uri.parse('$baseUrl/friends/requests'),
      token: token,
    );
    return _mapList(result);
  }

  static Future<List<Map<String, dynamic>>> getFriends({
    required String token,
  }) async {
    final result = await _authorizedJson(
      method: 'GET',
      url: Uri.parse('$baseUrl/friends'),
      token: token,
    );
    return _mapList(result);
  }

  static Future<void> respondToFriendRequest({
    required String token,
    required int requestId,
    required bool accept,
  }) async {
    await _authorizedJson(
      method: 'POST',
      url: Uri.parse(
        '$baseUrl/friends/requests/$requestId/${accept ? 'accept' : 'decline'}',
      ),
      token: token,
    );
  }

  // ---------- GROUPS ----------
  static Future<List<Map<String, dynamic>>> getGroups({
    required String token,
  }) async {
    final result = await _authorizedJson(
      method: 'GET',
      url: Uri.parse('$baseUrl/groups'),
      token: token,
    );
    return _mapList(result);
  }

  static Future<Map<String, dynamic>> createGroup({
    required String token,
    required String name,
    required List<String> memberUserIds,
  }) async {
    final result = await _authorizedJson(
      method: 'POST',
      url: Uri.parse('$baseUrl/groups'),
      token: token,
      payload: {'name': name, 'memberUserIds': memberUserIds},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  static Future<Map<String, dynamic>> joinGroup({
    required String token,
    required String joinCode,
  }) async {
    final result = await _authorizedJson(
      method: 'POST',
      url: Uri.parse('$baseUrl/groups/join'),
      token: token,
      payload: {'joinCode': joinCode},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  static Future<Map<String, dynamic>> resetGroupJoinCode({
    required String token,
    required int groupId,
  }) async {
    final result = await _authorizedJson(
      method: 'PUT',
      url: Uri.parse('$baseUrl/groups/$groupId/join-code'),
      token: token,
    );
    return Map<String, dynamic>.from(result as Map);
  }

  static Future<List<Map<String, dynamic>>> getGroupMembers({
    required String token,
    required int groupId,
  }) async {
    final result = await _authorizedJson(
      method: 'GET',
      url: Uri.parse('$baseUrl/groups/$groupId/members'),
      token: token,
    );
    return _mapList(result);
  }

  static Future<void> addGroupMember({
    required String token,
    required int groupId,
    required String userId,
  }) async {
    await _authorizedJson(
      method: 'POST',
      url: Uri.parse(
        '$baseUrl/groups/$groupId/members/${Uri.encodeComponent(userId)}',
      ),
      token: token,
    );
  }

  static Future<void> removeGroupMember({
    required String token,
    required int groupId,
    required String userId,
  }) async {
    await _authorizedJson(
      method: 'DELETE',
      url: Uri.parse(
        '$baseUrl/groups/$groupId/members/${Uri.encodeComponent(userId)}',
      ),
      token: token,
    );
  }

  static Future<void> leaveGroup({
    required String token,
    required int groupId,
  }) async {
    await _authorizedJson(
      method: 'DELETE',
      url: Uri.parse('$baseUrl/groups/$groupId/leave'),
      token: token,
    );
  }

  // ---------- BUDGETS ----------
  static Future<Map<String, dynamic>> createBudget({
    required String token,
    required String name,
    required double amount,
    DateTime? startDate,
    DateTime? endDate,
    int? groupId,
    required List<String> memberUserIds,
    String? proofData,
  }) async {
    final result = await _authorizedJson(
      method: 'POST',
      url: Uri.parse('$baseUrl/budgets'),
      token: token,
      payload: {
        'name': name,
        'amount': amount,
        if (startDate != null) 'startDate': _dateOnly(startDate),
        if (endDate != null) 'endDate': _dateOnly(endDate),
        if (groupId != null) 'groupId': groupId,
        'memberUserIds': memberUserIds,
        if (proofData != null) 'proofData': proofData,
      },
    );
    return Map<String, dynamic>.from(result as Map);
  }

  static Future<List<Map<String, dynamic>>> getBudgets({
    required String token,
  }) async {
    final result = await _authorizedJson(
      method: 'GET',
      url: Uri.parse('$baseUrl/budgets'),
      token: token,
    );
    return _mapList(result);
  }

  static Future<List<Map<String, dynamic>>> getBudgetMembers({
    required String token,
    required int budgetId,
  }) async {
    final result = await _authorizedJson(
      method: 'GET',
      url: Uri.parse('$baseUrl/budgets/$budgetId/members'),
      token: token,
    );
    return _mapList(result);
  }

  static Future<void> addBudgetMember({
    required String token,
    required int budgetId,
    required String userId,
  }) async {
    await _authorizedJson(
      method: 'POST',
      url: Uri.parse(
        '$baseUrl/budgets/$budgetId/members/${Uri.encodeComponent(userId)}',
      ),
      token: token,
    );
  }

  static Future<void> deleteBudget({
    required String token,
    required int budgetId,
  }) async {
    await _authorizedJson(
      method: 'DELETE',
      url: Uri.parse('$baseUrl/budgets/$budgetId'),
      token: token,
    );
  }

  static Future<void> updateBudgetProof({
    required String token,
    required int budgetId,
    required String proofData,
  }) async {
    await _authorizedJson(
      method: 'PUT',
      url: Uri.parse('$baseUrl/budgets/$budgetId/proof'),
      token: token,
      payload: {'proofData': proofData},
    );
  }

  static Future<void> updateBudgetSplit({
    required String token,
    required int budgetId,
    required Map<String, double> percentages,
  }) async {
    await _authorizedJson(
      method: 'PUT',
      url: Uri.parse('$baseUrl/budgets/$budgetId/split'),
      token: token,
      payload: {'percentages': percentages},
    );
  }

  static Future<void> saveBudgetSettlement({
    required String token,
    required int budgetId,
    required double amount,
    required String proofData,
  }) async {
    await _authorizedJson(
      method: 'POST',
      url: Uri.parse('$baseUrl/budgets/$budgetId/settlements'),
      token: token,
      payload: {'amount': amount, 'proofData': proofData},
    );
  }

  static Future<List<Map<String, dynamic>>> getBudgetSettlements({
    required String token,
    required int budgetId,
  }) async {
    final result = await _authorizedJson(
      method: 'GET',
      url: Uri.parse('$baseUrl/budgets/$budgetId/settlements'),
      token: token,
    );
    return _mapList(result);
  }

  static String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

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
          message =
              body['message']?.toString() ??
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

  static Future<dynamic> _authorizedJson({
    required String method,
    required Uri url,
    required String token,
    Map<String, dynamic>? payload,
  }) async {
    final client = http.Client();
    try {
      final request = http.Request(method, url)
        ..headers['Content-Type'] = 'application/json'
        ..headers['Authorization'] = 'Bearer $token';
      if (payload != null) {
        request.body = jsonEncode(payload);
      }
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 15));
      final body = await http.Response.fromStream(response);

      if (body.statusCode >= 200 && body.statusCode < 300) {
        return body.body.isEmpty ? null : jsonDecode(body.body);
      }

      String message = 'Request failed (${body.statusCode})';
      try {
        final decoded = jsonDecode(body.body);
        if (decoded is Map) {
          message =
              decoded['message']?.toString() ??
              decoded['error']?.toString() ??
              message;
        }
      } catch (_) {}
      throw Exception(message);
    } on http.ClientException {
      throw Exception('Cannot reach server. Is backend running on port 3030?');
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } finally {
      client.close();
    }
  }

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
