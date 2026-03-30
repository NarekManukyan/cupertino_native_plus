import 'package:flutter/cupertino.dart';
import 'package:cupertino_native_plus/cupertino_native_plus.dart';

class IconDemoPage extends StatefulWidget {
  const IconDemoPage({super.key});

  @override
  State<IconDemoPage> createState() => _IconDemoPageState();
}

class _IconDemoPageState extends State<IconDemoPage> {
  bool _useAlternateSvgIcons = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Icon')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Basic'),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                CNIconView(symbol: CNSymbol('heart'), size: 24),
                CNIconView(symbol: CNSymbol('star'), size: 24),
                CNIconView(symbol: CNSymbol('bell'), size: 24),
                CNIconView(symbol: CNSymbol('figure.walk'), size: 24),
                CNIconView(symbol: CNSymbol('paperplane'), size: 24),
              ],
            ),

            const SizedBox(height: 24),

            const Text('Sizes'),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                CNIconView(symbol: CNSymbol('heart'), size: 12),
                CNIconView(symbol: CNSymbol('star'), size: 16),
                CNIconView(symbol: CNSymbol('bell'), size: 24),
                CNIconView(symbol: CNSymbol('figure.walk'), size: 32),
                CNIconView(symbol: CNSymbol('paperplane'), size: 40),
              ],
            ),

            const SizedBox(height: 24),

            const Text('Monochrome colors'),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                CNIconView(
                  symbol: CNSymbol('star.fill'),
                  color: CupertinoColors.systemPink,
                  mode: CNSymbolRenderingMode.monochrome,
                ),
                CNIconView(
                  symbol: CNSymbol('star.fill'),
                  color: CupertinoColors.systemBlue,
                  mode: CNSymbolRenderingMode.monochrome,
                ),
                CNIconView(
                  symbol: CNSymbol('star.fill'),
                  color: CupertinoColors.systemGreen,
                  mode: CNSymbolRenderingMode.monochrome,
                ),
                CNIconView(
                  symbol: CNSymbol('star.fill'),
                  color: CupertinoColors.systemOrange,
                  mode: CNSymbolRenderingMode.monochrome,
                ),
                CNIconView(
                  symbol: CNSymbol('star.fill'),
                  color: CupertinoColors.systemPurple,
                  mode: CNSymbolRenderingMode.monochrome,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Hierarchical'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                CNIconView(
                  symbol: CNSymbol('rectangle.and.pencil.and.ellipsis'),
                  size: 32,
                  color: CupertinoColors.systemBlue,
                  mode: CNSymbolRenderingMode.hierarchical,
                ),
                CNIconView(
                  symbol: CNSymbol('person.3.sequence'),
                  size: 32,
                  color: CupertinoColors.systemBlue,
                  mode: CNSymbolRenderingMode.hierarchical,
                ),
                CNIconView(
                  symbol: CNSymbol('speaker.wave.2.bubble'),
                  size: 32,
                  color: CupertinoColors.systemBlue,
                  mode: CNSymbolRenderingMode.hierarchical,
                ),
                CNIconView(
                  symbol: CNSymbol('ear.badge.waveform'),
                  size: 32,
                  color: CupertinoColors.systemBlue,
                  mode: CNSymbolRenderingMode.hierarchical,
                ),
                CNIconView(
                  symbol: CNSymbol('square.stack.3d.up'),
                  size: 32,
                  color: CupertinoColors.systemBlue,
                  mode: CNSymbolRenderingMode.hierarchical,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Multicolor'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                CNIconView(
                  symbol: CNSymbol('paintpalette.fill'),
                  size: 28,
                  mode: CNSymbolRenderingMode.multicolor,
                ),
                CNIconView(
                  symbol: CNSymbol('sun.rain.fill'),
                  size: 28,
                  mode: CNSymbolRenderingMode.multicolor,
                ),
                CNIconView(
                  symbol: CNSymbol('rainbow'),
                  size: 28,
                  mode: CNSymbolRenderingMode.multicolor,
                ),
                CNIconView(
                  symbol: CNSymbol('pc'),
                  size: 28,
                  mode: CNSymbolRenderingMode.multicolor,
                ),
                CNIconView(
                  symbol: CNSymbol('lightspectrum.horizontal'),
                  size: 28,
                  mode: CNSymbolRenderingMode.multicolor,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SVG Image Assets'),
                CupertinoButton(
                  onPressed: () {
                    setState(() {
                      _useAlternateSvgIcons = !_useAlternateSvgIcons;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: CupertinoColors.systemBlue.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Text(
                      _useAlternateSvgIcons ? 'Reset' : 'Switch',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemBlue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CNIconView(
                  imageAsset: CNIcon.asset(
                    _useAlternateSvgIcons
                        ? 'assets/icons/profile.svg'
                        : 'assets/icons/home.svg',
                  ),
                  size: 24,
                ),
                CNIconView(
                  imageAsset: CNIcon.asset(
                    _useAlternateSvgIcons
                        ? 'assets/icons/chat.svg'
                        : 'assets/icons/search.svg',
                  ),
                  size: 32,
                ),
                CNIconView(
                  imageAsset: CNIcon.asset(
                    _useAlternateSvgIcons
                        ? 'assets/icons/home.svg'
                        : 'assets/icons/profile.svg',
                  ),
                  size: 40,
                ),
                CNIconView(
                  imageAsset: CNIcon.asset(
                    _useAlternateSvgIcons
                        ? 'assets/icons/search.svg'
                        : 'assets/icons/chat.svg',
                  ),
                  size: 48,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Debug: Testing with SF Symbol fallback',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CNIconView(
                  symbol: const CNSymbol('house.fill'),
                  imageAsset: CNIcon.asset(
                    _useAlternateSvgIcons
                        ? 'assets/icons/profile.svg'
                        : 'assets/icons/home.svg',
                  ),
                  size: 24,
                ),
                const SizedBox(width: 16),
                CNIconView(
                  symbol: const CNSymbol('magnifyingglass'),
                  imageAsset: CNIcon.asset(
                    _useAlternateSvgIcons
                        ? 'assets/icons/chat.svg'
                        : 'assets/icons/search.svg',
                  ),
                  size: 32,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Custom Icons (IconData)'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                CNIconView(
                  symbol: CNSymbol('house.fill'), // Fallback if not provided
                  customIcon: CupertinoIcons.home, // Custom IconData!
                  size: 24,
                ),
                CNIconView(
                  symbol: CNSymbol('house.fill'),
                  customIcon: CupertinoIcons.home,
                  size: 32,
                ),
                CNIconView(
                  symbol: CNSymbol('house.fill'),
                  customIcon: CupertinoIcons.home,
                  size: 40,
                ),
                CNIconView(
                  symbol: CNSymbol('house.fill'),
                  customIcon: CupertinoIcons.home,
                  size: 48,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
