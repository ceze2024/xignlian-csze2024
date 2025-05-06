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

  static Future<String> fetchValidDomain() async {
    int retryCount = 0;
    const maxRetries = 3;
    Duration retryDelay = const Duration(seconds: 2);

    while (retryCount < maxRetries) {
      try {
        // 尝试主域名
        final mainDomainResult = await _tryMainDomain();
        if (mainDomainResult != null) {
          baseUrl = mainDomainResult;
          return mainDomainResult;
        }

        // 尝试备用域名
        final backupDomainResult = await _tryBackupDomains();
        if (backupDomainResult != null) {
          baseUrl = backupDomainResult;
          return backupDomainResult;
        }

        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(retryDelay);
          retryDelay *= 2; // 指数退避
        }
      } catch (e) {
        if (kDebugMode) {
          print('Attempt ${retryCount + 1} failed: $e');
        }
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(retryDelay);
          retryDelay *= 2;
        }
      }
    }

    throw Exception('无法访问任何可用域名，请检查网络连接或稍后重试');
  }

  static Future<String?> _tryMainDomain() async {
    final client = http.Client();
    try {
      final response = await client.get(
        Uri.parse('$initialDomain/api/v1/guest/comm/config'),
        headers: {'User-Agent': 'Mozilla/5.0', 'Accept': 'application/json', 'Connection': 'close'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        try {
          final dynamic data = json.decode(response.body);
          if (data is Map<String, dynamic>) {
            return initialDomain;
          }
        } catch (e) {
          if (kDebugMode) {
            print('Main domain JSON parse error: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Main domain access error: $e');
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
        headers: {'User-Agent': 'Mozilla/5.0', 'Accept': 'application/json', 'Connection': 'close'},
      ).timeout(const Duration(seconds: 10));

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
        print('Config file access error for $domain: $e');
      }
    }
    return null;
  }

  static Future<bool> _checkDomainAccessibility(String domain) async {
    try {
      final client = http.Client();
      try {
        final response = await client.get(
          Uri.parse('$domain/api/v1/guest/comm/config'),
          headers: {'User-Agent': 'Mozilla/5.0'},
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          try {
            final dynamic data = json.decode(response.body);
            return data is Map<String, dynamic>;
          } catch (e) {
            if (kDebugMode) {
              print('JSON parse error for $domain: $e');
            }
            return false;
          }
        }
        return false;
      } catch (e) {
        if (kDebugMode) {
          print('Domain accessibility check failed for $domain: $e');
        }
        return false;
      } finally {
        client.close();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Client creation error in accessibility check for $domain: $e');
      }
      return false;
    }
  }
}
