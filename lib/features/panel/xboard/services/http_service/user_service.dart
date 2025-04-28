// services/user_service.dart
import 'package:hiddify/features/panel/xboard/models/user_info_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/auth_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';

class UserService {
  final HttpService _httpService = HttpService();

  Future<UserInfo?> fetchUserInfo(String accessToken) async {
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
      // token失效时自动静默刷新token并重试一次
      final refreshed = await AuthService.silentLogin();
      if (refreshed) {
        final newToken = await getToken();
        if (newToken != null) {
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
      rethrow;
    }
  }

  Future<bool> validateToken(String token) async {
    try {
      final response = await _httpService.getRequest(
        "/api/v1/user/getSubscribe",
        headers: {'Authorization': token},
      );
      return response['status'] == 'success';
    } catch (_) {
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
