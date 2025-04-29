import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hiddify/core/analytics/analytics_controller.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:hiddify/core/logger/logger_controller.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/preferences/preferences_migration.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/app/widget/app.dart';
import 'package:hiddify/features/auto_start/notifier/auto_start_notifier.dart';
import 'package:hiddify/features/deep_link/notifier/deep_link_notifier.dart';
import 'package:hiddify/features/log/data/log_data_providers.dart';
import 'package:hiddify/features/panel/xboard/services/auth_provider.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service_provider.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/user_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/system_tray/notifier/system_tray_notifier.dart';
import 'package:hiddify/features/window/notifier/window_notifier.dart';
import 'package:hiddify/singbox/service/singbox_service_provider.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:hiddify/core/app_info/domain_init_failed_provider.dart';
import 'package:path_provider/path_provider.dart';

Future<void> _writeLog(String message) async {
  final now = DateTime.now().toString().split('.').first;
  final logLine = '[bootstrap] $now: $message\n';
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/app_login.log');
    await file.writeAsString(logLine, mode: FileMode.append);
  } catch (e) {}
}

Future<void> lazyBootstrap(
  WidgetsBinding widgetsBinding,
  Environment env,
) async {
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  LoggerController.preInit();
  FlutterError.onError = Logger.logFlutterError;
  WidgetsBinding.instance.platformDispatcher.onError = Logger.logPlatformDispatcherError;
  final stopWatch = Stopwatch()..start();

  final container = ProviderContainer(
    overrides: [
      environmentProvider.overrideWithValue(env),
    ],
  );
  bool domainInitFailed = false;
  UserService? userService;
  try {
    container.read(authProvider.notifier).state = false;
    await _writeLog('Initializing domain...');
    await HttpServiceProvider.initialize();
    userService = UserService();
    await _writeLog('Domain initialized successfully: ${HttpService.baseUrl}');
  } catch (e, stackTrace) {
    await _writeLog('Error during domain initialization: $e\nStackTrace: $stackTrace');
    container.read(authProvider.notifier).state = false;
    domainInitFailed = true;
  }

  container.read(domainInitFailedProvider.notifier).state = domainInitFailed;

  try {
    final loginToken = await getLoginToken();
    final token = loginToken ?? await getToken();
    await _writeLog('Retrieved token: $token (type: ' + (loginToken != null ? 'login_token' : 'auth_data') + ')');

    if (token != null && userService != null) {
      await _writeLog('Validating token...');
      bool isValid = false;
      try {
        isValid = await userService.validateToken(token);
        await _writeLog('Token validation result: $isValid');
      } catch (e, stackTrace) {
        await _writeLog('Error during token validation: $e\nStackTrace: $stackTrace');
        // 即使验证失败也不清除token，允许用户在主界面中重新登录
        isValid = false;
      }

      if (isValid) {
        container.read(authProvider.notifier).state = true;
        await _writeLog('User is logged in, preparing to runApp(App)');
        try {
          runApp(
            ProviderScope(
              parent: container,
              child: SentryUserInteractionWidget(
                child: Builder(
                  builder: (context) {
                    try {
                      return const App();
                    } catch (e, stackTrace) {
                      _writeLog('Error creating App widget: $e\nStackTrace: $stackTrace');
                      return MaterialApp(
                        home: Scaffold(
                          body: Center(
                            child: Text('应用程序初始化失败，请检查日志'),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          );
          await _writeLog('runApp(App) finished successfully');
          return;
        } catch (e, stackTrace) {
          await _writeLog('Critical error during runApp: $e\nStackTrace: $stackTrace');
          throw e;
        }
      } else {
        container.read(authProvider.notifier).state = false;
        await _writeLog('Token is invalid, setting user to not logged in but preserving token');
      }
    } else {
      container.read(authProvider.notifier).state = false;
      await _writeLog('No token found, setting user to not logged in');
    }
  } catch (e, stackTrace) {
    await _writeLog('Error during token validation: $e\nStackTrace: $stackTrace');
    container.read(authProvider.notifier).state = false;
  }

  await _init(
    "directories",
    () => container.read(appDirectoriesProvider.future),
  );
  LoggerController.init(container.read(logPathResolverProvider).appFile().path);

  final appInfo = await _init(
    "app info",
    () => container.read(appInfoProvider.future),
  );
  await _init(
    "preferences",
    () => container.read(sharedPreferencesProvider.future),
  );

  // 检查是否首次运行，首次运行则自动开启开机启动
  if (PlatformUtils.isDesktop) {
    final prefs = container.read(sharedPreferencesProvider).requireValue;
    const firstRunKey = "auto_start_first_run";
    final isFirstRun = prefs.getBool(firstRunKey) == null;
    if (isFirstRun) {
      await container.read(autoStartNotifierProvider.notifier).enable();
      await prefs.setBool(firstRunKey, false);
    }
  }

  final enableAnalytics = await container.read(analyticsControllerProvider.future);
  if (enableAnalytics) {
    await _init(
      "analytics",
      () => container.read(analyticsControllerProvider.notifier).enableAnalytics(),
    );
  }

  await _init(
    "preferences migration",
    () async {
      try {
        await PreferencesMigration(
          sharedPreferences: container.read(sharedPreferencesProvider).requireValue,
        ).migrate();
      } catch (e, stackTrace) {
        Logger.bootstrap.error("preferences migration failed", e, stackTrace);
        if (env == Environment.dev) rethrow;
        Logger.bootstrap.info("clearing preferences");
        await container.read(sharedPreferencesProvider).requireValue.clear();
      }
    },
  );

  final debug = container.read(debugModeNotifierProvider) || kDebugMode;

  if (PlatformUtils.isDesktop) {
    await _writeLog('Initializing desktop-specific features');

    await _writeLog('Initializing window controller');
    await _init(
      "window controller",
      () => container.read(windowNotifierProvider.future),
    );

    final silentStart = container.read(Preferences.silentStart);
    await _writeLog('Silent start preference: ${silentStart ? "Enabled" : "Disabled"}');

    if (!silentStart) {
      await _writeLog('Opening window with focus: false');
      try {
        await container.read(windowNotifierProvider.notifier).open(focus: false);
        await _writeLog('Window opened successfully');
      } catch (e, stack) {
        await _writeLog('Error opening window: $e\nStackTrace: $stack');
      }
    } else {
      await _writeLog('Silent start enabled, window will remain hidden and accessible via tray');
      Logger.bootstrap.debug("silent start, remain hidden accessible via tray");
    }

    await _writeLog('Initializing auto start service');
    await _init(
      "auto start service",
      () => container.read(autoStartNotifierProvider.future),
    );
  }
  await _init(
    "logs repository",
    () => container.read(logRepositoryProvider.future),
  );
  await _init("logger controller", () => LoggerController.postInit(debug));

  Logger.bootstrap.info(appInfo.format());

  await _init(
    "profile repository",
    () => container.read(profileRepositoryProvider.future),
  );

  await _safeInit(
    "active profile",
    () => container.read(activeProfileProvider.future),
    timeout: 1000,
  );
  await _safeInit(
    "deep link service",
    () => container.read(deepLinkNotifierProvider.future),
    timeout: 1000,
  );
  await _init(
    "sing-box",
    () => container.read(singboxServiceProvider).init(),
  );
  if (PlatformUtils.isDesktop) {
    await _safeInit(
      "system tray",
      () => container.read(systemTrayNotifierProvider.future),
      timeout: 1000,
    );
  }

  if (Platform.isAndroid) {
    await _safeInit(
      "android display mode",
      () async {
        await FlutterDisplayMode.setHighRefreshRate();
      },
    );
  }

  Logger.bootstrap.info("bootstrap took [${stopWatch.elapsedMilliseconds}ms]");
  stopWatch.stop();

  runApp(
    ProviderScope(
      parent: container,
      child: SentryUserInteractionWidget(
        child: const App(),
      ),
    ),
  );

  FlutterNativeSplash.remove();
}

Future<T> _init<T>(
  String name,
  Future<T> Function() initializer, {
  int? timeout,
}) async {
  final stopWatch = Stopwatch()..start();
  Logger.bootstrap.info("initializing [$name]");
  Future<T> func() => timeout != null ? initializer().timeout(Duration(milliseconds: timeout)) : initializer();
  try {
    final result = await func();
    Logger.bootstrap.debug("[$name] initialized in ${stopWatch.elapsedMilliseconds}ms");
    return result;
  } catch (e, stackTrace) {
    Logger.bootstrap.error("[$name] error initializing", e, stackTrace);
    rethrow;
  } finally {
    stopWatch.stop();
  }
}

Future<T?> _safeInit<T>(
  String name,
  Future<T> Function() initializer, {
  int? timeout,
}) async {
  try {
    return await _init(name, initializer, timeout: timeout);
  } catch (e) {
    return null;
  }
}
