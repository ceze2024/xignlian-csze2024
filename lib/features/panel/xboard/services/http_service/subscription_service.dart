// services/subscription_service.dart
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SubscriptionService {
  final HttpService _httpService = HttpService();

  Future<void> _writeLog(String message) async {
    final now = DateTime.now().toString().split('.').first;
    final logLine = '[SubscriptionService] $now: $message\n';
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/app_login.log');
      await file.writeAsString(logLine, mode: FileMode.append);
    } catch (e) {}
  }

  // 获取订阅链接的方法
  Future<String?> getSubscriptionLink(String accessToken) async {
    await _writeLog('getSubscriptionLink called, token: $accessToken');
    try {
      final result = await _httpService.getRequest(
        "/api/v1/user/getSubscribe",
        headers: {
          'Authorization': accessToken,
          'X-Token-Type': 'login_token',
        },
      );

      if (result == null) {
        await _writeLog('getSubscriptionLink failed: HTTP response is null');
        throw Exception('HTTP响应为空');
      }

      if (result['status'] != 'success') {
        final message = result['message'] ?? '未知错误';
        await _writeLog('getSubscriptionLink failed: $message');
        throw Exception('业务失败: $message');
      }

      if (result.containsKey("data")) {
        final data = result["data"];
        if (data is Map<String, dynamic> && data.containsKey("subscribe_url")) {
          await _writeLog('getSubscriptionLink success');
          return data["subscribe_url"] as String?;
        }
      }
      await _writeLog('getSubscriptionLink failed: invalid response format');
      throw Exception("响应格式错误");
    } catch (e) {
      await _writeLog('getSubscriptionLink error: $e');
      rethrow;
    }
  }

  // 重置订阅链接的方法
  Future<String?> resetSubscriptionLink(String accessToken) async {
    await _writeLog('resetSubscriptionLink called');
    try {
      final result = await _httpService.getRequest(
        "/api/v1/passport/auth/forget",
        headers: {
          'Authorization': accessToken,
          'X-Token-Type': 'login_token',
        },
      );
      if (result['status'] != 'success') {
        final message = result['message'] ?? '未知错误';
        await _writeLog('resetSubscriptionLink failed: $message');
        throw Exception('业务失败: $message');
      }
      if (result.containsKey("data")) {
        final data = result["data"];
        if (data is String) {
          await _writeLog('resetSubscriptionLink success');
          return data;
        }
      }
      await _writeLog('resetSubscriptionLink failed: invalid response format');
      throw Exception("Failed to reset subscription link");
    } catch (e) {
      await _writeLog('resetSubscriptionLink error: $e');
      rethrow;
    }
  }
}
