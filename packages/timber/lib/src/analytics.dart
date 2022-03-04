import 'package:meta/meta.dart';

import 'tree.dart';

abstract class AnalyticsTree {
  Set<Type> get supportedTypes;

  @protected
  bool isSupportedType(Type value) {
    assert(value is Type);
    // TODO(amond): if value is not type, false?
    //if (value is! Type) {
    //  return false;
    //}
    return supportedTypes.any((type) {
      return type == value;
    });
    return supportedTypes.contains(value);
  }

  @protected
  bool isSupportedEventName(String name);

  Future<void> performLogEvent(
      {required String name, Map<String, dynamic>? parameters});

  Future<void> timingEvent(String name);

  Future<void> setCurrentScreen(
      {required String? screenName, String screenClassOverride = 'Flutter'});

  Future<void> reset();

  Future<void> flush();
}

final _alphaNumeric = RegExp(r'^[a-zA-Z0-9_]*$');

extension StringX on String {
  bool get isAlphaNumeric {
    return _alphaNumeric.hasMatch(this);
  }
}

abstract class UserAnalyticsTree {
  String get emailProperty => 'email';

  String get phoneProperty => 'phone';

  String get userIdProperty => 'userId';

  String get uidProperty => 'uid';

  String get nameProperty => 'name';

  /// userId 설정
  Future<void> setUserId(String id) {
    return setUserProperty(userIdProperty, id);
  }

  /// email 설정
  Future<void> setEmail(String email) async {
    return setUserProperty(emailProperty, email);
  }

  /// 전화번호 설정
  Future<void> setPhone(String phone) async {
    return setUserProperty(phoneProperty, phone);
  }

  /// uid 설정
  Future<void> setUid(String uid) {
    return setUserProperty(uidProperty, uid);
  }

  Future<void> union(Map<String, List<dynamic>> properties);

  Future<void> setUserProperty(String name, dynamic value);

  Future<void> increment(Map<String, num> properties);

  Future<void> setOnce(Map<String, dynamic> properties);

  Future<void> setUserName(value) {
    return setUserProperty(nameProperty, value);
  }

  Future<void> reset();

  Future<void> flush();
}
