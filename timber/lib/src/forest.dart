part of 'timber.dart';

const _LOGGER_NAME = 'Forest';
final _forestLogger = Logger(_LOGGER_NAME);

class Forest extends Tree
    with LogTree, CrashReportTree, AnalyticsTree, UserAnalyticsTree {
  final _lock = Lock();
  final _memo = AsyncMemoizer();
  final FlutterExceptionHandler? _exceptionHandler;

  @visibleForTesting
  Forest([this._exceptionHandler]);

  Forest._([this._exceptionHandler]);

  StreamSubscription<LogRecord>? _subscription;

  Future<void> init() {
    return _memo.runOnce(() {
      // This captures errors reported by the Flutter framework.
      FlutterError.onError = _exceptionHandler ?? onFlutterError;
      _subscription = Logger.root.onRecord.listen((record) {
        performLog(record);
      });
    });
  }

  // Default Error Handler
  void onFlutterError(FlutterErrorDetails details) {
    if (isInDebugMode) {
      // In development mode simply print to console.
      FlutterError.dumpErrorToConsole(details);
    } else {
      // In production mode report to the application zone to report to
      // Forest.
      performReportFlutterError(details);
    }
  }

  @override
  void performLog(LogRecord record) {
    _logTrees.forEach((tree) {
      if (record.loggerName != tree.loggerName) {
        // exclude recursive logging
        tree.performLog(record);
      }
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

  Iterable<UserAnalyticsTree> get _userAnalyticsTrees =>
      _trees.whereType<UserAnalyticsTree>();

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
    Logger.root.level = value;
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
  Set<Type> get supportedTypes {
    var set = <Type>{};
    _analyticsTrees.forEach((tree) {
      set.addAll(tree.supportedTypes);
    });
    return set;
  }

  @override
  bool isSupportedType(Type value) {
    return _analyticsTrees.any((element) => element.isSupportedType(value));
  }

  @override
  Future<void> performLogEvent(
      {required String name, Map<String, dynamic>? parameters}) async {
    _analyticsTrees.where((tree) => isSupportedEventName(name)).forEach((tree) {
      tree.performLogEvent(name: name, parameters: parameters);
    });
  }

  @override
  Future<void> setUserProperty(String name, value) async {
    _userAnalyticsTrees.forEach((tree) {
      tree.setUserProperty(name, value);
    });
  }

  /// userId 설정
  @override
  Future<void> setUserId(String id) async {
    _userAnalyticsTrees.forEach((tree) {
      tree.setUserId(id);
    });
  }

  /// email 설정
  @override
  Future<void> setEmail(String email) async {
    _userAnalyticsTrees.forEach((tree) {
      tree.setEmail(email);
    });
  }

  /// 전화번호 설정
  @override
  Future<void> setPhone(String phone) async {
    _userAnalyticsTrees.forEach((tree) {
      tree.setPhone(phone);
    });
  }

  /// uid 설정
  @override
  Future<void> setUid(String uid) async {
    _userAnalyticsTrees.forEach((tree) {
      tree.setUid(uid);
    });
  }

  @override
  Future<void> union(Map<String, List<dynamic>> properties) async {
    _userAnalyticsTrees.forEach((tree) {
      tree.union(properties);
    });
  }

  @override
  Future<void> increment(Map<String, num> properties) async {
    _userAnalyticsTrees.forEach((tree) {
      tree.increment(properties);
    });
  }

  @override
  Future<void> setOnce(Map<String, dynamic> properties) async {
    _userAnalyticsTrees.forEach((tree) {
      tree.setOnce(properties);
    });
  }

  @override
  Future<void> setUserName(value) async {
    _userAnalyticsTrees.forEach((tree) {
      tree.setUserName(value);
    });
  }

  @override
  Future<void> reset() async {
    _userAnalyticsTrees.forEach((tree) {
      tree.reset();
    });
    _analyticsTrees.forEach((tree) {
      tree.reset();
    });
  }

  @override
  Future<void> flush() async {
    _userAnalyticsTrees.forEach((tree) {
      tree.flush();
    });
    _analyticsTrees.forEach((tree) {
      tree.flush();
    });
  }

  @override
  Future<void> setCurrentScreen(
      {String? screenName, String screenClassOverride = 'Flutter'}) async {
    _analyticsTrees.forEach((tree) {
      tree.setCurrentScreen(
          screenName: screenName, screenClassOverride: screenClassOverride);
    });
  }

  @override
  Future<void> timingEvent(String name) async {
    _analyticsTrees.forEach((tree) {
      tree.timingEvent(name);
    });
  }

  @override
  String get loggerName => _LOGGER_NAME;
}
