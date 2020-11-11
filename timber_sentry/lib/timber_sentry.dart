library timber_sentry;

import 'dart:collection';

import 'package:async/async.dart';
import 'package:flutter/src/foundation/assertions.dart';
import 'package:logging/logging.dart' as $logging;
import 'package:package_info/package_info.dart';
import 'package:sentry/sentry.dart';

import 'package:timber/timber.dart';

const BUFFER_SIZE = 200;

class SentryTree extends Tree with CrashReportTree, LogTree {
  final SentryClient _client;
  final _buffer = DoubleLinkedQueue<Breadcrumb>();
  final _logger = $logging.Logger('SentryTree');
  final _releaseMemo = AsyncMemoizer();

  SentryTree(this._client);

  @override
  void performLog($logging.LogRecord record) async {
    final level = record.level;
    if (level <= $logging.Level.FINE) {
      return;
    }

    final message = Message(record.message);

    var severityLevel = _level(record.level);

    _buffer.addLast(Breadcrumb(
      level: _level(record.level),
      message: record.message,
      type: record.loggerName,
      data: record.object,
      timestamp: record.time,
    ));
    if (_buffer.length > BUFFER_SIZE) {
      _buffer.removeFirst();
    }

    if (record.level < $logging.Level.WARNING) {
      // do not capture
      return;
    }

    // Capture Event

    var packageInfo = await PackageInfo.fromPlatform();

    String packageName = packageInfo.packageName;
    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;

    try {
      final sentryId = await _client.captureEvent(SentryEvent(
        level: severityLevel,
        stackTrace: record.stackTrace,
        release: '$version+$buildNumber',
        exception: record.error,
        message: message,
        logger: record.loggerName,
        breadcrumbs: _buffer.toList(),
      ));
    } catch (e) {}
  }

  SentryLevel _level($logging.Level level) {
    if (level < $logging.Level.INFO) {
      return SentryLevel.debug;
    } else if (level < $logging.Level.WARNING) {
      return SentryLevel.info;
    } else if (level == $logging.Level.WARNING) {
      return SentryLevel.warning;
    } else if (level == $logging.Level.SEVERE) {
      return SentryLevel.error;
    } else if (level == $logging.Level.SHOUT) {
      return SentryLevel.fatal;
    }

    //
    assert(true);
    return SentryLevel.debug;
  }

  @override
  void performReportError(error, stackTrace) async {
    _logger.info('Reporting to Sentry.io...');
    // 프로덕션 모드에서는 exception과 stacktrace를 Sentry로 보냅니다.
    try {
// Capture Event

      var packageInfo = await PackageInfo.fromPlatform();

      final eventId = await _client.captureEvent(SentryEvent(
        stackTrace: stackTrace,
        release: await release,
        exception: error,
        breadcrumbs: _buffer.toList(),
      ));

      _logger.info('Success! Event ID: $eventId');
    } catch (e) {
      _logger.info('Failed to report to Sentry.io: $e');
    }
  }

  @override
  void performReportFlutterError(FlutterErrorDetails errorDetails) async {
    _logger.info('Reporting to Sentry.io...');
    // 프로덕션 모드에서는 exception과 stacktrace를 Sentry로 보냅니다.
    try {
      final eventId = await _client.captureEvent(SentryEvent(
        stackTrace: errorDetails.stack,
        release: await release,
        exception: errorDetails.exception,
        breadcrumbs: _buffer.toList(),
      ));

      _logger.info('Success! Event ID: $eventId');
    } catch (e) {
      _logger.info('Failed to report to Sentry.io: $e');
    }
  }

  @override
  void dispose() {
    return _client?.close();
  }

  Future<String> get release async {
    var packageInfo = await PackageInfo.fromPlatform();
    final packageName = packageInfo.packageName;
    final version = packageInfo.version;
    final buildNumber = packageInfo.buildNumber;
    return '$version+$buildNumber';
  }
}
