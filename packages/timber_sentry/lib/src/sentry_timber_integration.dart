import 'package:sentry/sentry.dart';

// ignore: implementation_imports
import 'package:sentry/src/hub.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:timber/timber.dart';

import 'sentry_tree.dart';

/// Sentry integration for Timber.
/// Integration that capture errors on the [FlutterError.onError] handler.
///
/// Remarks:
///   - Most UI and layout related errors (such as
///     [these](https://flutter.dev/docs/testing/common-errors)) are AssertionErrors
///     and are stripped in release mode. See [Flutter build modes](https://flutter.dev/docs/testing/build-modes).
///     So they only get caught in debug mode.
class SentryTimberIntegration extends Integration<SentryFlutterOptions> {
  late SentryTree _tree;
  Function(SentryLevel level, String message)? _logger;

  final SentryLevel minEventLevel;
  final SentryLevel minBreadcrumbLevel;

  SentryTimberIntegration(
      {this.minEventLevel = SentryLevel.error,
      this.minBreadcrumbLevel = SentryLevel.info});

  @override
  void call(Hub hub, SentryOptions options) {
    _logger = options.logger;

    _tree = SentryTree(hub,
        minEventLevel: minEventLevel, minBreadcrumbLevel: minBreadcrumbLevel);

    Timber.instance.plant(_tree);
    _logger?.call(SentryLevel.debug, 'SentryTimberIntegration installed.');
    options.sdk.addIntegration('sentryTimberIntegration');
  }
}
