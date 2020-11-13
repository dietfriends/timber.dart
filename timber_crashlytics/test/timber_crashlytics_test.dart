import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_crashlytics/src/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart' as $logging;
import 'package:stack_trace/stack_trace.dart';
import 'package:timber_crashlytics/timber_crashlytics.dart';

import 'mock.dart';

void main() {
  setupFirebaseCrashlyticsMocks();
  FirebaseCrashlytics crashlytics;

  CrashlyticsTree tree;
  setUpAll(() async {
    await Firebase.initializeApp();
    crashlytics = FirebaseCrashlytics.instance;
  });

  setUp(() {
    methodCallLog.clear();
    tree = CrashlyticsTree();
  });

  tearDown(() {
    methodCallLog.clear();
  });

  group('performLog', () {
    test('should call Crashlytics#log', () {
      final msg = 'foo';
      var record = $logging.LogRecord($logging.Level.INFO, msg, 'logger');
      tree.performLog(record);
      expect(methodCallLog, <Matcher>[
        isMethodCall('Crashlytics#log', arguments: {'message': msg})
      ]);
    });

    test('should call Crashlytics#recordError', () {
      final msg = 'foo';
      final exception = 'foo exception';
      final stack = StackTrace.current;

      var record = $logging.LogRecord(
          $logging.Level.SEVERE, msg, 'logger', exception, stack);
      tree.performLog(record);
      expect(methodCallLog, <Matcher>[
        isMethodCall('Crashlytics#recordError', arguments: {
          'exception': exception,
          'reason': msg,
          'information': '',
          'stackTraceElements':
              getStackTraceElements(Trace.format(stack).trimRight().split('\n'))
        })
      ]);
    });
  });

  test('performReportFlutterError', () {
    final exception = 'foo exception';
    final exceptionReason = 'bar reason';
    final exceptionLibrary = 'baz library';
    final exceptionFirstMessage = 'first message';
    final exceptionSecondMessage = 'second message';
    final stack = StackTrace.current;
    final details = FlutterErrorDetails(
      exception: exception,
      stack: stack,
      library: exceptionLibrary,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsNode.message(exceptionFirstMessage),
        DiagnosticsNode.message(exceptionSecondMessage),
      ],
      context: ErrorDescription(exceptionReason),
    );

    tree.performReportFlutterError(details);
    expect(methodCallLog, <Matcher>[
      isMethodCall('Crashlytics#recordError', arguments: {
        'exception': exception,
        'reason': exceptionReason,
        'information': '$exceptionFirstMessage\n$exceptionSecondMessage',
        'stackTraceElements':
            getStackTraceElements(Trace.format(stack).trimRight().split('\n'))
      })
    ]);
  });

  test('performReportError', () {
    final exception = 'foo exception';
    final stack = StackTrace.current;

    tree.performReportError(exception, stack);
    expect(methodCallLog, <Matcher>[
      isMethodCall('Crashlytics#recordError', arguments: {
        'exception': exception,
        'reason': null,
        'information': '',
        'stackTraceElements':
            getStackTraceElements(Trace.format(stack).trimRight().split('\n'))
      })
    ]);
  });

  test('setUserProperty', () {
    final key = 'foo';
    final value = 'bar';

    tree.setUserProperty(key, value);
    expect(methodCallLog, <Matcher>[
      isMethodCall('Crashlytics#setCustomKey',
          arguments: {'key': key, 'value': value})
    ]);
  });

  group('setUid', () {
    test('should throw if null', () {
      expect(() => tree.setUid(null), throwsAssertionError);
    });
    test('should call crashlytics setUserIdentifier', () async {
      final id = 'foo';
      await tree.setUid(id);
      expect(methodCallLog, <Matcher>[
        isMethodCall('Crashlytics#setUserIdentifier', arguments: {
          'identifier': id,
        })
      ]);
    });
  });

  test('reset', () {
    tree.reset();
  });

  test('flush', () {
    tree.flush();
  });

  test('increment', () {
    tree.increment({});
  });

  test('setOnce', () {
    tree.setOnce({});
  });

  test('union', () {
    tree.union({});
  });

  test('dispose', () {
    tree.dispose();
  });
}
