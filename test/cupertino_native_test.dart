import 'package:flutter_test/flutter_test.dart';
<<<<<<< HEAD
import 'package:cupertino_native_plus/cupertino_native.dart';
=======
import 'package:cupertino_native_plus/cupertino_native_plus.dart';
>>>>>>> fork/main
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockCupertinoNativePlatform
    with MockPlatformInterfaceMixin
    implements CupertinoNativePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<int?> getMajorOSVersion() => Future.value(26);
}

void main() {
  final CupertinoNativePlatform initialPlatform =
      CupertinoNativePlatform.instance;

<<<<<<< HEAD
  test('$MethodChannelCupertinoNative is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelCupertinoNative>());
  });

  test('getPlatformVersion', () async {
    CupertinoNative cupertinoNativePlugin = CupertinoNative();
    MockCupertinoNativePlatform fakePlatform = MockCupertinoNativePlatform();
    CupertinoNativePlatform.instance = fakePlatform;

    expect(await cupertinoNativePlugin.getPlatformVersion(), '42');
=======
  group('CupertinoNativePlatform', () {
    test('\$MethodChannelCupertinoNative is the default instance', () {
      expect(initialPlatform, isInstanceOf<MethodChannelCupertinoNative>());
    });

    test('getPlatformVersion returns expected value', () async {
      CupertinoNativeBetter cupertinoNativePlugin = CupertinoNativeBetter();
      MockCupertinoNativePlatform fakePlatform = MockCupertinoNativePlatform();
      CupertinoNativePlatform.instance = fakePlatform;

      expect(await cupertinoNativePlugin.getPlatformVersion(), '42');
    });

    test('getMajorOSVersion returns expected value', () async {
      MockCupertinoNativePlatform fakePlatform = MockCupertinoNativePlatform();
      CupertinoNativePlatform.instance = fakePlatform;

      expect(await fakePlatform.getMajorOSVersion(), 26);
    });
  });

  group('CNButtonStyle', () {
    test('has all expected values', () {
      expect(CNButtonStyle.values, contains(CNButtonStyle.plain));
      expect(CNButtonStyle.values, contains(CNButtonStyle.gray));
      expect(CNButtonStyle.values, contains(CNButtonStyle.tinted));
      expect(CNButtonStyle.values, contains(CNButtonStyle.bordered));
      expect(CNButtonStyle.values, contains(CNButtonStyle.borderedProminent));
      expect(CNButtonStyle.values, contains(CNButtonStyle.filled));
      expect(CNButtonStyle.values, contains(CNButtonStyle.glass));
      expect(CNButtonStyle.values, contains(CNButtonStyle.prominentGlass));
    });

    test('enum names are correct', () {
      expect(CNButtonStyle.glass.name, 'glass');
      expect(CNButtonStyle.prominentGlass.name, 'prominentGlass');
    });
  });

  group('CNGlassEffect', () {
    test('has all expected values', () {
      expect(CNGlassEffect.values.length, 2);
      expect(CNGlassEffect.values, contains(CNGlassEffect.regular));
      expect(CNGlassEffect.values, contains(CNGlassEffect.prominent));
    });

    test('enum names are correct', () {
      expect(CNGlassEffect.regular.name, 'regular');
      expect(CNGlassEffect.prominent.name, 'prominent');
    });
  });

  group('CNGlassEffectShape', () {
    test('has all expected values', () {
      expect(CNGlassEffectShape.values.length, 3);
      expect(CNGlassEffectShape.values, contains(CNGlassEffectShape.rect));
      expect(CNGlassEffectShape.values, contains(CNGlassEffectShape.capsule));
      expect(CNGlassEffectShape.values, contains(CNGlassEffectShape.circle));
    });
  });

  group('CNSpotlightMode', () {
    test('has all expected values', () {
      expect(CNSpotlightMode.values.length, 4);
      expect(CNSpotlightMode.values, contains(CNSpotlightMode.none));
      expect(CNSpotlightMode.values, contains(CNSpotlightMode.touch));
      expect(CNSpotlightMode.values, contains(CNSpotlightMode.gyroscope));
      expect(CNSpotlightMode.values, contains(CNSpotlightMode.both));
    });

    test('enum names are correct', () {
      expect(CNSpotlightMode.none.name, 'none');
      expect(CNSpotlightMode.touch.name, 'touch');
      expect(CNSpotlightMode.gyroscope.name, 'gyroscope');
      expect(CNSpotlightMode.both.name, 'both');
    });
  });

  group('CNImagePlacement', () {
    test('has all expected values', () {
      expect(CNImagePlacement.values.length, 4);
      expect(CNImagePlacement.values, contains(CNImagePlacement.leading));
      expect(CNImagePlacement.values, contains(CNImagePlacement.trailing));
      expect(CNImagePlacement.values, contains(CNImagePlacement.top));
      expect(CNImagePlacement.values, contains(CNImagePlacement.bottom));
    });
  });

  group('CNSymbolRenderingMode', () {
    test('has all expected values', () {
      expect(CNSymbolRenderingMode.values.length, 4);
      expect(
        CNSymbolRenderingMode.values,
        contains(CNSymbolRenderingMode.monochrome),
      );
      expect(
        CNSymbolRenderingMode.values,
        contains(CNSymbolRenderingMode.hierarchical),
      );
      expect(
        CNSymbolRenderingMode.values,
        contains(CNSymbolRenderingMode.palette),
      );
      expect(
        CNSymbolRenderingMode.values,
        contains(CNSymbolRenderingMode.multicolor),
      );
    });
  });

  group('CNFloatingIslandPosition', () {
    test('has all expected values', () {
      expect(CNFloatingIslandPosition.values.length, 2);
      expect(
        CNFloatingIslandPosition.values,
        contains(CNFloatingIslandPosition.top),
      );
      expect(
        CNFloatingIslandPosition.values,
        contains(CNFloatingIslandPosition.bottom),
      );
    });
>>>>>>> fork/main
  });
}
