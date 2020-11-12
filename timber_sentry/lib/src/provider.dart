import 'dart:io';

import 'package:battery/battery.dart';
import 'package:device_info/device_info.dart';
import 'package:package_info/package_info.dart';
import 'package:quiver/check.dart';
import 'package:sentry/sentry.dart';

abstract class Provider<T> {
  Future<T> provide();
}

abstract class ReleaseProvider extends Provider<String> {}

abstract class EnvironmentProvider extends Provider<String> {}

abstract class UserProvider extends Provider<User> {}

abstract class ContextsProvider extends Provider<Contexts> {}

class PlatformReleaseProvider implements ReleaseProvider {
  @override
  Future<String> provide() async {
    var packageInfo = await PackageInfo.fromPlatform();
    return provideFromPackageInfo(packageInfo);
  }

  Future<String> provideFromPackageInfo(PackageInfo packageInfo) async {
    checkNotNull(packageInfo);
    final packageName = packageInfo.packageName;
    final version = packageInfo.version;
    final buildNumber = packageInfo.buildNumber;
    return '$version+$buildNumber';
  }
}

class DeviceInfContextsProvider implements ContextsProvider {
  final _deviceInfo = DeviceInfoPlugin();
  final _battery = Battery();

  @override
  Future<Contexts> provide() async {
    if (Platform.isAndroid) {
      final androidDeviceInfo = await _deviceInfo.androidInfo;
      return provideFromAndroidDeviceInfo(androidDeviceInfo);
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return provideFromIosDeviceInfo(iosInfo);
    }
  }

  Future<Contexts> provideFromAndroidDeviceInfo(
      AndroidDeviceInfo androidDeviceInfo) async {
    checkNotNull(androidDeviceInfo);

    final os = OperatingSystem(
      //version: androidDeviceInfo.version.
      name: 'Android',
      build: androidDeviceInfo.version.release,
      version: androidDeviceInfo.version.baseOS,
    );
    final device = Device(
      name: androidDeviceInfo.device,
      brand: androidDeviceInfo.brand,
      batteryLevel: (await _battery.batteryLevel).toDouble(),
      family: androidDeviceInfo.model,
    );
    return Contexts(
      operatingSystem: os,
      device: device,
    );
  }

  Future<Contexts> provideFromIosDeviceInfo(IosDeviceInfo iosDeviceInfo) async {
    checkNotNull(iosDeviceInfo);
    final os = OperatingSystem(
      //version: androidDeviceInfo.version.
      name: iosDeviceInfo.systemName,
      build: iosDeviceInfo.utsname.version,
      version: iosDeviceInfo.systemVersion,
    );
    final device = Device(
      name: iosDeviceInfo.name,
      brand: 'apple',
    );
    return Contexts(
      operatingSystem: os,
      device: device,
    );
  }
}
