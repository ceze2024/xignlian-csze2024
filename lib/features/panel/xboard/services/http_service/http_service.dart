import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/domain_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

typedef SilentLoginCallback = Future<bool> Function();

class HttpService {
  static String baseUrl = '';
  static HttpService? _instance;
  final SilentLoginCallback? _silentLogin;
  bool _isRefreshingToken = false;

  HttpService._({SilentLoginCallback? silentLogin}) : _silentLogin = silentLogin;

  static HttpService get instance {
    _instance ??= HttpService._();
    return _instance!;
  }

  static Future<void> initialize({SilentLoginCallback? silentLogin}) async {
    _instance = HttpService._(silentLogin: silentLogin);
    await initializeDomain();
  }

  static Future<void> initializeDomain() async {
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

  bool _isTokenExpiredResponse(http.Response response) {
    if (response.statusCode == 401) return true;
    try {
      final body = json.decode(response.body) as Map<String, dynamic>;
      final message = body['message']?.toString().toLowerCase() ?? '';
      return message.contains('未登录') || message.contains('登陆已过期') || message.contains('token') && message.contains('过期');
    } catch (_) {
      return false;
    }
  }

  // 处理 token 过期的统一方法
  Future<Map<String, String>?> _handleTokenExpired() async {
    await _writeLog('Token expired, trying silent login');

    // 防止多个请求同时刷新 token
    if (_isRefreshingToken) {
      await _writeLog('Token refresh already in progress, waiting...');
      // 等待现有的刷新完成
      while (_isRefreshingToken) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      final loginToken = await getLoginToken();
      final authData = await getToken();
      if (loginToken != null && authData != null) {
        return {
          'Authorization': authData,
          'X-Token-Type': 'auth_data',
        };
      }
      return null;
    }

    _isRefreshingToken = true;
    try {
      if (_silentLogin == null) {
        await _writeLog('No silent login callback provided');
        return null;
      }

      final refreshed = await _silentLogin!();
      if (refreshed) {
        final loginToken = await getLoginToken();
        final authData = await getToken();
        if (loginToken != null && authData != null) {
          await _writeLog('Silent login success, got new tokens');
          return {
            'Authorization': authData,
            'X-Token-Type': 'auth_data',
          };
        }
      }
      await _writeLog('Silent login failed');
      return null;
    } finally {
      _isRefreshingToken = false;
    }
  }

  // 统一的 GET 请求方法
  Future<Map<String, dynamic>> getRequest(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    await _writeLog('GET request to: $endpoint');

    try {
      // 获取两种token
      final loginToken = await getLoginToken();
      final authData = await getToken();

      // 合并请求头
      final Map<String, String> finalHeaders = {
        if (loginToken != null) 'Authorization': loginToken,
        if (loginToken != null) 'X-Token-Type': 'login_token',
        if (authData != null) 'Auth-Data': authData,
        ...?headers,
      };

      final response = await http
          .get(
            url,
            headers: finalHeaders,
          )
          .timeout(const Duration(seconds: 20));

      if (kDebugMode) {
        print("GET $baseUrl$endpoint response: ${response.body}");
      }

      if (response.statusCode == 200) {
        await _writeLog('GET request success');
        return json.decode(response.body) as Map<String, dynamic>;
      }

      // 处理 token 过期情况
      if (_isTokenExpiredResponse(response)) {
        await _writeLog('Token expired detected in GET request');
        final newHeaders = await _handleTokenExpired();
        if (newHeaders != null) {
          await _writeLog('Retrying GET request with new token');
          final retryResponse = await http.get(
            url,
            headers: {...newHeaders, ...?headers},
          ).timeout(const Duration(seconds: 20));

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

  // 统一的 POST 请求方法
  Future<Map<String, dynamic>> postRequest(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    bool requiresHeaders = true,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    await _writeLog('POST request to: $endpoint');

    try {
      // 获取两种token
      final loginToken = await getLoginToken();
      final authData = await getToken();

      // 合并请求头
      final Map<String, String> finalHeaders = {
        if (requiresHeaders) 'Content-Type': 'application/json',
        if (loginToken != null) 'Authorization': loginToken,
        if (loginToken != null) 'X-Token-Type': 'login_token',
        if (authData != null) 'Auth-Data': authData,
        ...?headers,
      };

      final response = await http
          .post(
            url,
            headers: requiresHeaders ? finalHeaders : null,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 20));

      if (kDebugMode) {
        print("POST $baseUrl$endpoint response: ${response.body}");
      }

      if (response.statusCode == 200) {
        await _writeLog('POST request success');
        return json.decode(response.body) as Map<String, dynamic>;
      }

      // 处理 token 过期情况
      if (_isTokenExpiredResponse(response)) {
        await _writeLog('Token expired detected in POST request');
        final newHeaders = await _handleTokenExpired();
        if (newHeaders != null) {
          await _writeLog('Retrying POST request with new token');
          final retryHeaders = requiresHeaders ? {...newHeaders, 'Content-Type': 'application/json', ...?headers} : null;

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
