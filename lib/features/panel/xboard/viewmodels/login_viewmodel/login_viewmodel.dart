// viewmodels/login_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:hiddify/features/panel/xboard/services/auth_provider.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/auth_service.dart';
import 'package:hiddify/features/panel/xboard/services/subscription.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isRememberMe = false;
  bool get isRememberMe => _isRememberMe;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginViewModel({required AuthService authService}) : _authService = authService {
    _loadSavedCredentials();
  }

  Future<void> _writeLog(String message) async {
    final now = DateTime.now().toString().split('.').first;
    final logLine = '[LoginViewModel] $now: $message\n';
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/app_login.log');
      await file.writeAsString(logLine, mode: FileMode.append);
    } catch (e) {}
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    usernameController.text = prefs.getString('saved_username') ?? '';
    passwordController.text = prefs.getString('saved_password') ?? '';
    _isRememberMe = prefs.getBool('is_remember_me') ?? true;
    await _writeLog('加载本地凭证: username=${usernameController.text}, password=${passwordController.text.isNotEmpty}, rememberMe=$_isRememberMe');
    notifyListeners();
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_isRememberMe) {
      await prefs.setString('saved_username', usernameController.text);
      await prefs.setString('saved_password', passwordController.text);
      await _writeLog('保存凭证: username=${usernameController.text}, password=${passwordController.text.isNotEmpty}');
    } else {
      await prefs.remove('saved_username');
      await prefs.remove('saved_password');
      await _writeLog('移除本地凭证');
    }
    await prefs.setBool('is_remember_me', _isRememberMe);
  }

  void toggleRememberMe(bool value) {
    _isRememberMe = value;
    notifyListeners();
  }

  Future<void> login(
    String email,
    String password,
    BuildContext context,
    WidgetRef ref,
  ) async {
    _isLoading = true;
    notifyListeners();
    await _writeLog('开始登录: email=$email');
    try {
      final result = await _authService.login(email, password);
      String? authData;
      String? token;
      void findAuthData(Map<String, dynamic> json) {
        json.forEach((key, value) {
          if (key == 'auth_data' && value is String) {
            authData = value;
          }
          if (key == 'token' && value is String) {
            token = value;
          }
          if (value is Map<String, dynamic>) {
            findAuthData(value);
          }
        });
      }

      findAuthData(result);
      if (authData != null && token != null) {
        await storeToken(authData!);
        await _writeLog('保存token: $authData');
        await _saveCredentials();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('user_logged_out', false);
        await _writeLog('登录成功，user_logged_out=false');
        await Subscription.updateSubscription(context, ref);
        ref.read(authProvider.notifier).state = true;
        await _writeLog('登录流程结束，已设置authProvider为true');
      } else {
        await _writeLog('登录失败，未获取到token或authData');
        throw Exception("Invalid authentication data.");
      }
    } catch (e) {
      await _writeLog('登录异常: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
