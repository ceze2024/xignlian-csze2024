// viewmodels/register_viewmodel.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/auth_service.dart';

class RegisterViewModel extends ChangeNotifier {
  final AuthService _authService;
  // 添加 FormKey
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isCountingDown = false;
  bool get isCountingDown => _isCountingDown;

  int _countdownTime = 60;
  int get countdownTime => _countdownTime;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController inviteCodeController = TextEditingController();
  final TextEditingController emailCodeController = TextEditingController();

  RegisterViewModel({required AuthService authService}) : _authService = authService;

  Future<void> sendVerificationCode(BuildContext context) async {
    final email = emailController.text.trim();
    _isCountingDown = true;
    _countdownTime = 60;
    notifyListeners();

    try {
      await _authService.sendVerificationCode(email);
    } catch (e) {
      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('发送验证码失败，请稍后重试'),
          backgroundColor: Colors.red,
        ),
      );
      _isCountingDown = false;
      _countdownTime = 60;
      notifyListeners();
      return;
    }

    // 倒计时逻辑
    while (_countdownTime > 0) {
      await Future.delayed(const Duration(seconds: 1));
      _countdownTime--;
      notifyListeners();
    }

    _isCountingDown = false;
    notifyListeners();
  }

  Future<void> register(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final inviteCode = inviteCodeController.text.trim();
    final emailCode = emailCodeController.text.trim();

    try {
      await _authService.register(email, password, inviteCode, emailCode);
      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (context.mounted) {
        // 显示错误提示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('注册失败，请检查信息是否正确'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    inviteCodeController.dispose();
    emailCodeController.dispose();
    super.dispose();
  }
}
