import 'package:flutter_test/flutter_test.dart';
import 'package:sentry/sentry.dart';

import 'package:timber_sentry/timber_sentry.dart';
import 'package:mockito/mockito.dart';
import 'package:logging/logging.dart';

void main() {
  SentryTree tree;
  MockSentry client;
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    client = MockSentry();
    tree = TestSentry(client);
  });

  test('performLog', () {
    final record = LogRecord(Level.INFO, 'test', 'logger');

    tree.performLog(record);

    verifyNever(client.captureEvent(any));
  });

  test('performLog w', () {
    final record = LogRecord(Level.INFO, 'test', 'logger');

    tree.performLog(record);

    final record2 = LogRecord(Level.WARNING, 'test', 'logger');

    when(client.captureEvent(SentryEvent(
      level: SentryLevel.warning,
      message: Message('test'),
      logger: 'logger',
    ))).thenReturn(null);
    tree.performLog(record2);
    verify(client.captureEvent(any)).called(1);
  });

  test('buffer size', () {
    tree = SentryTree(client, bufferSize: 1);

    final record = LogRecord(Level.INFO, 'test', 'logger');

    tree.performLog(record);
    tree.performLog(record);
    tree.performLog(record);
    tree.performLog(record);

    verifyNever(client.captureEvent(any));
  });
}

class MockSentry extends Mock implements SentryClient {}

class TestSentry extends SentryTree {
  TestSentry(SentryClient client) : super(client);

  @override
  Future<String> get release async {
    return '1.0.0+1';
  }
}
