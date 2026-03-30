import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cupertino_native_plus/cupertino_native_plus.dart';

class ImageAssetDemo extends StatefulWidget {
  const ImageAssetDemo({super.key});

  @override
  State<ImageAssetDemo> createState() => _ImageAssetDemoState();
}

class _ImageAssetDemoState extends State<ImageAssetDemo> {
  Uint8List? _svgData;
  Uint8List? _pngData;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    // Load SVG data from actual icons
    try {
      final svgBytes = await rootBundle.load('assets/icons/home.svg');
      setState(() {
        _svgData = svgBytes.buffer.asUint8List();
      });
    } catch (e) {
      debugPrint('Failed to load SVG: $e');
    }

    // Load another SVG for comparison
    try {
      final pngBytes = await rootBundle.load('assets/icons/search.svg');
      setState(() {
        _pngData = pngBytes.buffer.asUint8List();
      });
    } catch (e) {
      debugPrint('Failed to load second SVG: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Image Asset Demo'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CNIcon / CNIconView Examples',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // SF Symbol (for comparison)
              const Text(
                'SF Symbol:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const CNIconView(symbol: CNSymbol('house.fill', size: 32)),
              const SizedBox(height: 20),

              // Asset path examples with your actual icons
              const Text(
                'Asset Path Examples:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const CNIconView(
                    imageAsset: CNIcon.asset(
                      'assets/icons/home.svg',
                      size: Size(32, 32),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const CNIconView(
                    imageAsset: CNIcon.asset(
                      'assets/icons/search.svg',
                      size: Size(32, 32),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const CNIconView(
                    imageAsset: CNIcon.asset(
                      'assets/icons/profile.svg',
                      size: Size(32, 32),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const CNIconView(
                    imageAsset: CNIcon.asset(
                      'assets/icons/chat.svg',
                      size: Size(32, 32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Raw SVG data (if supported)
              if (_svgData != null) ...[
                const Text(
                  'Raw SVG Data (Home Icon):',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                CNIconView(
                  imageAsset: CNIcon.svg(_svgData!, size: const Size(32, 32)),
                ),
                const SizedBox(height: 20),
              ],

              // Raw SVG data for search icon
              if (_pngData != null) ...[
                const Text(
                  'Raw SVG Data (Search Icon):',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                CNIconView(
                  imageAsset: CNIcon.svg(_pngData!, size: const Size(32, 32)),
                ),
                const SizedBox(height: 20),
              ],

              // Custom styling examples
              const Text(
                'Custom Styling Examples:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const CNIconView(
                    imageAsset: CNIcon.asset(
                      'assets/icons/home.svg',
                      size: Size(32, 32),
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const CNIconView(
                    imageAsset: CNIcon.asset(
                      'assets/icons/search.svg',
                      size: Size(32, 32),
                      color: CupertinoColors.systemRed,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const CNIconView(
                    imageAsset: CNIcon.asset(
                      'assets/icons/profile.svg',
                      size: Size(32, 32),
                      color: CupertinoColors.systemGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Filled vs outline comparison
              const Text(
                'Filled vs Outline Icons:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const CNIconView(
                    imageAsset: CNIcon.asset(
                      'assets/icons/home.svg',
                      size: Size(32, 32),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('vs', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  const CNIconView(
                    imageAsset: CNIcon.asset(
                      'assets/icons/home_filled.svg',
                      size: Size(32, 32),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const CNIconView(
                    imageAsset: CNIcon.asset(
                      'assets/icons/search.svg',
                      size: Size(32, 32),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('vs', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  const CNIconView(
                    imageAsset: CNIcon.asset(
                      'assets/icons/search-filled.svg',
                      size: Size(32, 32),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
