// services/domain_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DomainService {
  static const String initialDomain = 'https://starlink.168248.com';
  static const List<String> ossDomains = [
    'https://api.0101.pw',
    'https://api.starlinkvpn.cc',
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

  // 从返回的 JSON 中挑选一个可以正常访问的域名
  static Future<String> fetchValidDomain() async {
    // 首先尝试初始域名
    try {
      if (await _checkDomainAccessibility(initialDomain)) {
        if (kDebugMode) {
          print('Initial domain is accessible: $initialDomain');
        }
        return initialDomain;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Initial domain not accessible, trying OSS domains: $e');
      }
    }

    // 如果初始域名不可访问，则尝试 OSS 域名列表
    for (final ossDomain in ossDomains) {
      try {
        final response = await http.get(Uri.parse(ossDomain)).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final List<dynamic> websites = json.decode(response.body) as List<dynamic>;
          for (final website in websites) {
            final Map<String, dynamic> websiteMap = website as Map<String, dynamic>;
            final String domain = websiteMap['url'] as String;
            print(domain);
            if (await _checkDomainAccessibility(domain)) {
              if (kDebugMode) {
                print('Valid domain found: $domain');
              }
              return domain;
            }
          }
        } else {
          if (kDebugMode) {
            print('Failed to fetch websites.json: $ossDomain ${response.statusCode}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error fetching valid domain from $ossDomain: $e');
        }
      }
    }
    throw Exception('No accessible domains found.');
  }

  static Future<bool> _checkDomainAccessibility(String domain) async {
    try {
      final response = await http.get(Uri.parse('$domain/api/v1/guest/comm/config')).timeout(const Duration(seconds: 15));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
