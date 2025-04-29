// services/user_service.dart
import 'package:hiddify/features/panel/xboard/models/user_info_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service_provider.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class UserService {
  final HttpService _httpService;

  UserService() : _httpService = HttpServiceProvider.instance;

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
          'X-Token-Type': 'auth_data',
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
      final result = await _httpService.getRequest(
        "/api/v1/user/getSubscribe",
        headers: {
          'Authorization': token,
          'X-Token-Type': 'auth_data',
        },
      );
      final resultBool = result != null && result['status'] == 'success';
      await _writeLog('validateToken result: $resultBool');
      return resultBool;
    } catch (e) {
      await _writeLog('validateToken error: $e');
      return false;
    }
  }

  Future<String?> getSubscriptionLink(String accessToken) async {
    await _writeLog('getSubscriptionLink called');
    try {
      final result = await _httpService.getRequest(
        "/api/v1/user/getSubscribe",
        headers: {
          'Authorization': accessToken,
          'X-Token-Type': 'auth_data',
        },
      );
      if (result != null && result.containsKey("data")) {
        final data = result["data"];
        if (data is Map<String, dynamic> && data.containsKey("subscribe_url")) {
          await _writeLog('getSubscriptionLink success');
          return data["subscribe_url"] as String?;
        }
      }
      await _writeLog('getSubscriptionLink failed: invalid response format');
      return null;
    } catch (e) {
      await _writeLog('getSubscriptionLink error: $e');
      return null;
    }
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
