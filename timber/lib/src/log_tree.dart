import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart' as $logging;

import 'tree.dart';

abstract class LogTree {
  void performLog($logging.LogRecord record);

  /// Internal Logger Name
  String get loggerName;
}
