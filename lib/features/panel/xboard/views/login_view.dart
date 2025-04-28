// views/login_view.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/panel/xboard/services/auth_provider.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/auth_service.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/login_viewmodel/login_viewmodel.dart';
import 'package:hiddify/features/panel/xboard/views/domain_check_indicator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final loginViewModelProvider = ChangeNotifierProvider((ref) {
  return LoginViewModel(
    authService: AuthService(),
  );
});

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _autoLoginTried = false;
  bool _autoLoginFailed = false;

  @override
  void initState() {
    super.initState();
    print('LoginPage initState 开始');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('LoginPage postFrameCallback 开始');
      try {
        // 检查是否已经登录
        final isLoggedIn = ref.read(authProvider);
        print('当前登录状态: $isLoggedIn');
        if (isLoggedIn) {
          print('用户已登录，跳转到首页');
          if (mounted) {
            context.go('/');
          }
          return;
        }

        // 从 SharedPreferences 中获取自动登录尝试状态
        final prefs = await SharedPreferences.getInstance();
        _autoLoginTried = prefs.getBool('auto_login_tried') ?? false;
        print('自动登录尝试状态: $_autoLoginTried');

        // 监听域名检查状态
        print('开始监听域名检查状态');
        ref.listen(domainCheckViewModelProvider, (previous, current) {
          print('域名检查状态变化:');
          print('之前状态: ${previous?.isSuccess}');
          print('当前状态: ${current.isSuccess}');
          print('检查中: ${current.isChecking}');
          print('重试次数: ${current.retryCount}');

          if (current.isSuccess && !_autoLoginTried) {
            print('域名检查成功，准备自动登录');
            _tryAutoLogin();
          }
        });
      } catch (e) {
        print('初始化错误: $e');
        if (mounted) {
          _showErrorSnackbar(
            context,
            "初始化失败，请重试。",
            Colors.red,
          );
        }
      }
    });
  }

  Future<void> _tryAutoLogin() async {
    print('开始尝试自动登录');
    if (_autoLoginTried) {
      print('已经尝试过自动登录，跳过');
      return;
    }

    try {
      print('获取登录视图模型');
      final loginViewModel = ref.read(loginViewModelProvider);
      print('获取 SharedPreferences 实例');
      final prefs = await SharedPreferences.getInstance();
      print('获取用户登出状态');
      final loggedOut = prefs.getBool('user_logged_out') ?? false;

      // 从 SharedPreferences 中获取保存的凭据
      print('获取保存的用户凭据');
      final savedUsername = prefs.getString('saved_username') ?? '';
      final savedPassword = prefs.getString('saved_password') ?? '';
      final isRememberMe = prefs.getBool('is_remember_me') ?? true;

      print('自动登录凭据检查:');
      print('用户名: ${savedUsername.isNotEmpty ? "已保存" : "未保存"}');
      print('密码: ${savedPassword.isNotEmpty ? "已保存" : "未保存"}');
      print('记住密码: $isRememberMe');
      print('已登出: $loggedOut');

      // 如果保存了凭据且记住密码被选中
      final hasSavedCredentials = savedUsername.isNotEmpty && savedPassword.isNotEmpty && isRememberMe;

      if (hasSavedCredentials && !loggedOut) {
        print('开始执行自动登录');
        setState(() {
          _autoLoginTried = true;
          _autoLoginFailed = false;
        });

        // 保存自动登录尝试状态
        print('保存自动登录尝试状态到 SharedPreferences');
        await prefs.setBool('auto_login_tried', true);
        print('已保存自动登录尝试状态');

        try {
          // 使用保存的凭据进行登录
          print('开始调用登录接口');
          print('用户名长度: ${savedUsername.length}');
          print('密码长度: ${savedPassword.length}');
          await loginViewModel.login(
            savedUsername,
            savedPassword,
            context,
            ref,
          );
          print('登录成功');
          if (mounted) {
            print('准备跳转到首页');
            context.go('/');
          }
        } catch (e, stackTrace) {
          print('登录过程出错:');
          print('错误类型: ${e.runtimeType}');
          print('错误信息: $e');
          print('堆栈跟踪:');
          print(stackTrace);
          if (!mounted) {
            print('组件已卸载，无法显示错误提示');
            return;
          }
          setState(() {
            _autoLoginFailed = true;
          });
          _showErrorSnackbar(
            context,
            "自动登录失败，请手动登录。",
            Colors.red,
          );
        }
      } else {
        print('自动登录条件不满足:');
        print('hasSavedCredentials: $hasSavedCredentials');
        print('loggedOut: $loggedOut');
      }
    } catch (e, stackTrace) {
      print('自动登录过程出错:');
      print('错误类型: ${e.runtimeType}');
      print('错误信息: $e');
      print('堆栈跟踪:');
      print(stackTrace);
      if (!mounted) {
        print('组件已卸载，无法显示错误提示');
        return;
      }
      setState(() {
        _autoLoginFailed = true;
      });
      _showErrorSnackbar(
        context,
        "自动登录失败，请手动登录。",
        Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginViewModel = ref.watch(loginViewModelProvider);
    final t = ref.watch(translationsProvider);
    final domainCheckViewModel = ref.watch(domainCheckViewModelProvider);
    return Scaffold(
      appBar: AppBar(
        // title: const Text('Login'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: DomainCheckIndicator(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth > 600 ? 500 : constraints.maxWidth * 0.9,
                ),
                child: Form(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (_autoLoginTried && loginViewModel.isLoading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('正在自动登录...'),
                              ],
                            ),
                          ),
                        ),
                      if (_autoLoginFailed)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Center(
                            child: Text(
                              '自动登录失败，请手动登录。',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      Icon(
                        Icons.person,
                        size: 50,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 20),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: t.login.welcome,
                              style: TextStyle(
                                fontSize: constraints.maxWidth > 600 ? 32 : 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const TextSpan(
                              text: ' ',
                            ),
                            TextSpan(
                              text: t.general.appTitle,
                              style: TextStyle(
                                fontSize: constraints.maxWidth > 600 ? 32 : 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: loginViewModel.usernameController,
                        decoration: InputDecoration(
                          labelText: t.login.username,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: loginViewModel.passwordController,
                        decoration: InputDecoration(
                          labelText: t.login.password,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Checkbox(
                            value: loginViewModel.isRememberMe,
                            onChanged: (value) {
                              loginViewModel.toggleRememberMe(value ?? false);
                            },
                          ),
                          Text(t.login.rememberMe),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (loginViewModel.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        ElevatedButton(
                          onPressed: domainCheckViewModel.isSuccess
                              ? () async {
                                  final email = loginViewModel.usernameController.text;
                                  final password = loginViewModel.passwordController.text;
                                  try {
                                    await loginViewModel.login(
                                      email,
                                      password,
                                      context,
                                      ref,
                                    );
                                    if (context.mounted) {
                                      context.go('/');
                                    }
                                  } catch (e) {
                                    _showErrorSnackbar(
                                      context,
                                      "${t.login.loginErr}: $e",
                                      Colors.red,
                                    );
                                  }
                                }
                              : null, // 禁用按钮，直到连通性检查通过
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            t.login.loginButton,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              context.go('/forget-password');
                            },
                            child: Text(
                              t.login.forgotPassword,
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.go('/register');
                            },
                            child: Text(
                              t.login.register,
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await AuthService.openOfficialWebsite();
                            } catch (e) {
                              _showErrorSnackbar(
                                context,
                                e.toString(),
                                Colors.red,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '打开官网',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
