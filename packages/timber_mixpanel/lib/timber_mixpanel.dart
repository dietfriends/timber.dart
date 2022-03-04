library timber_mixpanel;

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:quiver/strings.dart';
import 'package:timber/timber.dart';

//import 'package:time_machine/time_machine.dart' show LocalDateTime, LocalDate;

final _logger = Logger('MixpanelTree');

class MixpanelTree extends Tree with AnalyticsTree, UserAnalyticsTree {
  final Mixpanel _mixpanel;
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

  MixpanelTree(this._mixpanel);

  @override
  Future<void> performLogEvent(
      {required String name, Map<String, dynamic>? parameters}) async {
    assert(isNotBlank(name));
    try {
      _mixpanel.track(name, properties: parameters);
      _logger.info(name);
    } catch (e, s) {
      _logger.severe('logEvent error : $e', e, s);
    }
  }

  @override
  Future<void> setUserProperty(String name, value) async {
    return _mixpanel.getPeople().set(name, value);
  }

  @override
  Future<void> setUserId(String id) async {
    _mixpanel.identify(id);
  }

  @override
  Future<void> timingEvent(String name) async {
    try {
      _mixpanel.timeEvent(name);
    } catch (e, s) {
      _logger.severe('timingEvent error : $e', e, s);
    }
  }

  @override
  Future<void> union(Map<String, List> properties) async {
    for (var key in properties.keys) {
      final value = properties[key];
      if (value != null) {
        _mixpanel.getPeople().union(key, value);
      }
    }
  }

  @override
  bool isSupportedEventName(String name) {
    return true;
  }

  @override
  Future<void> increment(Map<String, num> properties) async {
    try {
      for (var key in properties.keys) {
        final value = properties[key];
        if (value != null) {
          _mixpanel.getPeople().increment(key, value.toDouble());
        }
      }
    } catch (e, s) {
      _logger.severe('increment error : $e', e, s);
      return;
    }
  }

  @override
  Future<void> setOnce(Map<String, dynamic> properties) async {
    for (var key in properties.keys) {
      final value = properties[key];
      if (value != null) {
        _mixpanel.getPeople().setOnce(key, value);
      }
    }
  }

  @override
  Future<void> flush() async {
    return _mixpanel.flush();
  }

  @override
  Future<void> reset() async {
    return _mixpanel.reset();
  }

  @override
  void dispose() async {
    return _mixpanel.flush();
  }

  @override
  Future<void> setCurrentScreen(
      {String? screenName, String screenClassOverride = 'Flutter'}) async {}
}
