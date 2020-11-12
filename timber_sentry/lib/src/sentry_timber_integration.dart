import 'package:sentry/sentry.dart';

// ignore: implementation_imports
import 'package:sentry/src/hub.dart';
import 'package:timber/timber.dart';

import 'sentry_tree.dart';

/// Sentry integration for Timber.
class SentryTimberIntegration {
  SentryTree _tree;
  Function(SentryLevel level, String message) _logger;

  final SentryLevel minEventLevel;
  final SentryLevel minBreadcrumbLevel;

  SentryTimberIntegration(
      {this.minEventLevel = SentryLevel.error,
      this.minBreadcrumbLevel = SentryLevel.info});

  void call(Hub hub, SentryOptions options) {
    _logger = options.logger;

    _tree = SentryTree(hub,
        minEventLevel: minEventLevel, minBreadcrumbLevel: minBreadcrumbLevel);

    Timber.instance.plant(_tree);
    _logger?.call(SentryLevel.debug, 'SentryTimberIntegration installed.');
  }
}
