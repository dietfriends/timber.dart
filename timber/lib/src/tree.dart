import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart' as $logging;

class Timber {}

abstract class Tree {
  /// Whether the VM is running in debug mode.
  ///
  /// This is useful to decide whether a report should be sent to sentry. Usually
  /// reports from dev mode are not very useful, as these happen on developers'
  /// workspaces rather than on users' devices in production.
  bool get isInDebugMode {
    // 기본적으로 프로덕션 모드라고 가정합니다.
    var inDebugMode = false;

    // Assert 표현식은 개발 단계에서만 사용되며, 프로덕션 모드에서는 무시됩니다.
    // 그러므로 이 코드는 개발 단계에서만 'inDebugMode'를 true로 설정합니다.
    assert(inDebugMode = true);

    return inDebugMode;
  }

  void dispose() {}
}
