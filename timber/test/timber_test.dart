import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:timber/timber.dart';
import 'package:mockito/mockito.dart';

void main() {
  Forest devForest;
  Forest prodForest;
  Forest mockForest;

  setUp(() {
    devForest = Forest();
    prodForest = ProdForest();
    mockForest = MockForest();
  });

  group('Forest', () {
    test('init - dev', () {
      devForest.init();
      FlutterError.onError(FlutterErrorDetails(exception: 'test'));
    });

    test('init - prod', () {
      prodForest.init();
      FlutterError.onError(FlutterErrorDetails(exception: 'test'));
    });

    test('init - exceptionHandler, flutter 에서 에러 발생시 handler 가 불려야 함',
        () async {
      var callCount = 0;
      final handler = (FlutterErrorDetails details) {
        callCount++;
      };

      final forest = Forest(handler);
      await forest.init();
      expect(FlutterError.onError, equals(handler),
          reason:
              'Init 에 handler 설정할 경우 FlutterError.onError 에 handler 가 할당 됨');

      FlutterError.onError(FlutterErrorDetails());
      expect(callCount, 1, reason: '한번 불릴 경우');
      FlutterError.onError(FlutterErrorDetails());
      expect(callCount, 2, reason: '두번 불릴 경우');
    });

    test('dispose Test', () async {
      final tree1 = MockLogTree();

      devForest.plant(tree1);
      devForest.dispose();

      verify(tree1.dispose()).called(1);
      verifyNoMoreInteractions(tree1);
      expect(devForest.treeCount, 0);
      expect((await devForest.forest).length, 0);
    });

    test('platAll Test', () async {
      final trees = [MockLogTree(), MockLogTree()];
      devForest.plantAll(trees);

      expect((await devForest.forest).length, 2);
    });

    test('uproot Test', () async {
      final tree1 = MockLogTree();
      final tree2 = MockLogTree();

      final trees = [tree1, tree2];
      devForest.plantAll(trees);

      expect((await devForest.forest).length, 2);

      devForest.uproot(tree1);
      final forest = await devForest.forest;
      expect(forest, isNotEmpty);
      expect(forest.length, 1);
      expect(devForest.treeCount, 1);
      expect(forest, isNot(contains(tree1)));
      expect(forest, contains(tree2));
    });

    test('uprootAll Test', () async {
      final tree1 = MockLogTree();
      final tree2 = MockLogTree();

      final trees = [tree1, tree2];
      devForest.plantAll(trees);

      expect((await devForest.forest).length, 2);

      devForest.uprootAll();
      final forest = await devForest.forest;
      expect(forest, isEmpty);
      expect(devForest.treeCount, 0);
      expect(forest, isNot(contains(tree1)));
      expect(forest, isNot(contains(tree2)));
    });

    test('set level', () {
      devForest.level = Level.INFO;
      expect(devForest.level, Level.INFO);

      devForest.level = Level.FINE;
      expect(devForest.level, Level.FINE);
    });

    test('supportedTypes', () {
      expect(devForest.supportedTypes, isNotNull);
      expect(devForest.supportedTypes, isEmpty);

      final tree = MockAnalyticsTree();
      devForest.plant(tree);

      when(tree.supportedTypes).thenReturn({String, num});
      expect(devForest.supportedTypes, containsAll({String, num}));

      expect(devForest.isSupportedType(num), isTrue);
    });
  });

  group('LogTree', () {
    test('performLog', () {
      final tree = MockLogTree();
      devForest.plant(tree);

      final record = LogRecord(Level.INFO, 'test', 'loggerName');

      when(tree.performLog(record)).thenReturn(null);

      devForest.performLog(record);

      verify(tree.performLog(record)).called(1);
    });
  });

  group('AnalyticsTree', () {
    test('performLogEvent', () {
      final tree = MockAnalyticsTree();
      devForest.plant(tree);

      final eventName = 'testEvent';

      when(tree.performLogEvent(name: eventName)).thenReturn(null);

      devForest.performLogEvent(name: eventName);

      verify(tree.performLogEvent(name: eventName)).called(1);
    });

    test('isSupportedType', () {
      final tree = MockAnalyticsTree();
      devForest.plant(tree);
      when(tree.supportedTypes).thenReturn({String});

      devForest.isSupportedType(String);

      verify(tree.supportedTypes).called(1);

      verifyNoMoreInteractions(tree);
    });

    test('reset', () {
      final tree = MockAnalyticsTree();
      devForest.plant(tree);
      when(tree.reset()).thenReturn(null);

      devForest.reset();

      verify(tree.reset()).called(1);

      verifyNoMoreInteractions(tree);
    });

    test('flush', () {
      final tree = MockAnalyticsTree();
      devForest.plant(tree);
      when(tree.flush()).thenReturn(null);

      devForest.flush();

      verify(tree.flush()).called(1);

      verifyNoMoreInteractions(tree);
    });

    test('timingEvent', () {
      final tree = MockAnalyticsTree();
      devForest.plant(tree);
      when(tree.timingEvent('time')).thenReturn(null);

      devForest.timingEvent('time');

      verify(tree.timingEvent('time')).called(1);

      verifyNoMoreInteractions(tree);
    });
  });

  group('UserAnalyticsTree', () {
    test('performLogEvent', () {
      final tree = MockUserAnalyticsTree();
      devForest.plant(tree);

      final name = 'id';
      final value = 'id';

      when(tree.setUserProperty(name, value)).thenReturn(null);

      devForest.setUserProperty(name, value);

      verify(tree.setUserProperty(name, value)).called(1);
    });

    test('setUserId', () {
      final tree = MockUserAnalyticsTree();
      devForest.plant(tree);

      final userId = 'testUser';

      when(tree.setUserId(userId)).thenReturn(null);

      devForest.setUserId(userId);

      verify(tree.setUserId(userId)).called(1);

      verifyNoMoreInteractions(tree);
    });

    test('setEmail', () {
      final tree = MockUserAnalyticsTree();
      devForest.plant(tree);

      final email = 'test@test.com';
      when(tree.setEmail(email)).thenReturn(null);

      devForest.setEmail(email);

      verify(tree.setEmail(email)).called(1);

      verifyNoMoreInteractions(tree);
    });

    test('setUid', () {
      final tree = MockUserAnalyticsTree();
      devForest.plant(tree);

      final uid = '1234567890abcdefg';

      when(tree.setUid(uid)).thenReturn(null);

      devForest.setUid(uid);

      verify(tree.setUid(uid)).called(1);

      verifyNoMoreInteractions(tree);
    });

    test('setPhone', () {
      final tree = MockUserAnalyticsTree();
      devForest.plant(tree);

      final phone = '0101234567';

      when(tree.setPhone(phone)).thenAnswer((_) => null);
      devForest.setPhone(phone);

      verify(tree.setPhone(phone)).called(1);

      verifyNoMoreInteractions(tree);
    });

    test('setUserName', () {
      final tree = MockUserAnalyticsTree();
      devForest.plant(tree);

      final userName = 'John Doe';

      when(tree.setUserName(userName)).thenReturn(null);

      devForest.setUserName(userName);

      verify(tree.setUserName(userName)).called(1);

      verifyNoMoreInteractions(tree);
    });

    test('union', () {
      final tree = MockUserAnalyticsTree();
      devForest.plant(tree);

      final property = {
        'name': ['value']
      };

      when(tree.union(property)).thenReturn(null);

      devForest.union(property);

      verify(tree.union(property)).called(1);

      verifyNoMoreInteractions(tree);
    });

    test('increment', () {
      final tree = MockUserAnalyticsTree();
      devForest.plant(tree);

      final property = {'name': 1};

      when(tree.increment(property)).thenReturn(null);

      devForest.increment(property);

      verify(tree.increment(property)).called(1);

      verifyNoMoreInteractions(tree);
    });

    test('setOnce', () {
      final tree = MockUserAnalyticsTree();
      devForest.plant(tree);

      final property = {'name': 1};

      when(tree.setOnce(property)).thenReturn(null);

      devForest.setOnce(property);

      verify(tree.setOnce(property)).called(1);

      verifyNoMoreInteractions(tree);
    });

    test('reset', () {
      final tree = MockUserAnalyticsTree();
      devForest.plant(tree);

      when(tree.reset()).thenAnswer((_) => null);

      devForest.reset();

      verify(tree.reset()).called(1);

      verifyNoMoreInteractions(tree);
    });

    test('flush', () {
      final tree = MockUserAnalyticsTree();
      devForest.plant(tree);

      when(tree.flush()).thenReturn(null);

      devForest.flush();

      verify(tree.flush()).called(1);

      verifyNoMoreInteractions(tree);
    });
  });

  group('CrashReportTree', () {
    test('performReportError 는 debugMode 에서는 불리지 않아야 함', () {
      final tree = MockCrashReportTree();
      devForest.plant(tree);

      final error = StateError('test');
      final stack = StackTrace.empty;
      when(tree.performReportError(error, stack)).thenReturn(null);

      devForest.performReportError(error, stack);

      verifyNever(tree.performReportError(error, stack));
    });

    test('performReportError  productionMode ', () {
      final tree = MockCrashReportTree();
      prodForest.plant(tree);

      final error = StateError('test');
      final stack = StackTrace.empty;
      when(tree.performReportError(error, stack)).thenReturn(null);

      prodForest.performReportError(error, stack);

      verify(tree.performReportError(error, stack)).called(1);
    });

    test('performReportError - productionMode ', () {
      final tree = MockCrashReportTree();
      prodForest.plant(tree);

      final details = FlutterErrorDetails();
      when(tree.performReportFlutterError(details)).thenReturn(null);

      prodForest.performReportFlutterError(details);

      verify(tree.performReportFlutterError(details)).called(1);
    });

    test('performReportError - devMode ', () {
      final tree = MockCrashReportTree();
      devForest.plant(tree);

      final details = FlutterErrorDetails();
      when(tree.performReportFlutterError(details)).thenReturn(null);

      devForest.performReportFlutterError(details);

      verifyNever(tree.performReportFlutterError(details));
    });
  });

  test('isAlphaNumeric', () {
    expect('a'.isAlphaNumeric, isTrue);
    expect('한글'.isAlphaNumeric, isFalse);
  });

  group('DeveloperTree', () {
    test('performLog', () {
      final tree = DeveloperTree();
      final logRecord = LogRecord(Level.INFO, '이것은 로그', 'test');
      tree.performLog(logRecord);
    });
  });
}

class TestTree extends Tree {
  @override
  void dispose() {}
}

class MockLogTree extends Mock with LogTree implements LogTree, Tree {}

class MockAnalyticsTree extends Mock
    with AnalyticsTree, Tree
    implements AnalyticsTree, Tree {}

class MockUserAnalyticsTree extends Mock
    with UserAnalyticsTree
    implements UserAnalyticsTree, Tree {}

class MockCrashReportTree extends Mock implements CrashReportTree, Tree {}

class ProdForest extends Forest {
  @override
  bool get isInDebugMode => false;
}

class MockForest extends Mock implements Forest {}
