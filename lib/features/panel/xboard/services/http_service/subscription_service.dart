// services/subscription_service.dart
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service_provider.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';

class SubscriptionService {
  final HttpService _httpService = HttpServiceProvider.instance;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);

  Future<void> _writeLog(String message) async {
    final now = DateTime.now().toString().split('.').first;
    final logLine = '[SubscriptionService] $now: $message\n';
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/app_login.log');
      await file.writeAsString(logLine, mode: FileMode.append);
    } catch (e) {
      print('Failed to write log: $e'); // 添加控制台日志作为备份
    }
  }

  Future<T?> _retryOperation<T>(Future<T?> Function() operation, String operationName) async {
    int retryCount = 0;
    while (retryCount < _maxRetries) {
      try {
        final result = await operation();
        if (result != null) {
          return result;
        }
        retryCount++;
        if (retryCount < _maxRetries) {
          await _writeLog('$operationName attempt $retryCount failed, retrying after ${_retryDelay.inSeconds}s...');
          await Future.delayed(_retryDelay);
        }
      } catch (e) {
        await _writeLog('$operationName error on attempt $retryCount: $e');
        retryCount++;
        if (retryCount < _maxRetries) {
          await Future.delayed(_retryDelay);
        }
      }
    }
    await _writeLog('$operationName failed after $_maxRetries attempts');
    return null;
  }

  // 获取订阅链接的方法
  Future<String?> getSubscriptionLink(String accessToken) async {
    return _retryOperation(() async {
      await _writeLog('getSubscriptionLink called with token: $accessToken');
      final authData = await getToken();
      if (authData == null || authData.isEmpty) {
        await _writeLog('No valid auth_data token found');
        return null;
      }

      final result = await _httpService.getRequest(
        "/api/v1/user/getSubscribe",
        headers: {
          'Authorization': authData,
          'X-Token-Type': 'auth_data',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _writeLog('getSubscriptionLink request timeout');
          throw TimeoutException('Request timed out');
        },
      );

      if (result == null) {
        await _writeLog('getSubscriptionLink failed: HTTP response is null');
        return null;
      }

      await _writeLog('API response: ${result.toString()}');

      // 处理未登录或登录过期的情况
      if (result is Map<String, dynamic> && result.containsKey('message') && (result['message'].toString().contains('未登录') || result['message'].toString().contains('过期'))) {
        await _writeLog('Token expired or invalid, but not clearing tokens to allow re-login');
        // 不清除所有存储的token，让用户能够在UI中看到登录失效，并重新登录
        // await clearTokens(); // 注释掉自动清除token的代码
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
      }

      await _writeLog('getSubscriptionLink failed: unexpected data format');
      return null;
    }, 'getSubscriptionLink');
  }

  // 重置订阅链接的方法
  Future<String?> resetSubscriptionLink(String accessToken) async {
    return _retryOperation(() async {
      await _writeLog('resetSubscriptionLink called with token: $accessToken');
      final authData = await getToken();
      if (authData == null || authData.isEmpty) {
        await _writeLog('No valid auth_data token found');
        return null;
      }

      final result = await _httpService.getRequest(
        "/api/v1/passport/auth/forget",
        headers: {
          'Authorization': authData,
          'X-Token-Type': 'auth_data',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _writeLog('resetSubscriptionLink request timeout');
          throw TimeoutException('Request timed out');
        },
      );

      if (result == null) {
        await _writeLog('resetSubscriptionLink failed: HTTP response is null');
        return null;
      }

      await _writeLog('Reset API response: ${result.toString()}');

      // 处理未登录或登录过期的情况
      if (result is Map<String, dynamic> && result.containsKey('message') && (result['message'].toString().contains('未登录') || result['message'].toString().contains('过期'))) {
        await _writeLog('Token expired or invalid, but not clearing tokens to allow re-login');
        // 不清除所有存储的token，让用户能够在UI中看到登录失效，并重新登录
        // await clearTokens(); // 注释掉自动清除token的代码
        return null;
      }

      if (!result.containsKey('status')) {
        await _writeLog('resetSubscriptionLink failed: no status field in response');
        return null;
      }

      if (result['status'] != 'success') {
        final message = result['message'] ?? '未知错误';
        await _writeLog('resetSubscriptionLink failed: $message');
        return null;
      }

      if (!result.containsKey("data")) {
        await _writeLog('resetSubscriptionLink failed: no data field in response');
        return null;
      }

      final data = result["data"];
      if (data == null) {
        await _writeLog('resetSubscriptionLink failed: data field is null');
        return null;
      }

      if (data is String) {
        await _writeLog('resetSubscriptionLink success: $data');
        return data;
      }

      await _writeLog('resetSubscriptionLink failed: unexpected data format');
      return null;
    }, 'resetSubscriptionLink');
  }
}
