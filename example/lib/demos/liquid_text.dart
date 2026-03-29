import 'package:cupertino_native_plus/cupertino_native_plus.dart';
import 'package:flutter/cupertino.dart';

class LiquidTextDemoPage extends StatelessWidget {
  const LiquidTextDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Liquid Text')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Sizes',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                CNLiquidText(text: 'Small', fontSize: 13),
                CNLiquidText(text: 'Regular', fontSize: 16),
                CNLiquidText(text: 'Large', fontSize: 22),
                CNLiquidText(text: 'Title', fontSize: 28),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Weights',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                CNLiquidText(
                  text: 'Light',
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                ),
                CNLiquidText(
                  text: 'Regular',
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
                CNLiquidText(
                  text: 'Medium',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                CNLiquidText(
                  text: 'Semibold',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                CNLiquidText(
                  text: 'Bold',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Shapes',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                CNLiquidText(
                  text: 'Capsule',
                  fontSize: 16,
                  glassConfig: const LiquidGlassConfig(
                    shape: CNGlassEffectShape.capsule,
                  ),
                ),
                CNLiquidText(
                  text: 'Rectangle',
                  fontSize: 16,
                  glassConfig: const LiquidGlassConfig(
                    shape: CNGlassEffectShape.rect,
                    cornerRadius: 8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Tinted',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                CNLiquidText(
                  text: 'Blue',
                  fontSize: 16,
                  glassConfig: LiquidGlassConfig(
                    tint: CupertinoColors.systemBlue.withValues(alpha: 0.3),
                  ),
                ),
                CNLiquidText(
                  text: 'Green',
                  fontSize: 16,
                  glassConfig: LiquidGlassConfig(
                    tint: CupertinoColors.systemGreen.withValues(alpha: 0.3),
                  ),
                ),
                CNLiquidText(
                  text: 'Purple',
                  fontSize: 16,
                  glassConfig: LiquidGlassConfig(
                    tint: CupertinoColors.systemPurple.withValues(alpha: 0.3),
                  ),
                ),
                CNLiquidText(
                  text: 'Pink',
                  fontSize: 16,
                  glassConfig: LiquidGlassConfig(
                    tint: CupertinoColors.systemPink.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Interactive',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'On iOS 26+ the glass morphs on touch.',
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                CNLiquidText(
                  text: 'Tap me',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  glassConfig: const LiquidGlassConfig(interactive: true),
                ),
                CNLiquidText(
                  text: 'Press me',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  glassConfig: const LiquidGlassConfig(
                    interactive: true,
                    effect: CNGlassEffect.prominent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Falls back to plain Text on non-iOS 26+ platforms',
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
