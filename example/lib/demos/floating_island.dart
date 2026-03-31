import 'package:cupertino_native_plus/cupertino_native_plus.dart';
import 'package:flutter/cupertino.dart';

class FloatingIslandDemoPage extends StatefulWidget {
  const FloatingIslandDemoPage({super.key});

  @override
  State<FloatingIslandDemoPage> createState() => _FloatingIslandDemoPageState();
}

class _FloatingIslandDemoPageState extends State<FloatingIslandDemoPage> {
  final _musicController = CNFloatingIslandController();
  final _notifController = CNFloatingIslandController();
  bool _musicExpanded = false;
  bool _notifExpanded = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Floating Island'),
      ),
      child: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Music Player (top)',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap the island to expand/collapse',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  children: [
                    CNButton(
                      label: _musicExpanded ? 'Collapse' : 'Expand',
                      onPressed: () {
                        setState(() => _musicExpanded = !_musicExpanded);
                      },
                      config: const CNButtonConfig(
                        style: CNButtonStyle.gray,
                        shrinkWrap: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                const Text(
                  'Notification (bottom)',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'A bottom-anchored island for notifications.',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  children: [
                    CNButton(
                      label: _notifExpanded ? 'Dismiss' : 'Show',
                      onPressed: () {
                        setState(() => _notifExpanded = !_notifExpanded);
                      },
                      config: const CNButtonConfig(
                        style: CNButtonStyle.gray,
                        shrinkWrap: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Music player island — top
          CNFloatingIsland(
            controller: _musicController,
            isExpanded: _musicExpanded,
            position: CNFloatingIslandPosition.top,
            collapsedHeight: 44,
            collapsedWidth: 180,
            expandedHeight: 160,
            onTap: () => setState(() => _musicExpanded = !_musicExpanded),
            onExpandStateChanged: (v) => setState(() => _musicExpanded = v),
            collapsed: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(CupertinoIcons.music_note, size: 16),
                SizedBox(width: 8),
                Text(
                  'Now Playing',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            expanded: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Midnight Drive',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const Text(
                  'Neon Waves',
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(CupertinoIcons.backward_fill, size: 24),
                    SizedBox(width: 24),
                    Icon(CupertinoIcons.pause_fill, size: 28),
                    SizedBox(width: 24),
                    Icon(CupertinoIcons.forward_fill, size: 24),
                  ],
                ),
              ],
            ),
          ),

          // Notification island — bottom
          if (_notifExpanded)
            CNFloatingIsland(
              controller: _notifController,
              isExpanded: _notifExpanded,
              position: CNFloatingIslandPosition.bottom,
              collapsedHeight: 44,
              collapsedWidth: 200,
              expandedHeight: 120,
              onTap: () => setState(() => _notifExpanded = !_notifExpanded),
              onExpandStateChanged: (v) => setState(() => _notifExpanded = v),
              collapsed: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(CupertinoIcons.bell_fill, size: 16),
                  SizedBox(width: 8),
                  Text(
                    '1 new message',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              expanded: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Messages',
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Hey! Are you free tonight?',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'from Alex',
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.secondaryLabel,
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
