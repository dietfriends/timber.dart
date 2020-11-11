import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart' as $logging;

import 'tree.dart';

mixin LogTree {
  void performLog($logging.LogRecord record);
}
