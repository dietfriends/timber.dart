library timber_firebase_analytics;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:quiver/strings.dart' show isNotBlank;
import 'package:timber/timber.dart';
import 'package:time_machine/time_machine.dart' show LocalDate, LocalDateTime;

/// A Calculator.
class FirebaseAnalyticsTree extends Tree with AnalyticsTree, UserAnalyticsTree {
  final FirebaseAnalytics _firebaseAnalytics;

  FirebaseAnalyticsTree(this._firebaseAnalytics)
      : assert(_firebaseAnalytics != null);
  @override
  Set<Type> supportedTypes = {
    String,
    num,
    bool,
    DateTime,
    LocalDateTime,
    LocalDate
  };

  @override
  Future<void> setCurrentScreen(
      {String screenName, String screenClassOverride = 'Flutter'}) {
    if (screenName == null) {
      throw ArgumentError.notNull('screenName');
    }
    return _firebaseAnalytics.setCurrentScreen(
        screenName: screenName, screenClassOverride: screenClassOverride);
  }

  @override
  bool isSupportedEventName(String name) {
    return isNotBlank(name) && name.replaceAll(' ', '_').isAlphaNumeric;
  }

  Map<String, dynamic> convertFirebaseProperty(Map<String, dynamic> input) {
    if (input == null) {
      return {};
    }
    var properties = Map<String, dynamic>.of(input);

    input.forEach((key, value) {
      // only alpha numeric key is supported in Firebase Analytics
      if (key.isAlphaNumeric) {
        if (isSupportedType(value)) {
          if (value is DateTime) {
            properties[key] = value
                .toUtc()
                .toIso8601String()
                .replaceAll(RegExp(r'\.\d+Z*'), '');
          }
          if (value is LocalDateTime) {
            properties[key] = value
                .toDateTimeLocal()
                .toIso8601String()
                .replaceAll(RegExp(r'\.\d+Z*'), '');
          }
          if (value is LocalDate) {
            properties[key] = value.toString('yyyy-MM-dd');
          }
        } else {
          properties[key] = value.toString();
        }
      } else {
        properties.remove(key);
      }
    });
    return properties;
  }

  @override
  Future<void> setUserProperty(String name, dynamic value) {
    if (name.isAlphaNumeric) {
      // firebase 는 string 만 가능
      if (value is String) {
        return _firebaseAnalytics.setUserProperty(name: name, value: value);
      } else {
        return _firebaseAnalytics.setUserProperty(
            name: name, value: value.toString());
      }
    }
    return null;
  }

  @override
  Future<void> setUid(String uid) {
    return _firebaseAnalytics.setUserId(uid);
  }

  @override
  Future<void> reset() async {
    // TODO(amond): reset 이 필요한가?
    //return _firebaseAnalytics.resetAnalyticsData();
    return _firebaseAnalytics.setUserId('');
  }

  /// Clears all analytics data for this app from the device and resets the app instance id.
  Future<void> resetAnalyticsData() async {
    return _firebaseAnalytics.resetAnalyticsData();
  }

  @override
  Future<void> performLogEvent({String name, Map<String, dynamic> parameters}) {
    var eventName = name.replaceAll(' ', '_');
    var eventParams = convertFirebaseProperty(parameters);
    return _firebaseAnalytics.logEvent(
        name: eventName, parameters: eventParams);
  }

  @override
  Future<void> flush() {}

  @override
  Future<void> increment(Map<String, num> properties) {}

  @override
  Future<void> setOnce(Map<String, dynamic> properties) {}

  @override
  Future<void> timingEvent(String name) {}

  @override
  Future<void> union(Map<String, List> properties) {}

  @override
  void dispose() {}
}
