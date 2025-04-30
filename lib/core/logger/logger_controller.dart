import 'dart:io';

import 'package:hiddify/core/logger/custom_logger.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:loggy/loggy.dart';

class LoggerController extends LoggyPrinter with InfraLogger {
  LoggerController(
    this.consolePrinter,
    this.otherPrinters,
  );

  final LoggyPrinter consolePrinter;
  final Map<String, LoggyPrinter> otherPrinters;

  static LoggerController get instance => _instance;

  static late LoggerController _instance;

  static void preInit() {
    Loggy.initLoggy(logPrinter: const ConsolePrinter());
  }

  static void init(String appLogPath, {bool debugMode = false}) {
    _instance = LoggerController(
      const ConsolePrinter(),
      {},
    );
    Loggy.initLoggy(
      logPrinter: _instance,
      logOptions: LogOptions(debugMode ? LogLevel.all : LogLevel.off),
    );
  }

  static Future<void> postInit(bool debugMode) async {
    if (!debugMode) return;
  }

  void addPrinter(String name, LoggyPrinter printer) {
    loggy.debug("adding [$name] printer");
    otherPrinters.putIfAbsent(name, () => printer);
  }

  void removePrinter(String name) {
    loggy.debug("removing [$name] printer");
    final printer = otherPrinters[name];
    if (printer case FileLogPrinter()) {
      printer.dispose();
    }
    otherPrinters.remove(name);
  }

  @override
  void onLog(LogRecord record) {
    consolePrinter.onLog(record);
    for (final printer in otherPrinters.values) {
      printer.onLog(record);
    }
  }
}
