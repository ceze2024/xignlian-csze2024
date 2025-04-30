// ignore_for_file: avoid_print

import 'dart:io';

import 'package:loggy/loggy.dart';

class ConsolePrinter extends LoggyPrinter {
  const ConsolePrinter({
    this.showColors = false,
  });

  final bool showColors;

  static final _levelColors = {
    LogLevel.debug: AnsiColor(foregroundColor: AnsiColor.grey(0.5), italic: true),
    LogLevel.info: AnsiColor(foregroundColor: 35),
    LogLevel.warning: AnsiColor(foregroundColor: 214),
    LogLevel.error: AnsiColor(foregroundColor: 196),
  };

  @override
  void onLog(LogRecord record) {
    // 发布版本不打印日志
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final colorize = showColors && stdout.supportsAnsiEscapes;
    final time = record.time.toIso8601String().split('T')[1];
    final callerFrame = record.callerFrame == null ? ' ' : ' (${record.callerFrame?.location}) ';

    final String logLevel;
    if (colorize) {
      logLevel = record.level.name.toUpperCase().padRight(8);
    } else {
      logLevel = "[${record.level.name.toUpperCase()}]".padRight(10);
    }

    final color = showColors ? levelColor(record.level) ?? AnsiColor() : AnsiColor();

    // 发布版本不打印日志
    /*
    print(
      color(
        '$time $logLevel [${record.loggerName}]$callerFrame${record.message}',
      ),
    );

    if (record.stackTrace != null) {
      print(record.stackTrace);
    }
    */
  }

  AnsiColor? levelColor(LogLevel level) {
    return _levelColors[level];
  }
}

class FileLogPrinter extends LoggyPrinter {
  FileLogPrinter(
    String filePath, {
    this.minLevel = LogLevel.debug,
  }) : _logFile = File(filePath);

  final File _logFile;
  final LogLevel minLevel;

  late final _sink = _logFile.openWrite(
    mode: FileMode.writeOnly,
  );

  @override
  void onLog(LogRecord record) {
    // 发布版本不写入日志文件
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final time = record.time.toIso8601String().split('T')[1];
    _sink.writeln("$time - $record");
    if (record.error != null) {
      _sink.writeln(record.error);
    }
    if (record.stackTrace != null) {
      _sink.writeln(record.stackTrace);
    }
  }

  void dispose() {
    _sink.close();
  }
}
