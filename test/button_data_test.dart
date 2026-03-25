import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cupertino_native_plus/cupertino_native_plus.dart';

void main() {
  group('CNButtonData', () {
    test('creates labeled button with default values', () {
      final button = CNButtonData(label: 'Test Button');

      expect(button.label, 'Test Button');
      expect(button.isIcon, false);
      expect(button.enabled, true);
      expect(button.icon, isNull);
      expect(button.onPressed, isNull);
      expect(button.theme.tint, isNull);
      expect(button.config, isNotNull);
    });

    test('creates icon button with default values', () {
      final button = CNButtonData.icon();

      expect(button.label, isNull);
      expect(button.isIcon, true);
      expect(button.enabled, true);
    });

    test('creates button with SF Symbol icon', () {
      const icon = CNImageAsset.symbol('star.fill', size: Size(24, 24));
      final button = CNButtonData.icon(icon: icon);

      expect(button.icon, isNotNull);
      expect(button.icon!.toMap()['iconName'], 'star.fill');
      expect(button.icon!.size, const Size(24, 24));
    });

    test('creates icon button with Flutter asset', () {
      const icon = CNImageAsset.asset('assets/star.png');
      final button = CNButtonData.icon(icon: icon);

      expect(button.icon!.assetPath, 'assets/star.png');
    });

    test('creates button with tint color via theme', () {
      final button = CNButtonData(
        label: 'Colored',
        theme: const CNButtonTheme(tint: Colors.red),
      );

      expect(button.theme.tint, Colors.red);
    });

    test('creates disabled button', () {
      final button = CNButtonData(label: 'Disabled', enabled: false);

      expect(button.enabled, false);
    });

    test('creates button with onPressed callback', () {
      var pressed = false;
      final button = CNButtonData(
        label: 'Press Me',
        onPressed: () => pressed = true,
      );

      button.onPressed?.call();
      expect(pressed, true);
    });

    test('creates button with custom config', () {
      final config = CNButtonDataConfig(
        style: CNButtonStyle.prominentGlass,
        minHeight: 56.0,
        borderRadius: 12.0,
        padding: const EdgeInsets.all(16),
      );
      final button = CNButtonData(label: 'Custom', config: config);

      expect(button.config.style, CNButtonStyle.prominentGlass);
      expect(button.config.minHeight, 56.0);
      expect(button.config.borderRadius, 12.0);
      expect(button.config.padding, const EdgeInsets.all(16));
    });

    group('copyWith', () {
      test('copies labeled button with new label', () {
        final original = CNButtonData(label: 'Original');
        final copy = original.copyWith(label: 'Copy');

        expect(copy.label, 'Copy');
        expect(copy.isIcon, false);
      });

      test('copies icon button with new icon', () {
        final original = CNButtonData.icon(
          icon: const CNImageAsset.symbol('star'),
        );
        final copy = original.copyWith(
          icon: const CNImageAsset.symbol('heart'),
        );

        expect(copy.icon!.toMap()['iconName'], 'heart');
        expect(copy.isIcon, true);
      });

      test('copies button with new enabled state', () {
        final original = CNButtonData(label: 'Test', enabled: true);
        final copy = original.copyWith(enabled: false);

        expect(copy.enabled, false);
      });

      test('copies button with new theme tint', () {
        final original = CNButtonData(
          label: 'Test',
          theme: const CNButtonTheme(tint: Colors.blue),
        );
        final copy = original.copyWith(
          theme: const CNButtonTheme(tint: Colors.red),
        );

        expect(copy.theme.tint, Colors.red);
      });

      test('preserves original values when not specified', () {
        final original = CNButtonData(
          label: 'Original',
          enabled: false,
          theme: const CNButtonTheme(tint: Colors.blue),
        );
        final copy = original.copyWith(label: 'New Label');

        expect(copy.label, 'New Label');
        expect(copy.enabled, false);
        expect(copy.theme.tint, Colors.blue);
      });
    });
  });

  group('CNButtonDataConfig', () {
    test('creates config with default values', () {
      const config = CNButtonDataConfig();

      expect(config.style, CNButtonStyle.glass);
      expect(config.glassEffectInteractive, true);
      expect(config.width, isNull);
      expect(config.padding, isNull);
      expect(config.borderRadius, isNull);
      expect(config.minHeight, isNull);
      expect(config.imagePadding, isNull);
      expect(config.imagePlacement, isNull);
      expect(config.glassEffectUnionId, isNull);
      expect(config.glassEffectId, isNull);
    });

    test('creates config with custom values', () {
      const config = CNButtonDataConfig(
        width: 100.0,
        style: CNButtonStyle.borderedProminent,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        borderRadius: 8.0,
        minHeight: 44.0,
        imagePadding: 8.0,
        imagePlacement: CNImagePlacement.trailing,
        glassEffectUnionId: 'group1',
        glassEffectId: 'button1',
        glassEffectInteractive: false,
      );

      expect(config.width, 100.0);
      expect(config.style, CNButtonStyle.borderedProminent);
      expect(
        config.padding,
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      );
      expect(config.borderRadius, 8.0);
      expect(config.minHeight, 44.0);
      expect(config.imagePadding, 8.0);
      expect(config.imagePlacement, CNImagePlacement.trailing);
      expect(config.glassEffectUnionId, 'group1');
      expect(config.glassEffectId, 'button1');
      expect(config.glassEffectInteractive, false);
    });

    group('copyWith', () {
      test('copies config with new style', () {
        const original = CNButtonDataConfig(style: CNButtonStyle.glass);
        final copy = original.copyWith(style: CNButtonStyle.filled);

        expect(copy.style, CNButtonStyle.filled);
      });

      test('copies config with new dimensions', () {
        const original = CNButtonDataConfig(width: 100, minHeight: 44);
        final copy = original.copyWith(width: 200, minHeight: 56);

        expect(copy.width, 200);
        expect(copy.minHeight, 56);
      });

      test('preserves original values when not specified', () {
        const original = CNButtonDataConfig(
          style: CNButtonStyle.prominentGlass,
          borderRadius: 12.0,
          glassEffectUnionId: 'group1',
        );
        final copy = original.copyWith(borderRadius: 16.0);

        expect(copy.style, CNButtonStyle.prominentGlass);
        expect(copy.borderRadius, 16.0);
        expect(copy.glassEffectUnionId, 'group1');
      });
    });
  });

  group('CNSymbol', () {
    test('creates symbol with name only', () {
      const symbol = CNSymbol('star.fill');

      expect(symbol.name, 'star.fill');
      expect(symbol.size, 24.0); // default
      expect(symbol.color, isNull);
      expect(symbol.paletteColors, isNull);
      expect(symbol.mode, isNull);
      expect(symbol.gradient, isNull);
    });

    test('creates symbol with all parameters', () {
      final symbol = CNSymbol(
        'star.fill',
        size: 32.0,
        color: Colors.yellow,
        paletteColors: [Colors.red, Colors.blue],
        mode: CNSymbolRenderingMode.palette,
        gradient: true,
      );

      expect(symbol.name, 'star.fill');
      expect(symbol.size, 32.0);
      expect(symbol.color, Colors.yellow);
      expect(symbol.paletteColors, [Colors.red, Colors.blue]);
      expect(symbol.mode, CNSymbolRenderingMode.palette);
      expect(symbol.gradient, true);
    });
  });

  group('CNImageAsset', () {
    test('creates image asset with asset path', () {
      const asset = CNImageAsset.asset('assets/icon.png');

      expect(asset.assetPath, 'assets/icon.png');
      expect(asset.size, const Size(24, 24));
      expect(asset.color, isNull);
      expect(asset.imageData, isNull);
      expect(asset.imageFormat, isNull);
    });

    test('creates image asset with all parameters', () {
      final asset = CNImageAsset.asset(
        'assets/icon.svg',
        size: const Size(24, 24),
        color: Colors.blue,
        format: 'svg',
      );

      expect(asset.assetPath, 'assets/icon.svg');
      expect(asset.size, const Size(24, 24));
      expect(asset.color, Colors.blue);
      expect(asset.imageFormat, 'svg');
    });
  });
}
