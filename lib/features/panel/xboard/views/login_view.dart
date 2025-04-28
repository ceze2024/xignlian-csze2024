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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 检查是否已经登录
      final isLoggedIn = ref.read(authProvider);
      if (isLoggedIn) {
        if (mounted) {
          context.go('/');
        }
        return;
      }

      // 尝试自动登录
      await _tryAutoLogin();
    });
  }

  Future<void> _tryAutoLogin() async {
    if (_autoLoginTried) return; // 防止重复尝试自动登录

    final loginViewModel = ref.read(loginViewModelProvider);
    final domainCheckViewModel = ref.read(domainCheckViewModelProvider);
    final prefs = await SharedPreferences.getInstance();
    final loggedOut = prefs.getBool('user_logged_out') ?? false;

    // 从 SharedPreferences 中获取保存的凭据
    final savedUsername = prefs.getString('saved_username') ?? '';
    final savedPassword = prefs.getString('saved_password') ?? '';
    final isRememberMe = prefs.getBool('is_remember_me') ?? true;

    // 如果保存了凭据且记住密码被选中
    final hasSavedCredentials = savedUsername.isNotEmpty && savedPassword.isNotEmpty && isRememberMe;

    if (domainCheckViewModel.isSuccess && hasSavedCredentials && !loggedOut) {
      setState(() {
        _autoLoginTried = true;
        _autoLoginFailed = false;
      });

      try {
        // 使用保存的凭据进行登录
        await loginViewModel.login(
          savedUsername,
          savedPassword,
          context,
          ref,
        );
        if (mounted) {
          context.go('/');
        }
      } catch (e) {
        if (!mounted) return;
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
