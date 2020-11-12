import 'package:device_info/device_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timber_sentry/src/provider.dart';

void main() {
  group('DeviceInfContextsProvider', () {
    test('iosProvide', () async {
      var provider = DeviceInfContextsProvider();
      var deviceInfo = IosDeviceInfo.fromMap({
        'name': 'test',
        'utsname': {'version': 'test'}
      });
      var contexts = await provider.provideFromIosDeviceInfo(deviceInfo);

      expect(contexts.device.name, 'test');
      expect(contexts.device.brand, 'apple');
    });

    test('android', () async {
      var provider = DeviceInfContextsProvider();
      var deviceInfo =
          AndroidDeviceInfo.fromMap({'name': 'test', 'brand': 'samsung'});
      var contexts = await provider.provideFromAndroidDeviceInfo(deviceInfo);

      expect(contexts.device.name, 'test');
      expect(contexts.device.brand, 'samsung');
    });
  });
}
