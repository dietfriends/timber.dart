import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info/package_info.dart';
import 'package:sentry/sentry.dart';
import 'package:sentry/src/protocol/sentry_id.dart';
import 'package:logging/logging.dart' as $logging;

import 'package:sentry/src/hub_adapter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:timber_sentry/timber_sentry.dart';
import 'package:logging/logging.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(SentryEvent());
  });

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    $logging.Logger.root.onRecord.listen(($logging.LogRecord event) {
      print(event.message);
    });
    final options = SentryOptions(dsn: 'test');
    Sentry.init((options) => options..dsn = 'test');
  });
  late SentryTree tree;
  late MockHub hub;
  setUp(() {
    hub = MockHub();
    tree = SentryTree(hub);
  });
  tearDown(() {
    reset(hub);
  });
  group('performLog', () {
    test('performLog', () {
      final record = LogRecord(Level.INFO, 'test', 'logger');

      tree.performLog(record);

      verifyNever(() => hub.captureEvent(any()));
    });

    test('performLog waring', () {
      final record = LogRecord(Level.INFO, 'test', 'logger');

      tree.performLog(record);

      final record2 = LogRecord(Level.WARNING, 'test', 'logger');

      when(() => hub.captureEvent(any()!))
          .thenAnswer((_) => Future.value(SentryId.empty()));
      tree.performLog(record2);
      verifyNever(() => hub.captureEvent(any()!));
    });

    test('performLog severe', () {
      final record = LogRecord(Level.INFO, 'test', 'logger');

      when(() => hub.addBreadcrumb(any())).thenAnswer((_) async {});
      tree.performLog(record);
      verify(() => hub.addBreadcrumb(any()!)).called(1);

      final record2 = LogRecord(Level.SEVERE, 'test', 'logger');

      when(() => hub.captureEvent(any()!))
          .thenAnswer((_) => Future.value(SentryId.newId()));

      tree.performLog(record2);
      verify(() => hub.addBreadcrumb(any()!)).called(1);
      verify(() => hub.captureEvent(any()!)).called(1);
    });

    test('performLog shout', () {
      final record = LogRecord(Level.INFO, 'test', 'logger');

      tree.performLog(record);

      final record2 = LogRecord(Level.SHOUT, 'test', 'logger');

      when(() => hub.captureEvent(SentryEvent(
            level: SentryLevel.fatal,
            message: SentryMessage('test'),
            logger: 'logger',
          ))).thenAnswer((_) => Future.value(SentryId.empty()));
      tree.performLog(record2);
      verify(() => hub.captureEvent(any(named: 'addBreadcrumb')!)).called(1);
    });
  });

  test('dispose', () async {
    when(() => hub.close()).thenAnswer((_) => Future.value());
    tree.dispose();
    verify(() => hub.close()).called(1);
  });

  test('buffer size', () {
    var sentryOptions = SentryFlutterOptions(dsn: 'dsn');
    sentryOptions.maxBreadcrumbs = 1;
    tree = SentryTree(hub, sentryOptions: sentryOptions);

    final record = LogRecord(Level.INFO, 'test', 'logger');

    tree.performLog(record);
    tree.performLog(record);
    tree.performLog(record);
    tree.performLog(record);

    verifyNever(() => hub.captureEvent(any()));
  });

  group('LevelExtension', () {
    test('toSentryLevel', () {
      expect(Level.FINEST.toSentryLevel, SentryLevel.debug);
      expect(Level.FINER.toSentryLevel, SentryLevel.debug);
      expect(Level.FINE.toSentryLevel, SentryLevel.debug);

      expect(Level.INFO.toSentryLevel, SentryLevel.info);
      expect(Level.SEVERE.toSentryLevel, SentryLevel.error);
      expect(Level.SHOUT.toSentryLevel, SentryLevel.fatal);

      expect(Level.ALL.toSentryLevel, SentryLevel.debug);
      expect(Level.OFF.toSentryLevel, SentryLevel.debug);
    });
  });

  group('LogRecordExtension', () {
    test('toBreadcrumb', () {
      final stack = StackTrace.current;
      final record =
          LogRecord(Level.INFO, 'message', 'logger', 'object', stack);
      final breadcrumb = record.toBreadcrumb;

      expect(breadcrumb.level, SentryLevel.info);
      expect(breadcrumb.message, record.message);
      expect(breadcrumb.type, record.loggerName);
      expect(breadcrumb.data, record.object);
      expect(breadcrumb.timestamp, record.time);
    });

    test('data is not map', () {
      final record = LogRecord(Level.INFO, 'message', 'logger', 'object', null);
      final breadcrumb = record.toBreadcrumb;

      expect(breadcrumb.level, SentryLevel.info);
      expect(breadcrumb.message, record.message);
      expect(breadcrumb.type, record.loggerName);
      expect(breadcrumb.data, record.object);
      expect(breadcrumb.timestamp, record.time);
    });
  });
}

class MockHub extends Mock implements HubAdapter {}
