// viewmodels/register_viewmodel.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/auth_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'dart:convert';

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

      // 根据服务器返回的 {"data":true} 格式判断是否成功
      if (response.containsKey("data") && response["data"] == true) {
        _showSnackbar(context, "验证码已发送至 $email");
      } else {
        String errorMessage = response["message"]?.toString() ?? "发送验证码失败";
        // 处理特定错误信息
        if (errorMessage.contains("已存在")) {
          _showSnackbar(context, "该邮箱已注册，请直接登录");
        } else if (errorMessage.contains("不存在")) {
          // 注册时不太可能出现这个错误，如果出现了也作相应处理
          _showSnackbar(context, "邮箱格式可能不正确，请检查");
        } else if (errorMessage.contains("不能为空")) {
          _showSnackbar(context, "验证码不能为空");
        } else if (errorMessage.contains("有误")) {
          _showSnackbar(context, "验证码错误，请重新输入");
        } else {
          _showSnackbar(context, errorMessage);
        }
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

      // 检查多种成功响应格式
      bool isSuccess = false;

      // 检查第一种成功格式: {"status": "success"}
      if (result.containsKey("status") && result["status"] == "success") {
        isSuccess = true;
      }

      // 检查第二种成功格式: {"data": true}
      if (!isSuccess && result.containsKey("data") && result["data"] == true) {
        isSuccess = true;
      }

      // 检查第三种成功格式: {"data": {"token": "...", "auth_data": "..."}}
      if (!isSuccess && result.containsKey("data") && result["data"] is Map) {
        final Map<dynamic, dynamic> data = result["data"] as Map<dynamic, dynamic>;
        if (data.containsKey("token") && data.containsKey("auth_data")) {
          isSuccess = true;

          // 保存认证数据
          await storeToken(data["auth_data"].toString());
          await storeLoginToken(data["token"].toString());
        }
      }

      if (isSuccess) {
        _showSnackbar(context, "注册成功");
        if (context.mounted) {
          context.go('/login');
        }
      } else {
        // 处理错误信息
        String errorMessage = "注册失败";

        if (result.containsKey("message")) {
          String message = result["message"].toString();

          if (message.contains("invalid")) {
            // 检查是否有详细的错误信息
            if (result.containsKey("errors") && result["errors"] is Map) {
              final errors = result["errors"] as Map;
              if (errors.containsKey("email")) {
                errorMessage = "邮箱格式不正确或已被注册";
              } else if (errors.containsKey("password")) {
                errorMessage = "密码必须大于8个字符";
              } else if (errors.containsKey("email_code")) {
                errorMessage = "验证码不能为空";
              } else if (errors.containsKey("invite_code")) {
                errorMessage = "邀请码无效";
              }
            }
          } else if (message.contains("验证码有误")) {
            errorMessage = "验证码错误，请重新输入";
          } else if (message.contains("邮箱已存在")) {
            errorMessage = "该邮箱已注册，请直接登录";
          } else if (message.contains("不存在")) {
            errorMessage = "邮箱格式可能不正确，请检查";
          } else {
            errorMessage = message;
          }
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
