// services/http_service.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/domain_service.dart';
import 'package:http/http.dart' as http;

class HttpService {
  static String baseUrl = ''; // 替换为你的实际基础 URL
  // 初始化服务并设置动态域名
  static Future<void> initialize() async {
    baseUrl = await DomainService.fetchValidDomain();
  }

  // 统一的 GET 请求方法
  Future<Map<String, dynamic>> getRequest(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');

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
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception("GET request to $baseUrl$endpoint failed: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during GET request to $baseUrl$endpoint: $e');
      }
      rethrow;
    }
  }

  // 统一的 POST 请求方法

  // 统一的 POST 请求方法，增加 requiresHeaders 开关
  Future<Map<String, dynamic>> postRequest(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    bool requiresHeaders = true, // 新增开关参数，默认需要 headers
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');

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
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception("POST request to $baseUrl$endpoint failed: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during POST request to $baseUrl$endpoint: $e');
      }
      rethrow;
    }
  }

  // POST 请求方法，不包含 headers
  Future<Map<String, dynamic>> postRequestWithoutHeaders(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http
          .post(
            url,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 20)); // 设置超时时间

      if (kDebugMode) {
        print("POST $baseUrl$endpoint without headers response: ${response.body}");
      }
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception("POST request to $baseUrl$endpoint failed: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during POST request without headers to $baseUrl$endpoint: $e');
      }
      rethrow;
    }
  }
}
