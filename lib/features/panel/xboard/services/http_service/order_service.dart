// services/order_service.dart
import 'package:hiddify/features/panel/xboard/models/order_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class OrderService {
  final HttpService _httpService = HttpService();

  Future<void> _writeLog(String message) async {
    final now = DateTime.now().toString().split('.').first;
    final logLine = '[OrderService] $now: $message\n';
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/app_login.log');
      await file.writeAsString(logLine, mode: FileMode.append);
    } catch (e) {}
  }

  Future<List<Order>> fetchUserOrders(String accessToken) async {
    await _writeLog('fetchUserOrders called, token: $accessToken');
    try {
      final result = await _httpService.getRequest(
        "/api/v1/user/order/fetch",
        headers: {
          'Authorization': accessToken,
          'X-Token-Type': 'login_token',
        },
      );

      if (result.containsKey("data")) {
        await _writeLog('fetchUserOrders success');
        final ordersJson = result["data"] as List;
        return ordersJson.map((json) => Order.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        await _writeLog('fetchUserOrders: no data, returning empty list');
        return []; // 如果没有订单数据，返回空列表
      }
    } catch (e) {
      await _writeLog('fetchUserOrders error: $e');
      throw '获取订单列表失败，请稍后重试';
    }
  }

  Future<Map<String, dynamic>> getOrderDetails(String tradeNo, String accessToken) async {
    await _writeLog('getOrderDetails called, tradeNo: $tradeNo');
    try {
      final result = await _httpService.getRequest(
        "/api/v1/user/order/detail?trade_no=$tradeNo",
        headers: {
          'Authorization': accessToken,
          'X-Token-Type': 'login_token',
        },
      );
      await _writeLog('getOrderDetails success');
      return result;
    } catch (e) {
      await _writeLog('getOrderDetails error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> cancelOrder(String tradeNo, String accessToken) async {
    await _writeLog('cancelOrder called, tradeNo: $tradeNo');
    try {
      final result = await _httpService.postRequest(
        "/api/v1/user/order/cancel",
        {"trade_no": tradeNo},
        headers: {
          'Authorization': accessToken,
          'X-Token-Type': 'login_token',
        },
      );
      await _writeLog('cancelOrder success');
      return result;
    } catch (e) {
      await _writeLog('cancelOrder error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createOrder(String accessToken, int planId, String period) async {
    await _writeLog('createOrder called, planId: $planId, period: $period');
    try {
      final result = await _httpService.postRequest(
        "/api/v1/user/order/save",
        {"plan_id": planId, "period": period},
        headers: {
          'Authorization': accessToken,
          'X-Token-Type': 'login_token',
        },
      );
      await _writeLog('createOrder success');
      return result;
    } catch (e) {
      await _writeLog('createOrder error: $e');
      rethrow;
    }
  }
}
