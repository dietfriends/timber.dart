import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:timber/timber.dart';
import 'package:mockito/mockito.dart';

void main() {
  Forest forest;
  setUp(() {
    forest = Forest();
  });

  group('Forest', () {
    test('init Test', () {
      forest.init();
    });

    test('dispose Test', () {
      forest.dispose();
    });
  });

  group('LogTree', () {
    test('performLog', () {
      final tree = MockLogTree();
      forest.plant(tree);

      final record = LogRecord(Level.INFO, 'test', 'loggerName');

      when(tree.performLog(record)).thenReturn(null);

      forest.performLog(record);

      verify(tree.performLog(record)).called(1);
    });
  });

  group('AnalyticsTree', () {
    test('performLogEvent', () {
      final tree = MockAnalyticsTree();
      forest.plant(tree);

      final eventName = 'testEvent';

      when(tree.performLogEvent(name: eventName)).thenReturn(null);

      forest.performLogEvent(name: eventName);

      verify(tree.performLogEvent(name: eventName)).called(1);
    });
  });

  group('CrashReportTree', () {
    test('performReportError 는 debugMode 에서는 불리지 않아야 함', () {
      final tree = MockCrashReportTree();
      forest.plant(tree);

      final error = StateError('test');
      final stack = StackTrace.empty;
      when(tree.performReportError(error, stack)).thenReturn(null);

      forest.performReportError(error, stack);

      verifyNever(tree.performReportError(error, stack));
    });

    test('performReportError  productionMode ', () {
      final prodForest = ProdForest();
      final tree = MockCrashReportTree();
      prodForest.plant(tree);

      final error = StateError('test');
      final stack = StackTrace.empty;
      when(tree.performReportError(error, stack)).thenReturn(null);

      prodForest.performReportError(error, stack);

      verify(tree.performReportError(error, stack)).called(1);
    });
  });
}

class MockLogTree extends Mock with LogTree, Tree {}

class MockAnalyticsTree extends Mock with AnalyticsTree, Tree {}

class MockCrashReportTree extends Mock with CrashReportTree, Tree {}

class ProdForest extends Forest {
  @override
  bool get isInDebugMode => false;
}
