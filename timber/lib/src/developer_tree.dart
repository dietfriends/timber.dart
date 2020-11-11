import 'dart:developer' as developer;

import 'package:logging/logging.dart' as $logging;
import 'package:timber/src/log_tree.dart';

import 'tree.dart';

class AppLogger extends Tree with LogTree {
  @override
  void performLog($logging.LogRecord record) {
    developer.log(record.message,
        error: record.error,
        name: record.loggerName,
        stackTrace: record.stackTrace,
        level: record.level.value,
        time: record.time,
        sequenceNumber: record.sequenceNumber,
        zone: record.zone);
  }
}
