// services/payment_service.dart
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/domain_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PaymentService {
  final HttpService _httpService = HttpServiceProvider.instance;

  Future<void> _writeLog(String message) async {
    final now = DateTime.now().toString().split('.').first;
    final logLine = '[PaymentService] $now: $message\n';
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/app_login.log');
      await file.writeAsString(logLine, mode: FileMode.append);
    } catch (e) {}
  }

  Future<Map<String, dynamic>> submitOrder(
    String tradeNo,
    String method,
    String accessToken,
  ) async {
    await _writeLog('submitOrder called, tradeNo: $tradeNo, method: $method');
    try {
      final response = await _httpService.postRequest(
        "/api/v1/user/order/checkout",
        {
          "trade_no": tradeNo,
          "method": "EPay", // 固定使用EPay支付方式
          "type": "alipay", // 支持 alipay / wxpay
        },
        headers: {
          'Authorization': accessToken,
          'X-Token-Type': 'login_token',
        },
      );

      if (response.containsKey('data') && response['data'] != null) {
        await _writeLog('submitOrder success');
        if (response['data'] is Map<String, dynamic>) {
          return response['data'] as Map<String, dynamic>;
        }
        return Map<String, dynamic>.from(response['data'] as Map);
      }
      await _writeLog('submitOrder failed: no data in response');
      throw '获取支付链接失败';
    } catch (e) {
      await _writeLog('submitOrder error: $e');
      if (e is String) {
        throw e;
      }
      throw '提交订单失败，请稍后重试';
    }
  }

  Future<List<dynamic>> getPaymentMethods(String accessToken) async {
    await _writeLog('getPaymentMethods called');
    try {
      final response = await _httpService.getRequest(
        "/api/v1/user/order/getPaymentMethod",
        headers: {
          'Authorization': accessToken,
          'X-Token-Type': 'login_token',
        },
      );

      if (response.containsKey('data')) {
        final methods = response['data'] as List;
        if (methods.isNotEmpty) {
          // 确保返回的支付方式包含EPay
          final hasEPay = methods.any((method) => method is Map<String, dynamic> && method['payment'] == 'EPay');
          if (hasEPay) {
            await _writeLog('getPaymentMethods success');
            return methods;
          }
        }
      }
      await _writeLog('getPaymentMethods failed: no valid payment methods');
      throw '暂无可用的支付方式';
    } catch (e) {
      await _writeLog('getPaymentMethods error: $e');
      if (e is String) {
        throw e;
      }
      throw '获取支付方式失败，请稍后重试';
    }
  }

  Future<void> openPaymentPage(String accessToken) async {
    await _writeLog('openPaymentPage called');
    try {
      // 获取当前域名
      final domain = await DomainService.fetchValidDomain();
      await _writeLog('openPaymentPage got domain: $domain');

      // 构建带有token的支付URL
      final Uri url = Uri.parse('$domain/index.php#/plan?token=$accessToken');

      // 在默认浏览器中打开
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        await _writeLog('openPaymentPage failed: cannot launch URL');
        throw Exception('无法打开支付链接');
      }
      await _writeLog('openPaymentPage success');
    } catch (e) {
      await _writeLog('openPaymentPage error: $e');
      throw '打开支付页面失败: $e';
    }
  }
}
