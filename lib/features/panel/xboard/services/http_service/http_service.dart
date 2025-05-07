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
  static const int maxRetries = 3;
  static const Duration requestTimeout = Duration(seconds: 20);

  HttpService._({SilentLoginCallback? silentLogin}) : _silentLogin = silentLogin;

  static HttpService get instance {
    if (_instance == null) {
      throw Exception('HttpService 未初始化');
    }
    return _instance!;
  }

  static Future<void> initialize({SilentLoginCallback? silentLogin}) async {
    _instance = HttpService._(silentLogin: silentLogin);
    await initializeDomain();
  }

  static Future<void> initializeDomain() async {
    int retryCount = 0;
    Exception? lastError;
    Duration retryDelay = const Duration(seconds: 3);

    while (retryCount < maxRetries) {
      try {
        if (kDebugMode) {
          print('正在初始化域名服务 (尝试 ${retryCount + 1}/$maxRetries)...');
        }

        baseUrl = await DomainService.fetchValidDomain();
        if (baseUrl.isNotEmpty) {
          if (kDebugMode) {
            print('域名初始化成功: $baseUrl');
          }
          return;
        }
      } catch (e) {
        lastError = e as Exception;
        if (kDebugMode) {
          print('域名初始化失败 (尝试 ${retryCount + 1}): $e');
        }

        // 记录错误日志
        final now = DateTime.now().toString().split('.').first;
        final logLine = '[HttpService] $now: 域名初始化失败 (尝试 ${retryCount + 1}): $e\n';
        try {
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/app_http.log');
          await file.writeAsString(logLine, mode: FileMode.append);
        } catch (logError) {
          if (kDebugMode) {
            print('写入日志失败: $logError');
          }
        }
      }

      retryCount++;
      if (retryCount < maxRetries) {
        if (kDebugMode) {
          print('等待 ${retryDelay.inSeconds} 秒后重试...');
        }
        await Future.delayed(retryDelay);
        retryDelay *= 2; // 指数退避
      }
    }

    final errorMessage = lastError?.toString() ?? '未知错误';
    throw Exception('域名初始化失败: $errorMessage');
  }

  Future<void> _writeLog(String message) async {
    final now = DateTime.now().toString().split('.').first;
    final logLine = '[HttpService] $now: $message\n';
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/app_http.log');
      await file.writeAsString(logLine, mode: FileMode.append);
    } catch (e) {
      if (kDebugMode) {
        print('写入日志失败: $e');
      }
    }
  }

  bool _isTokenExpiredResponse(http.Response response) {
    if (response.statusCode == 401) return true;
    try {
      final body = json.decode(response.body) as Map<String, dynamic>;
      final message = body['message']?.toString().toLowerCase() ?? '';
      return message.contains('未登录') || message.contains('登陆已过期') || (message.contains('token') && message.contains('过期'));
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, String>?> _handleTokenExpired() async {
    await _writeLog('Token 已过期，尝试静默登录');

    if (_isRefreshingToken) {
      await _writeLog('Token 刷新正在进行中，等待...');
      while (_isRefreshingToken) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      final authData = await getToken();
      if (authData != null) {
        return {
          'Authorization': authData,
        };
      }
      return null;
    }

    _isRefreshingToken = true;
    try {
      if (_silentLogin == null) {
        await _writeLog('未提供静默登录回调');
        return null;
      }

      final refreshed = await _silentLogin!();
      if (refreshed) {
        final authData = await getToken();
        if (authData != null) {
          await _writeLog('静默登录成功，获取新token');
          return {
            'Authorization': authData,
          };
        }
      }
      await _writeLog('静默登录失败');
      return null;
    } finally {
      _isRefreshingToken = false;
    }
  }

  Future<Map<String, dynamic>> getRequest(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('域名未初始化，请先调用 initialize()');
    }

    final url = Uri.parse('$baseUrl$endpoint');
    await _writeLog('发送 GET 请求: $endpoint');

    try {
      Map<String, String> finalHeaders = {'Accept': 'application/json', 'Connection': 'keep-alive', 'Cache-Control': 'no-cache'};

      final authData = await getToken();
      if (authData != null) {
        finalHeaders['Authorization'] = authData;
        if (endpoint == '/api/v1/user/info') {
          finalHeaders['X-Token-Type'] = 'auth_data';
        }
      }

      if (headers != null) {
        finalHeaders.addAll(headers);
      }

      final response = await http
          .get(
            url,
            headers: finalHeaders,
          )
          .timeout(requestTimeout);

      if (kDebugMode) {
        print("GET $baseUrl$endpoint 响应: ${response.body}");
      }

      if (response.statusCode == 200) {
        await _writeLog('GET 请求成功');
        try {
          return json.decode(response.body) as Map<String, dynamic>;
        } catch (e) {
          throw Exception('响应数据解析失败: $e');
        }
      }

      if (_isTokenExpiredResponse(response)) {
        await _writeLog('检测到 Token 过期');
        final newHeaders = await _handleTokenExpired();
        if (newHeaders != null) {
          await _writeLog('使用新 Token 重试请求');
          final retryResponse = await http.get(
            url,
            headers: {...newHeaders, ...?headers},
          ).timeout(requestTimeout);

          if (retryResponse.statusCode == 200) {
            await _writeLog('GET 重试请求成功');
            return json.decode(retryResponse.body) as Map<String, dynamic>;
          }
        }
      }

      await _writeLog('GET 请求失败: ${response.statusCode}, ${response.body}');
      throw Exception("请求失败: ${response.statusCode}, ${response.reasonPhrase}");
    } catch (e) {
      await _writeLog('GET 请求错误: $e');
      if (kDebugMode) {
        print('请求 $baseUrl$endpoint 时发生错误: $e');
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
    if (baseUrl.isEmpty) {
      await initializeDomain();
    }

    final url = Uri.parse('$baseUrl$endpoint');
    await _writeLog('POST request to: $endpoint');

    int retryCount = 0;
    Duration retryDelay = const Duration(seconds: 2);
    Exception? lastError;

    while (retryCount < maxRetries) {
      try {
        final client = http.Client();
        try {
          final Map<String, String> finalHeaders = {
            if (requiresHeaders) 'Content-Type': 'application/json',
            'User-Agent': 'Mozilla/5.0',
            'Accept': 'application/json',
            'Connection': 'close',
            ...?headers,
          };

          // 获取认证token
          final authData = await getToken();
          if (authData != null) {
            finalHeaders['Authorization'] = authData;
          }

          final response = await client
              .post(
                url,
                headers: finalHeaders,
                body: json.encode(body),
              )
              .timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            await _writeLog('POST request success');
            return json.decode(response.body) as Map<String, dynamic>;
          }

          // 处理token过期
          if (_isTokenExpiredResponse(response)) {
            await _writeLog('Token expired detected in POST request');
            final newHeaders = await _handleTokenExpired();
            if (newHeaders != null) {
              final retryResponse = await client
                  .post(
                    url,
                    headers: {...finalHeaders, ...newHeaders},
                    body: json.encode(body),
                  )
                  .timeout(const Duration(seconds: 15));

              if (retryResponse.statusCode == 200) {
                await _writeLog('POST retry with new token success');
                return json.decode(retryResponse.body) as Map<String, dynamic>;
              }
            }
          }

          // 处理其他错误
          final errorMsg = _parseErrorMessage(response);
          throw Exception(errorMsg);
        } finally {
          client.close();
        }
      } catch (e) {
        lastError = e as Exception;
        await _writeLog('POST request error (attempt ${retryCount + 1}): $e');

        if (e.toString().contains('HandshakeException')) {
          await initializeDomain();
          baseUrl = DomainService.baseUrl;
        }

        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(retryDelay);
          retryDelay *= 2; // 指数退避
          continue;
        }
      }
    }

    throw lastError ?? Exception('请求失败，请稍后重试');
  }

  String _parseErrorMessage(http.Response response) {
    try {
      final body = json.decode(response.body) as Map<String, dynamic>;
      return body['message']?.toString() ?? '未知错误';
    } catch (e) {
      return '服务器响应异常 (${response.statusCode})';
    }
  }
}
