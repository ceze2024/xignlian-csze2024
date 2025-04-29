import 'package:hiddify/features/panel/xboard/services/http_service/auth_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';

class HttpServiceProvider {
  static AuthService? _authService;
  static HttpService? _httpService;

  static Future<void> initialize() async {
    await HttpService.initializeDomain();
    _authService = AuthService();
    await HttpService.initialize(silentLogin: _authService!.silentLogin);
    _httpService = HttpService.instance;
  }

  static HttpService get instance {
    if (_httpService == null) {
      throw Exception('HttpServiceProvider not initialized');
    }
    return _httpService!;
  }

  static AuthService get auth {
    if (_authService == null) {
      throw Exception('HttpServiceProvider not initialized');
    }
    return _authService!;
  }
}
