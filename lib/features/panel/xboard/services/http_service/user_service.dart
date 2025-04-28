// services/user_service.dart
import 'package:hiddify/features/panel/xboard/models/user_info_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/auth_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class UserService {
  final HttpService _httpService = HttpService();

  Future<UserInfo?> fetchUserInfo(String accessToken) async {
    final now = DateTime.now().toString().split('.').first;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/app_login.log');
      await file.writeAsString('[UserService] $now: fetchUserInfo called, token: $accessToken\n', mode: FileMode.append);
    } catch (e) {}
    try {
      final result = await _httpService.getRequest(
        "/api/v1/user/info",
        headers: {'Authorization': accessToken},
      );
      if (result.containsKey("data")) {
        final data = result["data"];
        return UserInfo.fromJson(data as Map<String, dynamic>);
      }
      throw Exception("Failed to retrieve user info");
    } catch (e) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/app_login.log');
        await file.writeAsString('[UserService] $now: fetchUserInfo token失效或异常: $e\n', mode: FileMode.append);
      } catch (e) {}
      // token失效时自动静默刷新token并重试一次
      final refreshed = await AuthService.silentLogin();
      if (refreshed) {
        final newToken = await getToken();
        if (newToken != null) {
          try {
            final dir = await getApplicationDocumentsDirectory();
            final file = File('${dir.path}/app_login.log');
            await file.writeAsString('[UserService] $now: fetchUserInfo silentLogin成功, retry with newToken\n', mode: FileMode.append);
          } catch (e) {}
          final result = await _httpService.getRequest(
            "/api/v1/user/info",
            headers: {'Authorization': newToken},
          );
          if (result.containsKey("data")) {
            final data = result["data"];
            return UserInfo.fromJson(data as Map<String, dynamic>);
          }
        }
      }
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/app_login.log');
        await file.writeAsString('[UserService] $now: fetchUserInfo silentLogin失败或重试失败\n', mode: FileMode.append);
      } catch (e) {}
      rethrow;
    }
  }

  Future<bool> validateToken(String token) async {
    final now = DateTime.now().toString().split('.').first;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/app_login.log');
      await file.writeAsString('[UserService] $now: validateToken called, token: $token\n', mode: FileMode.append);
    } catch (e) {}
    try {
      final response = await _httpService.getRequest(
        "/api/v1/user/getSubscribe",
        headers: {'Authorization': token},
      );
      final result = response['status'] == 'success';
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/app_login.log');
        await file.writeAsString('[UserService] $now: validateToken result: $result\n', mode: FileMode.append);
      } catch (e) {}
      return result;
    } catch (e) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/app_login.log');
        await file.writeAsString('[UserService] $now: validateToken error: $e\n', mode: FileMode.append);
      } catch (e) {}
      return false;
    }
  }

  Future<String?> getSubscriptionLink(String accessToken) async {
    final result = await _httpService.getRequest(
      "/api/v1/user/getSubscribe",
      headers: {'Authorization': accessToken},
    );
    // ignore: avoid_dynamic_calls
    return result["data"]["subscribe_url"] as String?;
  }

  Future<String?> resetSubscriptionLink(String accessToken) async {
    final result = await _httpService.getRequest(
      "/api/v1/user/resetSecurity",
      headers: {'Authorization': accessToken},
    );
    return result["data"] as String?;
  }
}
