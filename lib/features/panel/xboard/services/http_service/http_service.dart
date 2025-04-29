import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/domain_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

typedef SilentLoginCallback = Future<bool> Function();

class HttpService {
  static String baseUrl = ''; // 替换为你的实际基础 URL
  final SilentLoginCallback _silentLogin;

  HttpService(this._silentLogin);

  // 初始化服务并设置动态域名
  static Future<void> initialize() async {
    baseUrl = await DomainService.fetchValidDomain();
  }

  Future<void> _writeLog(String message) async {
    final now = DateTime.now().toString().split('.').first;
    final logLine = '[HttpService] $now: $message\n';
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/app_login.log');
      await file.writeAsString(logLine, mode: FileMode.append);
    } catch (e) {}
  }

  // 处理 token 过期的统一方法
  Future<Map<String, String>?> _handleTokenExpired() async {
    await _writeLog('Token expired, trying silent login');
    final refreshed = await _silentLogin();
    if (refreshed) {
      final newToken = await getLoginToken();
      if (newToken != null) {
        await _writeLog('Silent login success, got new token');
        return {
          'Authorization': newToken,
          'X-Token-Type': 'login_token',
        };
      }
    }
    await _writeLog('Silent login failed');
    return null;
  }

  // 统一的 GET 请求方法
  Future<Map<String, dynamic>> getRequest(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    await _writeLog('GET request to: $endpoint');

    try {
      final response = await http
          .get(
            url,
            headers: headers,
          )
          .timeout(const Duration(seconds: 20)); // 设置超时时间

      if (kDebugMode) {
        print("GET $baseUrl$endpoint response: ${response.body}");
      }

      if (response.statusCode == 200) {
        await _writeLog('GET request success');
        return json.decode(response.body) as Map<String, dynamic>;
      }

      // 处理 token 过期情况
      if (response.statusCode == 401 || (json.decode(response.body) as Map<String, dynamic>)['message']?.toString().contains('未登录或登陆已过期') == true) {
        await _writeLog('Token expired detected in GET request');
        final newHeaders = await _handleTokenExpired();
        if (newHeaders != null) {
          await _writeLog('Retrying GET request with new token');
          final retryResponse = await http
              .get(
                url,
                headers: newHeaders,
              )
              .timeout(const Duration(seconds: 20));

          if (retryResponse.statusCode == 200) {
            await _writeLog('GET retry request success');
            return json.decode(retryResponse.body) as Map<String, dynamic>;
          }
        }
      }

      await _writeLog('GET request failed: ${response.statusCode}, ${response.body}');
      throw Exception("GET request to $baseUrl$endpoint failed: ${response.statusCode}, ${response.body}");
    } catch (e) {
      await _writeLog('GET request error: $e');
      if (kDebugMode) {
        print('Error during GET request to $baseUrl$endpoint: $e');
      }
      rethrow;
    }
  }

  // 统一的 POST 请求方法，增加 requiresHeaders 开关
  Future<Map<String, dynamic>> postRequest(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    bool requiresHeaders = true, // 新增开关参数，默认需要 headers
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    await _writeLog('POST request to: $endpoint');

    try {
      final response = await http
          .post(
            url,
            headers: requiresHeaders ? (headers ?? {'Content-Type': 'application/json'}) : null,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 20)); // 设置超时时间

      if (kDebugMode) {
        print("POST $baseUrl$endpoint response: ${response.body}");
      }

      if (response.statusCode == 200) {
        await _writeLog('POST request success');
        return json.decode(response.body) as Map<String, dynamic>;
      }

      // 处理 token 过期情况
      if (response.statusCode == 401 || (json.decode(response.body) as Map<String, dynamic>)['message']?.toString().contains('未登录或登陆已过期') == true) {
        await _writeLog('Token expired detected in POST request');
        final newHeaders = await _handleTokenExpired();
        if (newHeaders != null) {
          await _writeLog('Retrying POST request with new token');
          final retryHeaders = requiresHeaders ? {...(newHeaders), 'Content-Type': 'application/json'} : null;

          final retryResponse = await http
              .post(
                url,
                headers: retryHeaders,
                body: json.encode(body),
              )
              .timeout(const Duration(seconds: 20));

          if (retryResponse.statusCode == 200) {
            await _writeLog('POST retry request success');
            return json.decode(retryResponse.body) as Map<String, dynamic>;
          }
        }
      }

      await _writeLog('POST request failed: ${response.statusCode}, ${response.body}');
      throw Exception("POST request to $baseUrl$endpoint failed: ${response.statusCode}, ${response.body}");
    } catch (e) {
      await _writeLog('POST request error: $e');
      if (kDebugMode) {
        print('Error during POST request to $baseUrl$endpoint: $e');
      }
      rethrow;
    }
  }
}
