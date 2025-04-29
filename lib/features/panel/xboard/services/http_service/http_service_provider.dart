import 'package:hiddify/features/panel/xboard/services/http_service/auth_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';

class HttpServiceProvider {
  static late final AuthService _authService;
  static late final HttpService _httpService;

  static void initialize() {
    _authService = AuthService();
    _httpService = HttpService(_authService.silentLogin);
  }

  static HttpService get instance {
    return _httpService;
  }

  static AuthService get auth {
    return _authService;
  }
}
