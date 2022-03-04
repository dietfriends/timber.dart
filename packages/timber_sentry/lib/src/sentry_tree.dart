library timber_sentry;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart' as $logging;
import 'package:sentry/sentry.dart';

// ignore: implementation_imports
import 'package:sentry/src/hub.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:timber/timber.dart';

import 'provider.dart';

const _LOGGER_NAME = 'SentryTree';
final _logger = $logging.Logger(_LOGGER_NAME);

class SentryTree extends Tree with LogTree {
  final SentryLevel minEventLevel;
  final SentryLevel minBreadcrumbLevel;
  final Hub hub;

  SentryTree(this.hub,
      {SentryFlutterOptions? sentryOptions,
      this.minBreadcrumbLevel = SentryLevel.info,
      this.minEventLevel = SentryLevel.error}) {
    /*
    Sentry.init((options) async {
      return options
        ..debug = sentryOptions?.debug ?? options.release
        ..release = sentryOptions?.release ?? options.release
        ..environment = sentryOptions?.environment ??
            await environmentProvider?.provide() ??
            options.environment
        ..beforeBreadcrumb =
            sentryOptions?.beforeBreadcrumb ?? options.beforeBreadcrumb
        ..compressPayload = sentryOptions?.compressPayload
        ..diagnosticLevel = sentryOptions?.diagnosticLevel
        ..dist = sentryOptions?.dist ?? options.dist
        ..dsn = sentryOptions?.dsn ?? options.dsn
        ..logger = _defaultLogger
        ..sampleRate = sentryOptions?.sampleRate ?? options.sampleRate
        ..maxBreadcrumbs =
            sentryOptions?.maxBreadcrumbs ?? options.maxBreadcrumbs;
    });*/
  }

  /// do not log if it's lower than min. required level.
  bool _isLoggable(SentryLevel level, SentryLevel minLevel) =>
      level.ordinal >= minLevel.ordinal;

  /// Captures a Sentry Event if the min. level is equal or higher than the min. required level.
  @override
  void performLog($logging.LogRecord record) async {
    final level = record.level.toSentryLevel;

    // Capture Event

    _captureEvent(level, record);
    _addBreadcrumb(level, record);
  }

  /// Captures an event with the given record
  void _captureEvent(SentryLevel sentryLevel, $logging.LogRecord record) async {
    if (_isLoggable(sentryLevel, minEventLevel)) {
      final sentryId = await hub.captureEvent(SentryEvent(
        level: record.level.toSentryLevel,
        // stackTrace: record.stackTrace,
        // exception: record.error as SentryException?,
        message: SentryMessage(record.message),
        logger: record.loggerName,
      ));
    }
  }

  /// Adds a breadcrumb
  void _addBreadcrumb(SentryLevel sentryLevel, $logging.LogRecord record) {
    // checks the breadcrumb level
    if (_isLoggable(sentryLevel, minBreadcrumbLevel)) {
      hub.addBreadcrumb(record.toBreadcrumb);
    }
  }

  @override
  void dispose() {
    hub.close();
  }

  @override
  String get loggerName => _LOGGER_NAME;
}

extension LevelX on $logging.Level {
  /// Converts from Logging Level to SentryLevel.
  /// Fallback to SentryLevel.DEBUG.
  SentryLevel get toSentryLevel {
    if (this >= $logging.Level.FINEST && this < $logging.Level.INFO) {
      return SentryLevel.debug;
    } else if (this >= $logging.Level.INFO && this < $logging.Level.WARNING) {
      return SentryLevel.info;
    } else if (this >= $logging.Level.WARNING && this < $logging.Level.SEVERE) {
      return SentryLevel.warning;
    } else if (this >= $logging.Level.SEVERE && this < $logging.Level.SHOUT) {
      return SentryLevel.error;
    } else if (this >= $logging.Level.SHOUT && this < $logging.Level.OFF) {
      return SentryLevel.fatal;
    } else {
      return SentryLevel.debug;
    }
  }
}

extension LogRecordX on $logging.LogRecord {
  Breadcrumb get toBreadcrumb {
    var data;
    if (object is Map<String, dynamic>) {
      data = object;
    }
    assert(data == null || data is Map<String, dynamic>);

    return Breadcrumb(
      level: level.toSentryLevel,
      message: message,
      type: loggerName,
      data: data,
      timestamp: time,
    );
  }
}

/*
extension SentryLevelX on SentryLevel {
  $logging.Level get toLevel {
    switch (this) {
      case SentryLevel.debug:
        return $logging.Level.FINEST;
      case SentryLevel.fatal:
        return $logging.Level.SHOUT;
      case SentryLevel.warning:
        return $logging.Level.WARNING;
      case SentryLevel.error:
        return $logging.Level.SEVERE;
      case SentryLevel.info:
        return $logging.Level.INFO;
      default:
        return $logging.Level.FINEST;
    }
  }
}
*/
