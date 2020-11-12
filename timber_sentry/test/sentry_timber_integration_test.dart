import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sentry/sentry.dart';
import 'package:sentry/src/hub_adapter.dart';
import 'package:timber/timber.dart';

import 'package:timber_sentry/src/sentry_timber_integration.dart';
import 'package:timber_sentry/src/sentry_tree.dart';

void main() {
  test('register test', () async {
    var integration = SentryTimberIntegration();

    final hub = MockHub();
    integration(hub, SentryOptions(dsn: 'test'));

    expect(Timber.instance.treeCount, 1);

    final tree = (await Timber.instance.forest).first;
    expect(tree, isA<SentryTree>());
    final sentryTree = tree as SentryTree;
    expect(sentryTree.hub, hub);
  });
}

class MockHub extends Mock implements HubAdapter {}
