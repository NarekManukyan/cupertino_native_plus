import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show TabController, TabBarView, Colors;
import 'package:cupertino_native_plus/cupertino_native_plus.dart';

class TabBarDemoPage extends StatefulWidget {
  const TabBarDemoPage({super.key});

  @override
  State<TabBarDemoPage> createState() => _TabBarDemoPageState();
}

class _TabBarDemoPageState extends State<TabBarDemoPage>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;
  int _index = 0;
  bool _useAlternateIcons = false;

  // Label style state
  int _labelStyleIndex = 0; // 0 = default, 1 = bold+large, 2 = Georgia italic

  static const _labelStyleOptions = ['Default', 'Bold/Large', 'Georgia'];

  TextStyle? get _labelStyle {
    switch (_labelStyleIndex) {
      case 1:
        return const TextStyle(fontWeight: FontWeight.w300, fontSize: 11);
      case 2:
        return const TextStyle(fontFamily: 'Georgia', fontSize: 11);
      default:
        return null;
    }
  }

  TextStyle? get _activeLabelStyle {
    switch (_labelStyleIndex) {
      case 1:
        return const TextStyle(fontWeight: FontWeight.w700, fontSize: 16);
      case 2:
        return const TextStyle(
          fontFamily: 'Georgia',
          fontSize: 16,
          fontStyle: FontStyle.italic,
        );
      default:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 4, vsync: this);
    _controller.addListener(() {
      final i = _controller.index;
      if (i != _index) setState(() => _index = i);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Native Tab Bar'),
      ),
      child: Stack(
        children: [
          // Content below
          Positioned.fill(
            child: TabBarView(
              controller: _controller,
              children: const [
                _ImageTabPage(asset: 'assets/home.jpg', label: 'Home'),
                _ImageTabPage(asset: 'assets/profile.jpg', label: 'Profile'),
                _ImageTabPage(asset: 'assets/settings.jpg', label: 'Settings'),
                _ImageTabPage(asset: 'assets/search.jpg', label: 'Search'),
              ],
            ),
          ),
          // Native tab bar overlay
          Align(
            alignment: Alignment.bottomCenter,
            child: CNTabBar(
              items: _useAlternateIcons
                  ? [
                      CNTabBarItem(
                        label: 'Home',
                        imageAsset: CNImageAsset.asset(
                          'assets/icons/profile.svg',
                        ),
                        activeImageAsset: CNImageAsset.asset(
                          'assets/icons/profile-filled.svg',
                        ),
                        badge: '5',
                      ),
                      CNTabBarItem(
                        label: 'Search',
                        imageAsset: CNImageAsset.asset('assets/icons/chat.svg'),
                        activeImageAsset: CNImageAsset.asset(
                          'assets/icons/chat-filled.svg',
                        ),
                        badge: '8',
                      ),
                      CNTabBarItem(
                        label: 'Profile',
                        imageAsset: CNImageAsset.asset('assets/icons/home.svg'),
                        activeImageAsset: CNImageAsset.asset(
                          'assets/icons/home_filled.svg',
                        ),
                      ),
                      CNTabBarItem(
                        imageAsset: CNImageAsset.asset(
                          'assets/icons/search.svg',
                        ),
                        activeImageAsset: CNImageAsset.asset(
                          'assets/icons/search-filled.svg',
                        ),
                      ),
                    ]
                  : [
                      CNTabBarItem(
                        label: 'Home',
                        imageAsset: CNImageAsset.asset('assets/icons/home.svg'),
                        activeImageAsset: CNImageAsset.asset(
                          'assets/icons/home_filled.svg',
                        ),
                        badge: '3',
                      ),
                      CNTabBarItem(
                        label: 'Search',
                        imageAsset: CNImageAsset.asset(
                          'assets/icons/search.svg',
                        ),
                        activeImageAsset: CNImageAsset.asset(
                          'assets/icons/search-filled.svg',
                        ),
                        badge: '12',
                      ),
                      CNTabBarItem(
                        label: 'Profile',
                        imageAsset: CNImageAsset.asset(
                          'assets/icons/profile.svg',
                        ),
                        activeImageAsset: CNImageAsset.asset(
                          'assets/icons/profile-filled.svg',
                        ),
                      ),
                      CNTabBarItem(
                        imageAsset: CNImageAsset.asset('assets/icons/chat.svg'),
                        activeImageAsset: CNImageAsset.asset(
                          'assets/icons/chat-filled.svg',
                        ),
                      ),
                    ],
              currentIndex: _index,
              split: true,
              rightCount: 1,
              splitSpacing: 8,
              shrinkCentered: true,
              tint: Colors.red,
              labelStyle: _labelStyle,
              activeLabelStyle: _activeLabelStyle,
              onTap: (i) {
                setState(() => _index = i);
                _controller.animateTo(i);
              },
            ),
          ),
          // Controls overlay
          Positioned(
            top: 100,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 8,
              children: [
                // Toggle icons button
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      _useAlternateIcons = !_useAlternateIcons;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBlue.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      _useAlternateIcons
                          ? CupertinoIcons.refresh
                          : CupertinoIcons.arrow_2_squarepath,
                      color: CupertinoColors.white,
                      size: 24,
                    ),
                  ),
                ),
                // Label style picker
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground
                        .resolveFrom(context)
                        .withOpacity(0.92),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withOpacity(0.12),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      const Text(
                        'Label Style',
                        style: TextStyle(
                          fontSize: 11,
                          color: CupertinoColors.secondaryLabel,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      for (int i = 0; i < _labelStyleOptions.length; i++)
                        GestureDetector(
                          onTap: () => setState(() => _labelStyleIndex = i),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 6,
                            children: [
                              Icon(
                                _labelStyleIndex == i
                                    ? CupertinoIcons.checkmark_circle_fill
                                    : CupertinoIcons.circle,
                                size: 16,
                                color: _labelStyleIndex == i
                                    ? CupertinoColors.systemBlue
                                    : CupertinoColors.tertiaryLabel,
                              ),
                              Text(
                                _labelStyleOptions[i],
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageTabPage extends StatelessWidget {
  const _ImageTabPage({required this.asset, required this.label});
  final String asset;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(asset, fit: BoxFit.cover),
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(top: 12),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                color: CupertinoColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
