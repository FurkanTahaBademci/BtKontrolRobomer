import 'package:flutter/foundation.dart';

enum LogLevel { info, warning, error, success }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
  });

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  String get levelLabel {
    switch (level) {
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERR ';
      case LogLevel.success:
        return ' OK ';
    }
  }

  @override
  String toString() => '[$formattedTime][$levelLabel][$tag] $message';
}

/// Uygulama genelinde log tutan singleton servis
class LogService extends ChangeNotifier {
  LogService._();
  static final LogService instance = LogService._();

  static const int _maxEntries = 500;
  final List<LogEntry> _entries = [];

  List<LogEntry> get entries => List.unmodifiable(_entries);

  void log(String tag, String message, {LogLevel level = LogLevel.info}) {
    _entries.insert(
      0,
      LogEntry(
        timestamp: DateTime.now(),
        level: level,
        tag: tag,
        message: message,
      ),
    );
    if (_entries.length > _maxEntries) {
      _entries.removeRange(_maxEntries, _entries.length);
    }
    notifyListeners();
  }

  void info(String tag, String message) =>
      log(tag, message, level: LogLevel.info);
  void warn(String tag, String message) =>
      log(tag, message, level: LogLevel.warning);
  void error(String tag, String message) =>
      log(tag, message, level: LogLevel.error);
  void success(String tag, String message) =>
      log(tag, message, level: LogLevel.success);

  void clear() {
    _entries.clear();
    notifyListeners();
  }

  String exportAsText() =>
      _entries.reversed.map((e) => e.toString()).join('\n');
}
