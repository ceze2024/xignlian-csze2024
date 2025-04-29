import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service_provider.dart';

class BalanceService {
  final HttpService _httpService = HttpServiceProvider.instance;
// 划转佣金到余额的方法
  Future<bool> transferCommission(
    String accessToken,
    int transferAmount,
  ) async {
    try {
      await _httpService.postRequest(
        '/api/v1/user/transfer',
        {'transfer_amount': transferAmount},
        headers: {'Authorization': accessToken}, // 需要用户的认证令牌
      );
      return true;
    } catch (e) {
      // 统一错误提示
      throw '佣金划转失败，请重试！（如有疑问请访问官网发起工单联系客服）';
    }
  }
}
