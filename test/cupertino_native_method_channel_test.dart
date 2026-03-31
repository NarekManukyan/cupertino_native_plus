import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cupertino_native_plus/cupertino_native_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final MethodChannelCupertinoNative platform = MethodChannelCupertinoNative();
  const MethodChannel channel = MethodChannel('cupertino_native');

  group('MethodChannelCupertinoNative', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            switch (methodCall.method) {
              case 'getPlatformVersion':
                return 'iOS 26.0';
              case 'getMajorOSVersion':
                return 26;
              default:
                return null;
            }
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('getPlatformVersion returns expected value', () async {
      expect(await platform.getPlatformVersion(), 'iOS 26.0');
    });

    test('getMajorOSVersion returns expected value', () async {
      expect(await platform.getMajorOSVersion(), 26);
    });
  });

  group('MethodChannelCupertinoNative error handling', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            throw PlatformException(code: 'ERROR', message: 'Test error');
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('getPlatformVersion throws on platform error', () async {
      expect(
        () => platform.getPlatformVersion(),
        throwsA(isA<PlatformException>()),
      );
    });

    test('getMajorOSVersion throws on platform error', () async {
      expect(
        () => platform.getMajorOSVersion(),
        throwsA(isA<PlatformException>()),
      );
    });
  });

  group('MethodChannelCupertinoNative null responses', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test(
      'getPlatformVersion returns null when platform returns null',
      () async {
        expect(await platform.getPlatformVersion(), isNull);
      },
    );

    test('getMajorOSVersion returns null when platform returns null', () async {
      expect(await platform.getMajorOSVersion(), isNull);
    });
  });
}
