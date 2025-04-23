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
    if (email.isEmpty) {
      _showSnackbar(context, "请输入邮箱地址");
      return;
    }

    _isCountingDown = true;
    _countdownTime = 60;
    notifyListeners();

    try {
      final response = await _authService.sendVerificationCode(email, isForget: false);

      if (response["status"] == "success") {
        _showSnackbar(context, "验证码已发送至 $email");
      } else {
        _showSnackbar(context, response["message"]?.toString() ?? "发送验证码失败");
      }
    } catch (e) {
      _showSnackbar(context, "发送验证码失败，请稍后重试");
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
      final result = await _authService.register(
        email,
        password,
        inviteCode,
        emailCode,
      );

      if (result["status"] == "success") {
        _showSnackbar(context, "注册成功");
        if (context.mounted) {
          context.go('/login');
        }
      } else {
        String errorMessage = result["message"]?.toString() ?? "注册失败";
        // 处理常见的错误信息
        if (errorMessage.contains("email")) {
          errorMessage = "邮箱已被注册";
        } else if (errorMessage.contains("password")) {
          errorMessage = "密码不符合要求";
        } else if (errorMessage.contains("code")) {
          errorMessage = "验证码错误或已过期";
        } else if (errorMessage.contains("invite")) {
          errorMessage = "邀请码无效";
        }
        _showSnackbar(context, errorMessage);
      }
    } catch (e) {
      _showSnackbar(context, "注册失败，请稍后重试");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void _showSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
      backgroundColor: message.contains("成功") ? Colors.green : Colors.red,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
