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
      final authData = await getToken(); // 获取auth_data token
      if (authData == null) {
        await _writeLog('No auth_data token found');
        // 不清除token，让用户在启动时能继续尝试登录
        return false;
      }

      final result = await _httpService.getRequest(
        "/api/v1/user/info",
        headers: {
          'Authorization': authData,
          'X-Token-Type': 'auth_data',
        },
      );
      await _writeLog('validateToken success');
      return result['data'] != null;
    } catch (e) {
      await _writeLog('validateToken error: $e');
      // 捕获到异常时不清除token，让用户可以在下次启动时再次尝试
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
