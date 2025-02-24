// services/auth_service.dart
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/domain_service.dart';

class AuthService {
  final HttpService _httpService = HttpService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final result = await _httpService.postRequest(
        "/api/v1/passport/auth/login",
        {"email": email, "password": password},
        requiresHeaders: true,
      );

      // 同时保存 auth_data 和 token
      if (result['data'] != null) {
        if (result['data']['auth_data'] != null) {
          await storeToken(result['data']['auth_data']); // 保存用于API认证的token
        }
        if (result['data']['token'] != null) {
          await storeLoginToken(result['data']['token']); // 保存用于自动登录的token
        }
      }

      return result;
    } catch (e) {
      // 转换错误信息为用户友好的提示
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

  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    return await _httpService.postRequest(
      "/api/v1/passport/comm/sendEmailVerify",
      {'email': email},
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
}
