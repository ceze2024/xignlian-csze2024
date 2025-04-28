// services/subscription_service.dart
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/auth_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SubscriptionService {
  final HttpService _httpService = HttpService();

  // 获取订阅链接的方法，增加自动重试
  Future<String?> getSubscriptionLink(String accessToken, {int retries = 3, Duration delay = const Duration(seconds: 2)}) async {
    final now = DateTime.now().toString().split('.').first;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/app_login.log');
      await file.writeAsString('[SubscriptionService] $now: getSubscriptionLink called, token: $accessToken\n', mode: FileMode.append);
    } catch (e) {}
    for (int i = 0; i < retries; i++) {
      try {
        final result = await _httpService.getRequest(
          "/api/v1/user/getSubscribe",
          headers: {
            'Authorization': accessToken,
          },
        );
        if (result['status'] != 'success') {
          throw Exception('业务失败: \\${result['message'] ?? ''}');
        }
        if (result.containsKey("data")) {
          final data = result["data"];
          if (data is Map<String, dynamic> && data.containsKey("subscribe_url")) {
            try {
              final dir = await getApplicationDocumentsDirectory();
              final file = File('${dir.path}/app_login.log');
              await file.writeAsString('[SubscriptionService] $now: getSubscriptionLink success\n', mode: FileMode.append);
            } catch (e) {}
            return data["subscribe_url"] as String?;
          }
        }
        throw Exception("Failed to retrieve subscription link");
      } catch (e) {
        try {
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/app_login.log');
          await file.writeAsString('[SubscriptionService] $now: getSubscriptionLink error: $e, retry $i\n', mode: FileMode.append);
        } catch (e) {}
        if (i == 0) {
          final refreshed = await AuthService.silentLogin();
          if (refreshed) {
            final newToken = await getToken();
            if (newToken != null) {
              try {
                final dir = await getApplicationDocumentsDirectory();
                final file = File('${dir.path}/app_login.log');
                await file.writeAsString('[SubscriptionService] $now: getSubscriptionLink silentLogin成功, retry with newToken\n', mode: FileMode.append);
              } catch (e) {}
              continue;
            }
          }
        }
        if (i == retries - 1) {
          try {
            final dir = await getApplicationDocumentsDirectory();
            final file = File('${dir.path}/app_login.log');
            await file.writeAsString('[SubscriptionService] $now: getSubscriptionLink 最终失败\n', mode: FileMode.append);
          } catch (e) {}
          rethrow;
        }
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
        if (result['status'] != 'success') {
          throw Exception('业务失败: \\${result['message'] ?? ''}');
        }
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
