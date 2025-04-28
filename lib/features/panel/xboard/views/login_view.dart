// views/login_view.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/material.dart' show Scaffold, AppBar, Colors, Theme, Icons;
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/auth_service.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/login_viewmodel/login_viewmodel.dart';
import 'package:hiddify/features/panel/xboard/views/domain_check_indicator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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

  // 写日志到本地文件
  Future<void> _writeLog(String message) async {
    final now = DateTime.now().toString().split('.').first;
    final logLine = '$now: $message\n';
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/app_login.log');
      await file.writeAsString(logLine, mode: FileMode.append);
    } catch (e) {
      // 忽略日志写入错误
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAutoLogin();
  }

  Future<void> _initializeAutoLogin() async {
    final loginViewModel = ref.read(loginViewModelProvider);
    final domainCheckViewModel = ref.read(domainCheckViewModelProvider);
    final prefs = await SharedPreferences.getInstance();
    final isLoggedOut = prefs.getBool('user_logged_out') ?? false;

    await _writeLog('自动登录初始化检查:');
    await _writeLog('domainCheckViewModel.isSuccess: [32m${domainCheckViewModel.isSuccess}[0m');
    await _writeLog('username: ${loginViewModel.usernameController.text}');
    await _writeLog('password: ${loginViewModel.passwordController.text.isNotEmpty}');
    await _writeLog('_autoLoginTried: $_autoLoginTried');
    await _writeLog('isLoggedOut: $isLoggedOut');

    // 如果 domainCheckViewModel 已经是成功状态，直接尝试自动登录
    if (domainCheckViewModel.isSuccess && !_autoLoginTried) {
      _checkAutoLogin();
    }
  }

  Future<void> _checkAutoLogin() async {
    final loginViewModel = ref.read(loginViewModelProvider);
    final domainCheckViewModel = ref.read(domainCheckViewModelProvider);
    final prefs = await SharedPreferences.getInstance();
    final isLoggedOut = prefs.getBool('user_logged_out') ?? false;

    await _writeLog('尝试自动登录:');
    await _writeLog('domainCheckViewModel.isSuccess: ${domainCheckViewModel.isSuccess}');
    await _writeLog('username: ${loginViewModel.usernameController.text}');
    await _writeLog('password: ${loginViewModel.passwordController.text.isNotEmpty}');
    await _writeLog('_autoLoginTried: $_autoLoginTried');
    await _writeLog('isLoggedOut: $isLoggedOut');

    if (domainCheckViewModel.isSuccess && loginViewModel.usernameController.text.isNotEmpty && loginViewModel.passwordController.text.isNotEmpty && !_autoLoginTried && !isLoggedOut) {
      await _writeLog('满足自动登录条件，开始自动登录');
      _autoLoginTried = true;
      if (mounted) {
        setState(() {
          _autoLoginFailed = false;
        });
      }
      try {
        await _writeLog('loginViewModel.login 开始: ${DateTime.now()}');
        await loginViewModel.login(
          loginViewModel.usernameController.text,
          loginViewModel.passwordController.text,
          context as BuildContext,
          ref,
        );
        await _writeLog('loginViewModel.login 返回: ${DateTime.now()}');
        if (mounted) {
          await _writeLog('跳转主页前: ${DateTime.now()}');
          context.go('/');
          await _writeLog('跳转主页后: ${DateTime.now()}');
        }
      } catch (e) {
        await _writeLog('自动登录失败: $e');
        if (mounted) {
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
    } else {
      await _writeLog('不满足自动登录条件');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginViewModel = ref.watch(loginViewModelProvider);
    final t = ref.watch(translationsProvider);
    final domainCheckViewModel = ref.watch(domainCheckViewModelProvider);

    // 只在 build 方法中监听 domainCheckViewModel 状态变化，确保自动登录只触发一次
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen(domainCheckViewModelProvider, (previous, next) async {
        if (next.isSuccess && !_autoLoginTried) {
          await _writeLog('domainCheckViewModel 状态变化: ${next.isSuccess}');
          _checkAutoLogin();
        }
      });
    });

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
                      // 日志显示区域已移除
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
                            onChanged: (bool? value) {
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
                                  await _writeLog('点击登录按钮: ${DateTime.now()}');
                                  final email = loginViewModel.usernameController.text;
                                  final password = loginViewModel.passwordController.text;
                                  try {
                                    await _writeLog('loginViewModel.login 开始: ${DateTime.now()}');
                                    await loginViewModel.login(
                                      email,
                                      password,
                                      context as BuildContext,
                                      ref,
                                    );
                                    await _writeLog('loginViewModel.login 返回: ${DateTime.now()}');
                                    if (context.mounted) {
                                      await _writeLog('跳转主页前: ${DateTime.now()}');
                                      context.go('/');
                                      await _writeLog('跳转主页后: ${DateTime.now()}');
                                    }
                                  } catch (e) {
                                    await _writeLog('登录失败: $e');
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
