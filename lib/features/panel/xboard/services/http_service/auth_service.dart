// services/auth_service.dart
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/domain_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AuthService {
  final HttpService _httpService = HttpService();

  // 写日志到本地文件
  Future<void> _writeLog(String message) async {
    final now = DateTime.now().toString().split('.').first;
    final logLine = '[AuthService] $now: $message\n';
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/app_login.log');
      await file.writeAsString(logLine, mode: FileMode.append);
    } catch (e) {
      // 忽略日志写入错误
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    await _writeLog('login() called, email: $email');
    try {
      await _writeLog('准备发起POST请求');
      final reqStart = DateTime.now();
      final result = await _httpService.postRequest(
        "/api/v1/passport/auth/login",
        {"email": email, "password": password},
        requiresHeaders: true,
      );
      final reqEnd = DateTime.now();
      await _writeLog('POST请求返回, 耗时: [33m${reqEnd.difference(reqStart).inMilliseconds}ms[0m');
      await _writeLog('POST响应内容: ${result.toString()}');

      // 同时保存 auth_data 和 token
      if (result['data'] != null) {
        if (result['data']['auth_data'] != null) {
          await _writeLog('准备保存auth_data token');
          await storeToken(result['data']['auth_data'].toString());
          await _writeLog('保存auth_data token完成');
        }
        if (result['data']['token'] != null) {
          await _writeLog('准备保存login token');
          await storeLoginToken(result['data']['token'].toString());
          await _writeLog('保存login token完成');
        }
      }
      await _writeLog('login() 返回正常');
      return result;
    } catch (e) {
      await _writeLog('login() 异常: $e');
      throw '密码错误，请重新输入';
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String inviteCode, String emailCode) async {
    return await _httpService.postRequest(
      "/api/v1/passport/auth/register",
      {
        "email": email,
        "password": password,
        "invite_code": inviteCode,
        "email_code": emailCode,
      },
    );
  }

  Future<Map<String, dynamic>> sendVerificationCode(String email, {bool isForget = false}) async {
    return await _httpService.postRequest(
      "/api/v1/passport/comm/sendEmailVerify",
      {'email': email, 'isforget': isForget ? 1 : 0},
    );
  }

  Future<Map<String, dynamic>> resetPassword(String email, String password, String emailCode) async {
    return await _httpService.postRequest(
      "/api/v1/passport/auth/forget",
      {
        "email": email,
        "password": password,
        "email_code": emailCode,
      },
    );
  }

  // 修改: 打开官网的方法
  static Future<void> openOfficialWebsite() async {
    try {
      // 获取当前可用域名
      String baseUrl = await DomainService.fetchValidDomain();

      final Uri url = Uri.parse(baseUrl);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('无法打开官网链接');
      }
    } catch (e) {
      throw '打开官网失败: $e';
    }
  }

  // 修改: 打开订阅页面的方法
  static Future<void> openSubscriptionPage() async {
    try {
      // 获取当前可用域名
      String baseUrl = await DomainService.fetchValidDomain();

      // 获取用于自动登录的token
      final loginToken = await getLoginToken();
      if (loginToken == null) {
        throw Exception('未登录，请先登录');
      }

      // 使用登录token构建URL
      final url = '$baseUrl/index.php#/plan?token=$loginToken';

      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('无法打开订阅页面');
      }
    } catch (e) {
      throw '打开订阅页面失败: $e';
    }
  }

  // 静默登录：用本地保存的邮箱密码自动登录
  static Future<bool> silentLogin() async {
    final creds = await getSavedCredentials();
    if (creds == null) return false;
    try {
      final authService = AuthService();
      await authService.login(creds['email']!, creds['password']!);
      return true;
    } catch (_) {
      return false;
    }
  }
}
