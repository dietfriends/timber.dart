import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:timber_firebase_analytics/timber_firebase_analytics.dart';
import 'package:time_machine/time_machine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final analytics = FirebaseAnalytics();
  FirebaseAnalytics mock;
  const channel = MethodChannel('plugins.flutter.io/firebase_analytics');
  MethodCall methodCall;
  FirebaseAnalyticsTree treeWithMock;
  FirebaseAnalyticsTree tree;

  setUp(() async {
    channel.setMockMethodCallHandler((MethodCall m) async {
      methodCall = m;
    });
    tree = FirebaseAnalyticsTree(analytics);
    mock = MockFirebaseAnalytics();
    treeWithMock = FirebaseAnalyticsTree(mock);
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
    methodCall = null;
  });

  group('FirebaseAnalyticsTree', () {
    test('should thorws exception', () {
      expect(() => FirebaseAnalyticsTree(null), throwsAssertionError);
    });
  });
  group('setCurrentScreen', () {
    test('should throws error', () {
      expect(
          () => tree.setCurrentScreen(screenName: null), throwsArgumentError);
    });

    test('should call FirebaseAnalytics.setCurrentScreen', () async {
      final screen = 'Main';
      when(mock.setCurrentScreen(screenName: screen)).thenReturn(null);
      await treeWithMock.setCurrentScreen(screenName: screen);
      verify(mock.setCurrentScreen(screenName: screen));
      verifyNoMoreInteractions(mock);
    });
  });

  group('isSupportedType', () {
    test('should throw assertion error', () {
      expect(tree.isSupportedType(null), false);
    });

    test('should true', () {
      expect(tree.isSupportedType(String), isTrue);
      expect(tree.isSupportedType(bool), isTrue);
      expect(tree.isSupportedType(int), isTrue);
      expect(tree.isSupportedType(double), isTrue);
      expect(tree.isSupportedType(DateTime), isTrue);
      expect(tree.isSupportedType(LocalDateTime), isTrue);
      expect(tree.isSupportedType(LocalDate), isTrue);
    });
  });

  group('isSupportedEventName', () {
    test('null -> should false', () {
      expect(tree.isSupportedEventName(null), isFalse);
    });

    test('blank string should false', () {
      expect(tree.isSupportedEventName(' '), isFalse);
    });

    test('non-alphanumeric event should false', () {
      expect(tree.isSupportedEventName('한글'), isFalse);
    });
  });

  group('convertFirebaseProperty', () {
    test('if input is null, should return {}', () {
      expect(tree.convertFirebaseProperty(null), {});
    });

    test('DateTime should be converted String', () {
      final key = 'dateTime';
      final value = DateTime.utc(2020, 1, 1, 0, 0, 0);
      final converted = tree.convertFirebaseProperty({key: value});

      expect(converted.containsKey(key), isTrue);
      expect(converted[key], isA<String>());
      expect(converted[key], '2020-01-01T00:00:00');
    });

    test('LocalDateTime should be converted String', () {
      final key = 'LocalDateTime';
      final value = LocalDateTime(2020, 1, 1, 0, 0, 0);
      final converted = tree.convertFirebaseProperty({key: value});

      expect(converted.containsKey(key), isTrue);
      expect(converted[key], isA<String>());
      expect(converted[key], '2020-01-01T00:00:00');
    });

    test('LocalDate should be converted String', () {
      final key = 'LocalDate';
      final value = LocalDate(2020, 1, 1);
      final converted = tree.convertFirebaseProperty({key: value});

      expect(converted.containsKey(key), isTrue);
      expect(converted[key], isA<String>());
      expect(converted[key], '2020-01-01');
    });

    test('NotSupportedType should be converted String', () {
      final key = 'TestType';
      final value = TestType();
      final converted = tree.convertFirebaseProperty({key: value});

      expect(converted.containsKey(key), isTrue);
      expect(converted[key], isA<String>());
      expect(converted[key], 'foo');
    });

    test('non-alphanumeric key should be deleted', () {
      final key = '한글';
      final value = TestType();
      final converted = tree.convertFirebaseProperty({key: value});

      expect(converted.containsKey(key), isFalse);
    });
  });

  group('setUserProperty', () {
    test('non-alphanumeric user property', () async {
      final key = '한글';
      final value = 'bar';
      await treeWithMock.setUserProperty(key, value);
      verifyNever(mock.setUserProperty(name: key, value: value));
      verifyZeroInteractions(mock);
      verifyNoMoreInteractions(mock);
    });

    test('should call FirebaseAnalytics.setUserProperty method', () async {
      final key = 'foo';
      final value = 'bar';

      when(mock.setUserProperty(name: key, value: value)).thenReturn(null);
      await treeWithMock.setUserProperty(key, value);
      verify(mock.setUserProperty(name: key, value: value)).called(1);
    });

    test('if value is not string, the value should be converted to string',
        () async {
      final key = 'foo';
      final value = 1;
      final valueString = value.toString();

      when(mock.setUserProperty(name: 'key', value: value.toString()))
          .thenAnswer((_) => Future.value(null));

      await treeWithMock.setUserProperty(key, value);

      verify(mock.setUserProperty(name: key, value: valueString)).called(1);
      verifyNoMoreInteractions(mock);
    });
  });

  group('setUid', () {
    test('if value is not string, the value should be converted to string',
        () async {
      final value = '1';
      when(mock.setUserId(any)).thenReturn(null);
      await treeWithMock.setUid(value);
      verify(mock.setUserId(any)).called(1);
      verifyNoMoreInteractions(mock);
    });
  });

  group('reset', () {
    test("should call setUserId('')", () async {
      when(mock.setUserId('')).thenReturn(null);
      await treeWithMock.reset();
      verify(mock.setUserId('')).called(1);
      verifyNoMoreInteractions(mock);
    });
  });

  group('resetAnalyticsData', () {
    test("should call resetAnalyticsData('')", () async {
      when(mock.resetAnalyticsData()).thenReturn(null);
      await treeWithMock.resetAnalyticsData();
      verify(mock.resetAnalyticsData()).called(1);
      verifyNoMoreInteractions(mock);
    });
  });

  group('performLogEvent', () {
    test('should call', () async {
      final key = 'foo';
      final value = {'foo': 'bar'};

      when(mock.logEvent(name: key, parameters: value)).thenReturn(null);

      await treeWithMock.performLogEvent(name: key, parameters: value);

      verify(mock.logEvent(name: key, parameters: value)).called(1);
      verifyNoMoreInteractions(mock);
    });
  });

  group('flush', () {
    test('should call nothing', () async {
      await treeWithMock.flush();
      verifyZeroInteractions(mock);
    });
  });

  group('increment', () {
    test('should call nothing', () async {
      await treeWithMock.increment({});
      verifyZeroInteractions(mock);
    });
  });

  group('setOnce', () {
    test('should call nothing', () async {
      await treeWithMock.setOnce({});
      verifyZeroInteractions(mock);
    });
  });

  group('timingEvent', () {
    test('should call nothing', () async {
      await treeWithMock.timingEvent('name');
      verifyZeroInteractions(mock);
    });
  });

  group('union', () {
    test('should call nothing', () async {
      await treeWithMock.union({});
      verifyZeroInteractions(mock);
    });
  });

  group('dispose', () {
    test('should call nothing', () async {
      treeWithMock.dispose();
      verifyZeroInteractions(mock);
    });
  });
}

class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

class TestType {
  @override
  String toString() {
    return 'foo';
  }
}
