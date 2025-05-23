import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:hiddify/features/panel/xboard/models/plan_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/order_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/payment_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/plan_service.dart';
import 'package:hiddify/features/panel/xboard/services/subscription.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/domain_service.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

class PurchaseService {
  Future<List<Plan>> fetchPlanData() async {
    final loginToken = await getLoginToken();
    if (loginToken == null) {
      print("No access token found.");
      return [];
    }

    return await PlanService().fetchPlanData(loginToken);
  }

  Future<void> addSubscription(
    BuildContext context,
    String accessToken,
    WidgetRef ref,
    Function showSnackbar,
  ) async {
    Subscription.updateSubscription(context, ref);
  }

  final OrderService _orderService = OrderService();
  final PaymentService _paymentService = PaymentService();

  Future<Map<String, dynamic>?> createOrder(int planId, String period, String accessToken) async {
    return await _orderService.createOrder(accessToken, planId, period);
  }

  Future<List<dynamic>> getPaymentMethods(String accessToken) async {
    return await _paymentService.getPaymentMethods(accessToken);
  }

  Future<Map<String, dynamic>> submitOrder(String tradeNo, String method, String accessToken) async {
    return await _paymentService.submitOrder(tradeNo, method, accessToken);
  }

  Future<void> openPurchasePage() async {
    try {
      final domain = await DomainService.fetchValidDomain();
      final token = await getLoginToken();
      if (token == null) {
        throw Exception('未登录，请先登录');
      }

      final Uri url = Uri.parse('$domain/index.php#/plan?token=$token');

      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('无法打开链接');
      }
    } catch (e) {
      rethrow;
    }
  }
}
