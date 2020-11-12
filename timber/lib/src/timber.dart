import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:logging/logging.dart' show LogRecord;
import 'package:quiver/check.dart';
import 'package:synchronized/synchronized.dart';

import 'analytics.dart';
import 'crashreport_tree.dart';
import 'log_tree.dart';
import 'tree.dart';

part 'forest.dart';

class Timber {
  static final Forest _instance = Forest._();

  static Forest get instance => _instance;

  Timber._internal();
}
