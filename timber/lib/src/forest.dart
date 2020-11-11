import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:logging/logging.dart' show LogRecord;
import 'package:quiver/check.dart';
import 'package:synchronized/synchronized.dart';
import 'package:timber/src/analytics.dart';

import 'crashreport_tree.dart';
import 'log_tree.dart';
import 'tree.dart';

final _forestLogger = Logger('Forest');

class Forest extends Tree with LogTree, CrashReportTree, AnalyticsTree {
  final _lock = Lock();
  final _memo = AsyncMemoizer();
  StreamSubscription<LogRecord> _subscription;

  Future<void> init() {
    return _memo.runOnce(() {
      // This captures errors reported by the Flutter framework.
      FlutterError.onError = (FlutterErrorDetails details) {
        if (isInDebugMode) {
          // In development mode simply print to console.
          FlutterError.dumpErrorToConsole(details);
        } else {
          // In production mode report to the application zone to report to
          // Forest.
          performReportFlutterError(details);
        }
      };
      _subscription = Logger.root.onRecord.listen((record) {
        performLog(record);
      });
    });
  }

  @override
  void performLog(LogRecord record) {
    _logTrees.forEach((tree) {
      tree.performLog(record);
    });
  }

  /// Flutter Error 를 Report 합니다.
  /// ex: Crashlytics, Sentry
  @override
  Future<void> performReportError(error, stackTrace) async {
    _forestLogger.info('Caught error: $error');

    // Errors thrown in development mode are unlikely to be interesting. You can
    // check if you are running in dev mode using an assertion and omit sending
    // the report.
    if (isInDebugMode) {
      // 디버그 모드에서는 전체 stacktrace를 출력합니다.
      _forestLogger.info(stackTrace);
      _forestLogger.info('In dev mode. Not sending report to Sentry.io.');
      return;
    } else {
      _forestLogger.info('performReport');

      _crashReportTrees.forEach((tree) {
        tree.performReportError(error, stackTrace);
      });
    }
  }

  /// Flutter Error 를 Report 합니다.
  /// ex: Crashlytics, Sentry
  @override
  void performReportFlutterError(FlutterErrorDetails details) {
    _forestLogger.info('Caught error: ${details.exception}');

    // Errors thrown in development mode are unlikely to be interesting. You can
    // check if you are running in dev mode using an assertion and omit sending
    // the report.
    if (isInDebugMode) {
      // 디버그 모드에서는 전체 stacktrace를 출력합니다.
      _forestLogger.info(details.stack);
      _forestLogger.info('In dev mode. Not sending report to Sentry.io.');
      return;
    } else {
      _forestLogger.info('performReport');

      _crashReportTrees.forEach((tree) {
        tree.performReportFlutterError(details);
      });
    }
  }

  final _trees = <Tree>[];

  Iterable<LogTree> get _logTrees => _trees.whereType<LogTree>();

  Iterable<CrashReportTree> get _crashReportTrees =>
      _trees.whereType<CrashReportTree>();

  Iterable<AnalyticsTree> get _analyticsTrees =>
      _trees.whereType<AnalyticsTree>();

  /// Add a new logging tree.
  void plant(Tree tree) {
    checkArgument(tree != this);
    _lock.synchronized(() => _trees.add(tree));
  }

  /// Add a new logging tree.
  void plantAll(Iterable<Tree> trees) {
    for (var tree in trees) {
      checkNotNull(tree);
      checkArgument(tree != this, message: 'Cannot plant Timber into itself.');
    }
    _lock.synchronized(() => _trees.addAll(trees));
  }

  /// Remove a planted tree.
  void uproot(Tree tree) {
    _lock.synchronized(() => _trees.remove(tree));
  }

  /// Remove all planted tree.
  void uprootAll() {
    _lock.synchronized(() => _trees.clear());
  }

  /// Return a copy of all planted [trees][Tree].
  Future<List<Tree>> get forest {
    return _lock.synchronized(() => List.unmodifiable(_trees));
  }

  int get treeCount => _trees.length;

  /// Override the level for this particular [Logger] and its children.
  set level(Level value) {
    Logger.root.level = level;
  }

  Level get level => Logger.root.level;

  @override
  void dispose() {
    _lock.synchronized(() {
      _trees.forEach((tree) {
        tree.dispose();
      });
      _trees.clear();
    });
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  bool isSupportedEventName(String name) {
    return true;
  }

  @override
  List<Type> get supportedTypes => [];

  @override
  Future<void> performLogEvent(
      {@required String name, Map<String, dynamic> parameters}) {
    _analyticsTrees.where((tree) => isSupportedEventName(name)).forEach((tree) {
      tree.performLogEvent(name: name, parameters: parameters);
    });
  }
}
