// services/plan_service.dart
import 'package:hiddify/features/panel/xboard/models/plan_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service_provider.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';

class PlanService {
  final HttpService _httpService = HttpServiceProvider.instance;

  Future<List<Plan>> fetchPlanData(String accessToken) async {
    final result = await _httpService.getRequest(
      "/api/v1/user/plan/fetch",
    );
    return (result["data"] as List).cast<Map<String, dynamic>>().map((json) => Plan.fromJson(json)).toList();
  }
}
