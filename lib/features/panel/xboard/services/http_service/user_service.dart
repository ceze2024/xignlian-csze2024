// services/user_service.dart
import 'package:hiddify/features/panel/xboard/models/user_info_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/auth_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class UserService {
  final HttpService _httpService = HttpService();

  Future<void> _writeLog(String message) async {
    final now = DateTime.now().toString().split('.').first;
    final logLine = '[UserService] $now: $message\n';
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/app_login.log');
      await file.writeAsString(logLine, mode: FileMode.append);
    } catch (e) {}
  }

  Future<UserInfo?> fetchUserInfo(String accessToken) async {
    await _writeLog('fetchUserInfo called, token: $accessToken');
    try {
      final result = await _httpService.getRequest(
        "/api/v1/user/info",
        headers: {
          'Authorization': accessToken,
          'X-Token-Type': 'login_token',
        },
      );
      if (result.containsKey("data")) {
        final data = result["data"];
        await _writeLog('fetchUserInfo success');
        return UserInfo.fromJson(data as Map<String, dynamic>);
      }
      await _writeLog('fetchUserInfo failed: no data in response');
      throw Exception("Failed to retrieve user info");
    } catch (e) {
      await _writeLog('fetchUserInfo error: $e');
      rethrow;
    }
  }

  Future<bool> validateToken(String token) async {
    await _writeLog('validateToken called, token: $token');
    try {
      final response = await _httpService.getRequest(
        "/api/v1/user/getSubscribe",
        headers: {
          'Authorization': token,
          'X-Token-Type': 'login_token',
        },
      );
      final result = response['status'] == 'success';
      await _writeLog('validateToken result: $result');
      return result;
    } catch (e) {
      await _writeLog('validateToken error: $e');
      return false;
    }
  }

  Future<String?> getSubscriptionLink(String accessToken) async {
    final result = await _httpService.getRequest(
      "/api/v1/user/getSubscribe",
      headers: {
        'Authorization': accessToken,
        'X-Token-Type': 'login_token',
      },
    );
    // ignore: avoid_dynamic_calls
    return result["data"]["subscribe_url"] as String?;
  }

  Future<String?> resetSubscriptionLink(String accessToken) async {
    final result = await _httpService.getRequest(
      "/api/v1/user/resetSecurity",
      headers: {
        'Authorization': accessToken,
        'X-Token-Type': 'login_token',
      },
    );
    return result["data"] as String?;
  }
}
