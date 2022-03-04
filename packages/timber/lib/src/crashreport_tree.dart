import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart' as $logging;

import 'tree.dart';

abstract class CrashReportTree {
  void performReportError(dynamic error, dynamic stackTrace);

  void performReportFlutterError(FlutterErrorDetails details);
}
