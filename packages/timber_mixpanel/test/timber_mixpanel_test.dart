// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timber_mixpanel/timber_mixpanel.dart';

class MockMixpanel extends Mock implements Mixpanel {}

void main() {
  late MixpanelTree tree;
  late Mixpanel mixpanel;
  var channel;
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    final log = <MethodCall>[];

    mixpanel = MockMixpanel();
    channel = const MethodChannel('net.amond.flutter_mixpanel');

// Register the mock handler.
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
    });
    tree = MixpanelTree(mixpanel);
  });

  test('performLogEvent', () {
    tree.performLogEvent(name: 'test');
  });

  test('setUserProperty', () {
    tree.setUserProperty('email', 'email');
  });

  test('setUserId', () {
    tree.setUserId('id');
  });

  test('timingEvent - success', () {
    tree.timingEvent('timing');
  });
  test('timingEvent - error', () {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'time') {
        throw StateError('test');
      }
    });
    tree.timingEvent('timing');
  });

  test('union', () {
    tree.union({
      'union': ['test']
    });
  });

  test('isSupportedType', () {
    expect(tree.isSupportedType(DateTime), isTrue);
    //expect(tree.isSupportedType(LocalDateTime), isTrue);
    //expect(tree.isSupportedType(LocalDate), isTrue);
    expect(tree.isSupportedType(String), isTrue);
    expect(tree.isSupportedType(bool), isTrue);
    expect(tree.isSupportedType(int), isTrue);
    expect(tree.isSupportedType(double), isTrue);
    expect(tree.isSupportedType(num), isTrue);
    expect(tree.isSupportedType(Map), isTrue);
    expect(tree.isSupportedType(List), isTrue);
  });
}

class TestType {
  @override
  String toString() {
    return 'Yay';
  }
}
