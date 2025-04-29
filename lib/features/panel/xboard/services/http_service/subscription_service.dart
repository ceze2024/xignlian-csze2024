// services/subscription_service.dart
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service_provider.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SubscriptionService {
  final HttpService _httpService = HttpServiceProvider.instance;

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
      final authData = await getToken();
      if (authData == null) {
        await _writeLog('No auth_data token found');
        return null;
      }

      final result = await _httpService.getRequest(
        "/api/v1/user/getSubscribe",
        headers: {
          'Authorization': authData,
          'X-Token-Type': 'auth_data',
        },
      );

      if (result == null) {
        await _writeLog('getSubscriptionLink failed: HTTP response is null');
        return null;
      }

      await _writeLog('API response: ${result.toString()}');

      if (result['status'] != 'success') {
        final message = result['message'] ?? '未知错误';
        await _writeLog('getSubscriptionLink failed: $message');
        return null;
      }

      if (!result.containsKey("data")) {
        await _writeLog('getSubscriptionLink failed: no data field in response');
        return null;
      }

      final data = result["data"];
      if (data == null) {
        await _writeLog('getSubscriptionLink failed: data field is null');
        return null;
      }

      if (data is Map<String, dynamic>) {
        if (!data.containsKey("subscribe_url")) {
          await _writeLog('getSubscriptionLink failed: no subscribe_url field in data');
          return null;
        }
        final subscribeUrl = data["subscribe_url"];
        if (subscribeUrl == null) {
          await _writeLog('getSubscriptionLink failed: subscribe_url is null');
          return null;
        }
        await _writeLog('getSubscriptionLink success: $subscribeUrl');
        return subscribeUrl as String;
      } else if (data is String) {
        await _writeLog('getSubscriptionLink success: $data');
        return data;
      }

      await _writeLog('getSubscriptionLink failed: unexpected data format');
      return null;
    } catch (e) {
      await _writeLog('getSubscriptionLink error: $e');
      return null;
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
          'X-Token-Type': 'auth_data',
        },
      );
      if (result['status'] != 'success') {
        await _writeLog('resetSubscriptionLink failed: ${result['message'] ?? '未知错误'}');
        return null;
      }
      if (result.containsKey("data")) {
        final data = result["data"];
        if (data is String) {
          await _writeLog('resetSubscriptionLink success');
          return data;
        }
      }
      await _writeLog('resetSubscriptionLink failed: invalid response format');
      return null;
    } catch (e) {
      await _writeLog('resetSubscriptionLink error: $e');
      return null;
    }
  }
}
