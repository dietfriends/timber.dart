import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:timber/timber.dart';
import 'package:mockito/mockito.dart';

void main() {
  test('Forest', () {
    final forest = Forest();

    final tree = MockLogTree();
    forest.plant(tree);

    final record = LogRecord(Level.INFO, 'test', 'loggerName');

    when(tree.performLog(record)).thenReturn(null);

    forest.performLog(record);

    verify(tree.performLog(record)).called(1);
  });
}

class MockLogTree extends Mock with LogTree, Tree {}
