library timber_mixpanel;

import 'dart:io';

import 'package:flutter_mixpanel/flutter_mixpanel.dart';
import 'package:logging/logging.dart';
import 'package:quiver/strings.dart';
import 'package:timber/timber.dart';

//import 'package:time_machine/time_machine.dart' show LocalDateTime, LocalDate;
import 'package:pedantic/pedantic.dart';

final _logger = Logger('MixpanelTree');

class MixpanelTree extends Tree with AnalyticsTree, UserAnalyticsTree {
  @override
  final Set<Type> supportedTypes = {
    String,
    num,
    Uri,
    DateTime,
    List,
    //LocalDate,
    //LocalDateTime,
    bool,
    int,
    double,
    Map
  };
  @override
  String emailProperty = '\$email';
  @override
  String phoneProperty = '\$phone';
  @override
  String nameProperty = '\$name';

  @override
  Future<void> performLogEvent(
      {required String name, Map<String, dynamic>? parameters}) async {
    assert(isNotBlank(name));
    try {
      unawaited(
          FlutterMixpanel.track(name, convertMixpanelProperty(parameters)));
      _logger.info(name);
    } catch (e, s) {
      _logger.severe('logEvent error : $e', e, s);
    }
  }

  @override
  Future<void> setUserProperty(String name, value) {
    return FlutterMixpanel.people.setProperty(name, value);
  }

  @override
  Future<void> setUserId(String id) async {
    unawaited(FlutterMixpanel.identify(id));
    if (Platform.isAndroid) {
      unawaited(FlutterMixpanel.people.identify(id));
    }
  }

  @override
  Future<void> timingEvent(String name) async {
    try {
      await FlutterMixpanel.time(name);
    } catch (e, s) {
      _logger.severe('timingEvent error : $e', e, s);
    }
  }

  @override
  Future<void> union(Map<String, List> properties) {
    return FlutterMixpanel.people.union(properties);
  }

  Map<String, dynamic> convertMixpanelProperty(Map<String, dynamic>? input) {
    if (input == null) {
      return <String, dynamic>{};
    }
    var mixpanel = Map<String, dynamic>.of(input);

    input.forEach((key, value) {
      if (isSupportedType(value.runtimeType)) {
        if (value is DateTime) {
          //mixpanel[key] = value.toUtc();
        }
        //if (value is LocalDateTime) {
        //  mixpanel[key] = value.toDateTimeLocal().toUtc();
        //}
        //if (value is LocalDate) {
        //  mixpanel[key] = value.toDateTimeUnspecified().toUtc();
        //}
      } else {
        _logger.fine(() => 'unsupported type: $key - ${value.runtimeType}');
        mixpanel[key] = value.toString();
      }
    });
    return mixpanel;
  }

  @override
  bool isSupportedEventName(String name) {
    return true;
  }

  @override
  Future<void> increment(Map<String, num> properties) async {
    try {
      return FlutterMixpanel.people.increment(properties);
    } catch (e, s) {
      _logger.severe('increment error : $e', e, s);
      return;
    }
  }

  @override
  Future<void> setOnce(Map<String, dynamic> properties) {
    return FlutterMixpanel.people.setOnce(convertMixpanelProperty(properties));
  }

  @override
  Future<void> flush() {
    return FlutterMixpanel.flush();
  }

  @override
  Future<void> reset() {
    return FlutterMixpanel.reset();
  }

  @override
  void dispose() async {
    return FlutterMixpanel.flush();
  }

  @override
  Future<void> setCurrentScreen(
      {String? screenName, String screenClassOverride = 'Flutter'}) async {}
}
