// services/domain_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:async'; // 添加 Completer 导入
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:async/async.dart';

class DomainService {
  static const String initialDomain = 'https://www.starlinkvpn.cc';
  static const int maxRedirects = 5; // 最大重定向次数
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration responseTimeout = Duration(seconds: 30);

  // API域名列表 - 这些域名应该返回JSON格式的配置
  static const List<String> apiDomains = [
    'https://api.0101.pw',
    'https://api-bk0.pages.dev/index.json',
    'https://ceze2024.github.io/api',
    'https://api.0222.pw',
    'https://api.038y.xyz',
    'https://api.1231234567.xyz',
    'https://api.168168.pw',
    'https://api.168246.com',
    'https://api.168cp.in',
    'https://api.168cp.org',
    'https://api.168cp.top'
  ];

  static Future<String> fetchValidDomain() async {
    // 创建一个自定义的HttpClient来处理SSL证书验证
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // 这里可以添加证书指纹验证逻辑
        if (kDebugMode) {
          print('Certificate validation for $host:$port');
          print('Certificate: ${cert.pem}');
        }
        // 对于特定域名,我们可以验证证书指纹
        return true; // 临时允许所有证书,生产环境应该验证证书
      }
      ..connectionTimeout = connectionTimeout
      ..maxConnectionsPerHost = 5;

    // 首先尝试主域名
    try {
      if (await _checkDomainAccessibility(initialDomain, httpClient)) {
        if (kDebugMode) {
          print('Main domain is accessible: $initialDomain');
        }
        return initialDomain;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Main domain not accessible, trying API domains: $e');
      }
    }

    // 如果主域名不可访问,尝试API域名列表
    for (final apiDomain in apiDomains) {
      try {
        if (apiDomain.endsWith('index.json')) {
          // 对于返回JSON配置的域名,尝试获取可用域名列表
          final response = await _getWithRedirects(apiDomain, httpClient);
          if (response != null) {
            try {
              final List<dynamic> websites = json.decode(response) as List<dynamic>;
              for (final website in websites) {
                final Map<String, dynamic> websiteMap = website as Map<String, dynamic>;
                final String domain = websiteMap['url'] as String;

                if (await _checkDomainAccessibility(domain, httpClient)) {
                  if (kDebugMode) {
                    print('Valid domain found from config: $domain');
                  }
                  return domain;
                }
              }
            } catch (e) {
              if (kDebugMode) {
                print('Error parsing JSON from $apiDomain: $e');
              }
              continue;
            }
          }
        } else {
          // 直接检查API域名是否可用
          if (await _checkDomainAccessibility(apiDomain, httpClient)) {
            if (kDebugMode) {
              print('Valid API domain found: $apiDomain');
            }
            return apiDomain;
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error checking API domain $apiDomain: $e');
        }
        continue;
      }
    }

    throw Exception('No accessible domains found.');
  }

  static Future<bool> _checkDomainAccessibility(String domain, HttpClient httpClient) async {
    try {
      final response = await _getWithRedirects('$domain/api/v1/guest/comm/config', httpClient);
      return response != null;
    } catch (e) {
      if (kDebugMode) {
        print('Domain accessibility check failed for $domain: $e');
      }
      return false;
    }
  }

  // 处理重定向的GET请求
  static Future<String?> _getWithRedirects(String url, HttpClient httpClient, [int redirectCount = 0]) async {
    if (redirectCount >= maxRedirects) {
      if (kDebugMode) {
        print('Too many redirects for $url');
      }
      return null;
    }

    try {
      final uri = Uri.parse(url);
      final request = await httpClient.getUrl(uri);
      request.headers.add('User-Agent', 'Mozilla/5.0');

      final response = await request.close().timeout(responseTimeout);

      // 处理重定向
      if (response.statusCode >= 300 && response.statusCode < 400) {
        final location = response.headers.value('location');
        if (location != null) {
          // 确保重定向URL是完整的
          final redirectUrl = location.startsWith('http') ? location : '${uri.scheme}://${uri.host}${location.startsWith('/') ? location : '/$location'}';

          await response.drain<void>(); // 释放响应资源
          return _getWithRedirects(redirectUrl, httpClient, redirectCount + 1);
        }
      }

      if (response.statusCode == 200) {
        // 读取响应内容
        final completer = Completer<String>();
        final contents = StringBuffer();

        response.transform(utf8.decoder).listen(
              (data) => contents.write(data),
              onDone: () => completer.complete(contents.toString()),
              onError: (Object e) => completer.completeError(e),
              cancelOnError: true,
            );

        return completer.future.timeout(responseTimeout);
      }

      await response.drain<void>(); // 释放响应资源
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error during GET request to $url: $e');
      }
      return null;
    }
  }
}
