import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hiddify/core/preferences/actions_at_closing.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/features/common/adaptive_root_scaffold.dart';
import 'package:hiddify/features/window/notifier/window_notifier.dart';
import 'package:hiddify/features/window/widget/window_closing_dialog.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';

class WindowWrapper extends StatefulHookConsumerWidget {
  const WindowWrapper(this.child, {super.key});

  final Widget child;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _WindowWrapperState();
}

class _WindowWrapperState extends ConsumerState<WindowWrapper> with WindowListener, AppLogger {
  late AlertDialog closeDialog;

  bool isWindowClosingDialogOpened = false;

  @override
  Widget build(BuildContext context) {
    loggy.debug('Building WindowWrapper');
    ref.watch(windowNotifierProvider);

    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    loggy.debug('Initializing WindowWrapper');
    windowManager.addListener(this);
    if (PlatformUtils.isDesktop) {
      loggy.debug('Desktop platform detected, configuring window');
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          loggy.debug('Setting window properties');
          await windowManager.setPreventClose(true);
          loggy.debug('PreventClose set successfully');

          final isVisible = await windowManager.isVisible();
          loggy.debug('Current window visibility: $isVisible');

          final isAlwaysOnTop = await windowManager.isAlwaysOnTop();
          loggy.debug('Current window always on top: $isAlwaysOnTop');

          final isFocused = await windowManager.isFocused();
          loggy.debug('Current window focus state: $isFocused');

          final isMaximized = await windowManager.isMaximized();
          loggy.debug('Current window maximize state: $isMaximized');

          final isMinimized = await windowManager.isMinimized();
          loggy.debug('Current window minimize state: $isMinimized');

          final bounds = await windowManager.getBounds();
          loggy.debug('Current window bounds: $bounds');
        } catch (e, stack) {
          loggy.error('Error configuring window', e, stack);
        }
      });
    } else {
      loggy.debug('Non-desktop platform detected');
    }
  }

  @override
  void dispose() {
    loggy.debug('Disposing WindowWrapper');
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Future<void> onWindowClose() async {
    loggy.debug('Window close requested');
    if (RootScaffold.stateKey.currentContext == null) {
      loggy.debug('No scaffold context found, closing window directly');
      await ref.read(windowNotifierProvider.notifier).close();
      return;
    }

    final action = ref.read(Preferences.actionAtClose);
    loggy.debug('Action at close: $action');

    switch (action) {
      case ActionsAtClosing.ask:
        if (isWindowClosingDialogOpened) {
          loggy.debug('Close dialog already opened');
          return;
        }
        loggy.debug('Showing close confirmation dialog');
        isWindowClosingDialogOpened = true;
        await showDialog(
          context: RootScaffold.stateKey.currentContext!,
          builder: (BuildContext context) => const WindowClosingDialog(),
        );
        isWindowClosingDialogOpened = false;
        break;

      case ActionsAtClosing.hide:
        loggy.debug('Hiding window');
        await ref.read(windowNotifierProvider.notifier).close();
        break;

      case ActionsAtClosing.exit:
        loggy.debug('Quitting application');
        await ref.read(windowNotifierProvider.notifier).quit();
        break;
    }
  }

  @override
  void onWindowFocus() {
    loggy.debug('Window focused');
    setState(() {});
  }
}
