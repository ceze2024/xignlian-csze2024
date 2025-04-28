// services/subscription_service.dart
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/auth_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';

class SubscriptionService {
  final HttpService _httpService = HttpService();

  // 获取订阅链接的方法，增加自动重试
  Future<String?> getSubscriptionLink(String accessToken, {int retries = 3, Duration delay = const Duration(seconds: 2)}) async {
    for (int i = 0; i < retries; i++) {
      try {
        final result = await _httpService.getRequest(
          "/api/v1/user/getSubscribe",
          headers: {
            'Authorization': accessToken,
          },
        );
        if (result.containsKey("data")) {
          final data = result["data"];
          if (data is Map<String, dynamic> && data.containsKey("subscribe_url")) {
            return data["subscribe_url"] as String?;
          }
        }
        throw Exception("Failed to retrieve subscription link");
      } catch (e) {
        // token失效时自动静默刷新token并重试一次
        if (i == 0) {
          final refreshed = await AuthService.silentLogin();
          if (refreshed) {
            final newToken = await getToken();
            if (newToken != null) {
              // 用新token重试本次
              continue;
            }
          }
        }
        if (i == retries - 1) rethrow;
        await Future.delayed(delay);
      }
    }
    throw Exception("Failed to retrieve subscription link after $retries retries");
  }

  // 重置订阅链接的方法，增加自动重试
  Future<String?> resetSubscriptionLink(String accessToken, {int retries = 3, Duration delay = const Duration(seconds: 2)}) async {
    for (int i = 0; i < retries; i++) {
      try {
        final result = await _httpService.getRequest(
          "/api/v1/passport/auth/forget",
          headers: {
            'Authorization': accessToken,
          },
        );
        if (result.containsKey("data")) {
          final data = result["data"];
          if (data is String) {
            return data;
          }
        }
        throw Exception("Failed to reset subscription link");
      } catch (e) {
        if (i == retries - 1) rethrow;
        await Future.delayed(delay);
      }
    }
    throw Exception("Failed to reset subscription link after $retries retries");
  }
}
