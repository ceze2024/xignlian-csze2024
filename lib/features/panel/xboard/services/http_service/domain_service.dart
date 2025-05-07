// services/domain_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DomainService {
  static String baseUrl = '';
  static const String initialDomain = 'https://www.starlinkvpn.cc';
  static const List<String> ossDomains = [
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

  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration totalTimeout = Duration(seconds: 30);

  static Future<String> fetchValidDomain() async {
    int retryCount = 0;
    const maxRetries = 3;
    Duration retryDelay = const Duration(seconds: 3);
    List<String> errors = [];

    while (retryCount < maxRetries) {
      try {
        // 尝试主域名
        if (kDebugMode) {
          print('正在尝试主域名...');
        }
        final mainDomainResult = await _tryMainDomain();
        if (mainDomainResult != null) {
          baseUrl = mainDomainResult;
          return mainDomainResult;
        }

        // 尝试备用域名
        if (kDebugMode) {
          print('正在尝试备用域名...');
        }
        final backupDomainResult = await _tryBackupDomains();
        if (backupDomainResult != null) {
          baseUrl = backupDomainResult;
          return backupDomainResult;
        }

        retryCount++;
        if (retryCount < maxRetries) {
          if (kDebugMode) {
            print('尝试失败，等待 ${retryDelay.inSeconds} 秒后重试...');
          }
          await Future.delayed(retryDelay);
          retryDelay *= 2; // 指数退避
        }
      } catch (e) {
        errors.add(e.toString());
        if (kDebugMode) {
          print('尝试 ${retryCount + 1} 失败: $e');
        }
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(retryDelay);
          retryDelay *= 2;
        }
      }
    }

    final errorMessage = errors.isNotEmpty ? '错误详情: ${errors.join(", ")}' : '所有域名均无法访问';
    throw Exception('无法访问任何可用域名，请检查网络连接或稍后重试。\n$errorMessage');
  }

  static Future<String?> _tryMainDomain() async {
    final client = http.Client();
    try {
      final response = await client.get(
        Uri.parse('$initialDomain/api/v1/guest/comm/config'),
        headers: {'User-Agent': 'Mozilla/5.0', 'Accept': 'application/json', 'Connection': 'keep-alive', 'Cache-Control': 'no-cache'},
      ).timeout(connectionTimeout);

      if (response.statusCode == 200) {
        try {
          final dynamic data = json.decode(response.body);
          if (data is Map<String, dynamic>) {
            return initialDomain;
          }
        } catch (e) {
          if (kDebugMode) {
            print('主域名 JSON 解析错误: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('主域名访问错误: $e');
      }
    } finally {
      client.close();
    }
    return null;
  }

  static Future<String?> _tryBackupDomains() async {
    for (final domain in ossDomains) {
      final client = http.Client();
      try {
        if (domain.endsWith('index.json')) {
          final configResult = await _tryConfigFile(domain, client);
          if (configResult != null) {
            return configResult;
          }
        } else {
          if (await _checkDomainAccessibility(domain)) {
            return domain;
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('备用域名 $domain 访问错误: $e');
        }
      } finally {
        client.close();
      }
    }
    return null;
  }

  static Future<String?> _tryConfigFile(String domain, http.Client client) async {
    try {
      final response = await client.get(
        Uri.parse(domain),
        headers: {'User-Agent': 'Mozilla/5.0', 'Accept': 'application/json', 'Connection': 'keep-alive', 'Cache-Control': 'no-cache'},
      ).timeout(connectionTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> websites = json.decode(response.body) as List<dynamic>;
        for (final website in websites) {
          if (website is Map<String, dynamic>) {
            final String? url = website['url'] as String?;
            if (url != null && url.isNotEmpty && await _checkDomainAccessibility(url)) {
              return url;
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('配置文件访问错误 $domain: $e');
      }
    }
    return null;
  }

  static Future<bool> _checkDomainAccessibility(String domain) async {
    final client = http.Client();
    try {
      final response = await client.get(
        Uri.parse('$domain/api/v1/guest/comm/config'),
        headers: {'User-Agent': 'Mozilla/5.0', 'Accept': 'application/json', 'Connection': 'keep-alive', 'Cache-Control': 'no-cache'},
      ).timeout(connectionTimeout);

      if (response.statusCode == 200) {
        try {
          final dynamic data = json.decode(response.body);
          return data is Map<String, dynamic>;
        } catch (e) {
          if (kDebugMode) {
            print('域名 $domain JSON 解析错误: $e');
          }
          return false;
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('域名可访问性检查失败 $domain: $e');
      }
      return false;
    } finally {
      client.close();
    }
  }
}
