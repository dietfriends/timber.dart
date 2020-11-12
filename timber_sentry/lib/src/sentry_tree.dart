library timber_sentry;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart' as $logging;
import 'package:sentry/sentry.dart';
// ignore: implementation_imports
import 'package:sentry/src/hub.dart';
import 'package:timber/timber.dart';

import 'provider.dart';

final _logger = $logging.Logger('SentryTree');

class SentryTree extends Tree with CrashReportTree, LogTree {
  final ReleaseProvider releaseProvider;
  final EnvironmentProvider environmentProvider;
  final UserProvider userProvider;
  final ContextsProvider contextsProvider;
  final SentryLevel minEventLevel;
  final SentryLevel minBreadcrumbLevel;
  final Hub hub;

  SentryTree(this.hub,
      {SentryOptions sentryOptions,
      this.userProvider,
      this.contextsProvider,
      this.environmentProvider,
      this.releaseProvider,
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
        stackTrace: record.stackTrace,
        exception: record.error,
        message: Message(record.message),
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
  void performReportError(dynamic error, dynamic stackTrace) async {
    _logger.info('performReportError');
    _logger.info('Reporting to Sentry.io... ');
    // 프로덕션 모드에서는 exception과 stacktrace를 Sentry로 보냅니다.
    await _captureError(error, stackTrace);
  }

  Future<SentryId> _captureError(dynamic error, dynamic stackTrace) async {
    try {
      // Capture Event
      final eventId = await hub.captureEvent(SentryEvent(
          stackTrace: stackTrace,
          release: await releaseProvider?.provide(),
          exception: error,
          environment: await environmentProvider?.provide(),
          user: await userProvider?.provide(),
          contexts: await contextsProvider?.provide()));
      _logger.info('Success! Event ID: $eventId');
      return eventId;
    } catch (e) {
      _logger.info('Failed to report to Sentry.io: $e', e);
      return null;
    }
  }

  @override
  void performReportFlutterError(FlutterErrorDetails errorDetails) async {
    _logger.info('Reporting to Sentry.io...');
    // 프로덕션 모드에서는 exception과 stacktrace를 Sentry로 보냅니다.
    await _captureFlutterError(errorDetails);
  }

  Future<void> _captureFlutterError(FlutterErrorDetails errorDetails) async {
    try {
      final eventId = await hub.captureEvent(SentryEvent(
          stackTrace: errorDetails.stack,
          release: await releaseProvider?.provide(),
          exception: errorDetails.exception,
          message: Message(errorDetails.toString()),
          environment: await environmentProvider?.provide(),
          user: await userProvider?.provide(),
          contexts: await contextsProvider?.provide()));

      _logger.info('Success! Event ID: $eventId');
    } catch (e) {
      _logger.info('Failed to report to Sentry.io: $e', e);
    }
  }

  @override
  void dispose() {
    return hub?.close();
  }
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
    return Breadcrumb(
      level: level.toSentryLevel,
      message: message,
      type: loggerName,
      data: object,
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
