// services/domain_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DomainService {
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
    // 首先尝试主域名
    try {
      final client = http.Client();
      final response = await client.get(
        Uri.parse('$initialDomain/api/v1/guest/comm/config'),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 10));
      client.close();

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Main domain is accessible: $initialDomain');
        }
        return initialDomain;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Main domain not accessible: $e');
      }
    }

    // 尝试备用域名列表
    for (final domain in ossDomains) {
      try {
        if (domain.endsWith('index.json')) {
          // 尝试从配置文件获取域名列表
          final client = http.Client();
          final response = await client.get(
            Uri.parse(domain),
            headers: {'User-Agent': 'Mozilla/5.0'},
          ).timeout(const Duration(seconds: 10));
          client.close();

          if (response.statusCode == 200) {
            try {
              final List<dynamic> websites = json.decode(response.body) as List<dynamic>;
              for (final website in websites) {
                if (website is! Map<String, dynamic>) continue;
                final String? url = website['url'] as String?;
                if (url == null || url.isEmpty) continue;

                if (await _checkDomainAccessibility(url)) {
                  if (kDebugMode) {
                    print('Valid domain found from config: $url');
                  }
                  return url;
                }
              }
            } catch (e) {
              if (kDebugMode) {
                print('Error parsing JSON from $domain: $e');
              }
            }
          }
        } else {
          // 直接检查域名是否可用
          if (await _checkDomainAccessibility(domain)) {
            if (kDebugMode) {
              print('Valid domain found: $domain');
            }
            return domain;
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error checking domain $domain: $e');
        }
        continue;
      }
    }

    throw Exception('No accessible domains found');
  }

  static Future<bool> _checkDomainAccessibility(String domain) async {
    try {
      final client = http.Client();
      final response = await client.get(
        Uri.parse('$domain/api/v1/guest/comm/config'),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 10));
      client.close();

      if (response.statusCode == 200) {
        try {
          final dynamic data = json.decode(response.body);
          return data is Map<String, dynamic>;
        } catch (_) {
          return false;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
