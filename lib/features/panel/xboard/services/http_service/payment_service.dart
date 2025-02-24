// services/payment_service.dart
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/domain_service.dart';

class PaymentService {
  final HttpService _httpService = HttpService();

  Future<Map<String, dynamic>> submitOrder(
    String tradeNo,
    String method,
    String accessToken,
  ) async {
    try {
      final response = await _httpService.postRequest(
        "/api/v1/user/order/checkout",
        {
          "trade_no": tradeNo,
          "method": "EPay", // 固定使用EPay支付方式
          "type": "alipay", // 支持 alipay / wxpay
        },
        headers: {'Authorization': accessToken},
      );

      if (response.containsKey('data') && response['data'] != null) {
        // 确保返回类型正确
        return Map<String, dynamic>.from(response['data']);
      }
      throw '获取支付链接失败';
    } catch (e) {
      if (e is String) {
        throw e;
      }
      throw '提交订单失败，请稍后重试';
    }
  }

  Future<List<dynamic>> getPaymentMethods(String accessToken) async {
    try {
      final response = await _httpService.getRequest(
        "/api/v1/user/order/getPaymentMethod",
        headers: {'Authorization': accessToken},
      );

      if (response.containsKey('data')) {
        final methods = response['data'] as List;
        if (methods.isNotEmpty) {
          // 确保返回的支付方式包含EPay
          final hasEPay = methods.any((method) => method is Map<String, dynamic> && method['payment'] == 'EPay');
          if (hasEPay) {
            return methods;
          }
        }
      }
      throw '暂无可用的支付方式';
    } catch (e) {
      if (e is String) {
        throw e;
      }
      throw '获取支付方式失败，请稍后重试';
    }
  }

  Future<void> openPaymentPage(String accessToken) async {
    try {
      // 获取当前域名
      final domain = await DomainService.fetchValidDomain();

      // 构建带有token的支付URL
      final Uri url = Uri.parse('$domain/index.php#/plan?token=$accessToken');

      // 在默认浏览器中打开
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('无法打开支付链接');
      }
    } catch (e) {
      throw '打开支付页面失败: $e';
    }
  }
}
