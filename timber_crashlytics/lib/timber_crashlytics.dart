library timber_crashlytics;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart' as $logging;
import 'package:timber/timber.dart';

/// A Calculator.
class CrashlyticsTree with UserAnalyticsTree, LogTree, CrashReportTree {
  final FirebaseCrashlytics _crashlytics;

  CrashlyticsTree([FirebaseCrashlytics firebaseCrashlytics])
      : _crashlytics = firebaseCrashlytics ?? FirebaseCrashlytics.instance;

  @override
  void performLog($logging.LogRecord record) {
    final level = record.level;
    if (level <= $logging.Level.FINE) {
      return;
    }
    if (level < $logging.Level.WARNING) {
      _crashlytics.log(record.message);
    } else {
      try {
        _crashlytics.recordError(
          record.error,
          record.stackTrace,
          reason: record.message,
        );
      } finally {}
    }
  }

  @override
  void performReportError(error, stackTrace) {
    _crashlytics.recordError(error, stackTrace);
  }

  @override
  void performReportFlutterError(FlutterErrorDetails flutterErrorDetails) {
    _crashlytics.recordError(
        flutterErrorDetails.exceptionAsString(), flutterErrorDetails.stack,
        reason: flutterErrorDetails.context,
        printDetails: false,
        information: flutterErrorDetails.informationCollector == null
            ? null
            : flutterErrorDetails.informationCollector());
  }

  @override
  Future<void> setUserProperty(String name, dynamic value) async {
    return _crashlytics.setCustomKey(name, value);
  }

  @override
  Future<void> setUid(String uid) {
    return _crashlytics.setUserIdentifier(uid);
  }

  @override
  Future<void> reset() async {
    // return _crashlytics.setUserIdentifier('');
  }
}
