# cupertino_native_plus

[![Pub Version](https://img.shields.io/pub/v/cupertino_native_plus)](https://pub.dev/packages/cupertino_native_plus)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS-lightgrey)](https://flutter.dev)

Native iOS 26+ **Liquid Glass** widgets for Flutter with pixel-perfect fidelity. This package renders authentic Apple UI components using native platform views, providing the genuine iOS/macOS look and feel that Flutter's built-in widgets cannot achieve.

<p align="center">
  <img src="https://raw.githubusercontent.com/NarekManukyan/cupertino_native_plus/main/misc/screenshots/preview.jpg" alt="Preview" width="600"/>
</p>

## Quick Start

No initialization required! Just import and use:

```dart
import 'package:cupertino_native_plus/cupertino_native_plus.dart';

void main() {
  runApp(MyApp());
}
```

> **Note:** `PlatformVersion` auto-initializes on first access. No need to call `initialize()` anymore!

## Performance Best Practices

### ⚠️ LiquidGlassContainer & Lists

`LiquidGlassContainer` uses a **Platform View** (`UiKitView` / `AppKitView`) under the hood. While powerful, platform views are more expensive than standard Flutter widgets.

*   **DO NOT** use `LiquidGlassContainer` inside long scrolling lists (`ListView.builder`, `GridView`) with many items. This will cause significant performance drops (jank).
*   **DO** use `LiquidGlassContainer` for static elements like Cards, Headers, Navigation Bars, or Floating Action Buttons.

## Why cupertino_native_plus?

**cupertino_native_plus** provides native iOS and macOS widgets with pixel-perfect fidelity. Unlike other packages that rely on Flutter's Cupertino widgets, this package uses native platform views to render authentic Apple UI components.

### Key Advantages

- **Reliable Version Detection**: Uses `Platform.operatingSystemVersion` parsing instead of platform channels, ensuring accurate version detection in both debug and release builds
- **Native Rendering**: All widgets use native platform views for authentic iOS/macOS appearance
- **Comprehensive Fallbacks**: Every widget gracefully degrades on older OS versions
- **Multiple Icon Types**: Unified `CNIcon` supports SF Symbols, xcassets, Flutter asset paths, and raw bytes (SVG/PNG/JPG)
- **Dark Mode Support**: Automatic theme synchronization with system preferences
- **Glass Effect Unioning**: Multiple buttons can share unified glass effects

## Features

### Widgets

| Widget | Description | Controller |
|--------|-------------|:----------:|
| `CNButton` | Native push button with Liquid Glass effects, SF Symbols, and image assets | - |
| `CNButton.icon` | Circular icon-only button variant | - |
| `CNIcon` | Platform-rendered SF Symbols, custom IconData, or image assets | - |
| `CNTabBar` | Native tab bar with split mode for scroll-aware layouts | - |
| `CNSlider` | Native slider with min/max range and step support | `CNSliderController` |
| `CNSwitch` | Native toggle switch with animated state changes | `CNSwitchController` |
| `CNPopupMenuButton` | Native popup menu with dividers, icons, and image assets | - |
| `CNPopupMenuButton.icon` | Circular icon-only popup menu variant | - |
| `CNSegmentedControl` | Native segmented control with SF Symbols support | - |
| `CNGlassButtonGroup` | Grouped buttons with unified glass blending | - |
| `LiquidGlassContainer` | Apply Liquid Glass effects to any Flutter widget | - |
| `CNGlassCard` | **(Experimental)** Pre-styled card with optional breathing glow animation | - |
| `CNTabBarNative` | **iOS 26 Native Tab Bar** with UITabBarController + search | - |
| `CNToast` | Toast notifications with Liquid Glass effects | - |

### Icon Support

All widgets use `CNIcon` as the single unified icon type. Choose the named constructor that matches your source:

| Constructor | Source |
|---|---|
| `CNIcon.symbol('name')` | SF Symbol (system icon) |
| `CNIcon.xcasset('name')` | App asset catalog (xcassets) |
| `CNIcon.asset('path')` | Flutter asset path (SVG/PNG/JPG auto-detected) |
| `CNIcon.svg(bytes)` | SVG bytes |
| `CNIcon.png(bytes)` | PNG bytes |
| `CNIcon.jpg(bytes)` | JPG bytes |

```dart
// SF Symbol
CNButton(
  label: 'Settings',
  icon: const CNIcon.symbol('gear', size: Size(20, 20)),
  onPressed: () {},
)

// Flutter asset (SVG/PNG/JPG — format auto-detected from extension)
CNButton(
  label: 'Custom',
  icon: const CNIcon.asset('assets/icons/custom.png', size: Size(20, 20)),
  onPressed: () {},
)

// App asset catalog (xcassets)
CNButton(
  label: 'Logo',
  icon: const CNIcon.xcasset('AppIcon', size: Size(20, 20)),
  onPressed: () {},
)

// Tinted icon
CNButton.icon(
  icon: const CNIcon.symbol('house.fill', size: Size(20, 20)),
  tint: Colors.blue,
  onPressed: () {},
)
```

### Button Styles

```dart
CNButtonStyle.plain           // Minimal, text-only
CNButtonStyle.gray            // Subtle gray background
CNButtonStyle.tinted          // Tinted text
CNButtonStyle.bordered        // Bordered outline
CNButtonStyle.borderedProminent // Accent-colored border
CNButtonStyle.filled          // Solid filled background
CNButtonStyle.glass           // Liquid Glass effect (iOS 26+)
CNButtonStyle.prominentGlass  // Prominent glass effect (iOS 26+)
```

### Glass Effect Unioning

Multiple buttons can share a unified glass effect:

```dart
Row(
  children: [
    CNButton(
      label: 'Left',
      config: CNButtonConfig(
        style: CNButtonStyle.glass,
        glassEffectUnionId: 'toolbar',
      ),
      onPressed: () {},
    ),
    CNButton(
      label: 'Right',
      config: CNButtonConfig(
        style: CNButtonStyle.glass,
        glassEffectUnionId: 'toolbar',
      ),
      onPressed: () {},
    ),
  ],
)
```

### Tab Bar with Split Mode

<p align="center">
  <img src="https://raw.githubusercontent.com/NarekManukyan/cupertino_native_plus/main/misc/screenshots/tab_bar_preview.png" width="300" alt="Tab Bar Preview"/>
</p>

```dart
CNTabBar(
  items: [
    CNTabBarItem(
      label: 'Home',
      icon: const CNIcon.symbol('house'),
      activeIcon: const CNIcon.symbol('house.fill'),
    ),
    CNTabBarItem(
      label: 'Profile',
      icon: const CNIcon.symbol('person.crop.circle'),
      activeIcon: const CNIcon.symbol('person.crop.circle.fill'),
    ),
  ],
  currentIndex: _selectedIndex,
  onTap: (index) => setState(() => _selectedIndex = index),
  split: true, // Separates tabs when scrolling
  rightCount: 1, // Number of tabs pinned to the right
)
```

### Native iOS 26 Tab Bar (CNTabBarNative)

For full iOS 26 liquid glass tab bar experience with native UITabBarController:

```dart
@override
void initState() {
  super.initState();
  CNTabBarNative.enable(
    tabs: [
      CNTab(title: 'Home', sfSymbol: const CNIcon.symbol('house.fill')),
      CNTab(title: 'Search', sfSymbol: const CNIcon.symbol('magnifyingglass'), isSearchTab: true),
      CNTab(title: 'Profile', sfSymbol: const CNIcon.symbol('person.fill')),
    ],
    onTabSelected: (index) => setState(() => _selectedTab = index),
    onSearchChanged: (query) => filterResults(query),
  );
}

@override
void dispose() {
  CNTabBarNative.disable();
  super.dispose();
}
```

### Tab Bar with iOS 26 Search Tab

The `CNTabBar` supports iOS 26's native search tab feature with animated expansion:

```dart
CNTabBar(
  items: [
    CNTabBarItem(
      label: 'Overview',
      icon: const CNIcon.symbol('square.grid.2x2.fill'),
    ),
    CNTabBarItem(
      label: 'Projects',
      icon: const CNIcon.symbol('folder'),
      activeIcon: const CNIcon.symbol('folder.fill'),
    ),
  ],
  currentIndex: _index,
  onTap: (i) => setState(() => _index = i),
  // iOS 26 Search Tab Feature
  searchItem: CNTabBarSearchItem(
    placeholder: 'Find customer',
    // Control keyboard auto-activation
    automaticallyActivatesSearch: false, // Keyboard only opens on text field tap
    onSearchChanged: (query) {
      // Live filtering as user types
    },
    onSearchSubmit: (query) {
      // Handle search submission
    },
    onSearchActiveChanged: (isActive) {
      // React to search expand/collapse
    },
    style: const CNTabBarSearchStyle(
      iconSize: 20,
      buttonSize: 44,
      searchBarHeight: 44,
      animationDuration: Duration(milliseconds: 400),
      showClearButton: true,
    ),
  ),
  searchController: _searchController, // Optional programmatic control
)
```

#### automaticallyActivatesSearch

Controls whether the keyboard opens automatically when the search tab expands:

- `true` (default): Tapping the search button expands the bar AND opens the keyboard
- `false`: Tapping the search button only expands the bar; keyboard opens when user taps the text field

This mirrors `UISearchTab.automaticallyActivatesSearch` from UIKit.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  cupertino_native_plus: ^0.0.7
```

## Usage

### Basic Button

<p align="center">
  <img src="https://raw.githubusercontent.com/NarekManukyan/cupertino_native_plus/main/misc/screenshots/button_preview.png" width="300" alt="Button Preview"/>
</p>

```dart
CNButton(
  label: 'Get Started',
  icon: const CNIcon.symbol('arrow.right', size: Size(18, 18)),
  config: const CNButtonConfig(
    style: CNButtonStyle.filled,
    imagePlacement: CNImagePlacement.trailing,
  ),
  onPressed: () {
    // Handle tap
  },
)
```

### Button Styles Gallery

<p align="center">
  <img src="https://raw.githubusercontent.com/NarekManukyan/cupertino_native_plus/main/misc/screenshots/button_preview_2.png" width="300" alt="Glass Button Styles"/>
  <img src="https://raw.githubusercontent.com/NarekManukyan/cupertino_native_plus/main/misc/screenshots/button_preview_3.png" width="300" alt="Filled Button Styles"/>
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/NarekManukyan/cupertino_native_plus/main/misc/screenshots/button_preview_4.png" width="300" alt="More Button Styles"/>
</p>

### Icon-Only Button

<p align="center">
  <img src="https://raw.githubusercontent.com/NarekManukyan/cupertino_native_plus/main/misc/screenshots/icon_button_preview.png" width="300" alt="Icon Button Preview"/>
</p>

```dart
CNButton.icon(
  icon: const CNIcon.symbol('plus', size: Size(24, 24)),
  config: const CNButtonConfig(style: CNButtonStyle.glass),
  onPressed: () {},
)
```

### Native Icons

<p align="center">
  <img src="https://raw.githubusercontent.com/NarekManukyan/cupertino_native_plus/main/misc/screenshots/icon_preview.png" width="300" alt="Icon Preview"/>
</p>

```dart
CNIcon(
  asset: const CNIcon.symbol(
    'star.fill',
    size: Size(32, 32),
    color: Colors.amber,
    mode: CNSymbolRenderingMode.multicolor,
  ),
)
```

### Slider with Controller

<p align="center">
  <img src="https://raw.githubusercontent.com/NarekManukyan/cupertino_native_plus/main/misc/screenshots/slider_preview.jpg" width="300" alt="Slider Preview"/>
</p>

```dart
final controller = CNSliderController();

CNSlider(
  value: 0.5,
  min: 0,
  max: 1,
  controller: controller,
  onChanged: (value) {
    print('Value: $value');
  },
)

// Programmatic update
controller.setValue(0.75);
```

### Switch with Controller

<p align="center">
  <img src="https://raw.githubusercontent.com/NarekManukyan/cupertino_native_plus/main/misc/screenshots/switch_preview.png" width="300" alt="Switch Preview"/>
</p>

```dart
final controller = CNSwitchController();

CNSwitch(
  value: _isEnabled,
  onChanged: (value) {
    setState(() => _isEnabled = value);
  },
  controller: controller,
  color: Colors.green, // Optional tint color
)

// Programmatic control
controller.setValue(true, animated: true);
controller.setEnabled(false); // Disable interaction
```

### Popup Menu Button

<p align="center">
  <img src="https://raw.githubusercontent.com/NarekManukyan/cupertino_native_plus/main/misc/screenshots/popup_menu_preview.png" width="300" alt="Popup Menu Button"/>
  <img src="https://raw.githubusercontent.com/NarekManukyan/cupertino_native_plus/main/misc/screenshots/popup_menu_opened_preview.jpg" width="300" alt="Popup Menu Opened"/>
</p>

```dart
// Text-labeled popup menu
CNPopupMenuButton(
  buttonLabel: 'Options',
  buttonStyle: CNButtonStyle.glass,
  items: [
    CNPopupMenuItem(
      label: 'Edit',
      icon: const CNIcon.symbol('pencil'),
    ),
    CNPopupMenuItem(
      label: 'Share',
      icon: const CNIcon.symbol('square.and.arrow.up'),
    ),
    const CNPopupMenuDivider(), // Visual separator
    CNPopupMenuItem(
      label: 'Delete',
      icon: const CNIcon.symbol('trash', color: Colors.red),
      enabled: true,
    ),
  ],
  onSelected: (index) {
    print('Selected item at index: $index');
  },
)

// Icon-only popup menu (circular glass button)
CNPopupMenuButton.icon(
  buttonIcon: const CNIcon.symbol('ellipsis.circle', size: Size(24, 24)),
  buttonStyle: CNButtonStyle.glass,
  items: [
    CNPopupMenuItem(label: 'Option 1', icon: const CNIcon.symbol('star')),
    CNPopupMenuItem(label: 'Option 2', icon: const CNIcon.symbol('heart')),
  ],
  onSelected: (index) {},
)
```

### Segmented Control

<p align="center">
  <img src="https://raw.githubusercontent.com/NarekManukyan/cupertino_native_plus/main/misc/screenshots/segmented_control_preview.png" width="300" alt="Segmented Control Preview"/>
</p>

```dart
// Text-only segments
CNSegmentedControl(
  labels: ['Day', 'Week', 'Month', 'Year'],
  selectedIndex: _selectedIndex,
  onValueChanged: (index) {
    setState(() => _selectedIndex = index);
  },
  color: Colors.blue, // Optional tint color
)

// Segments with SF Symbols
CNSegmentedControl(
  labels: ['List', 'Grid', 'Gallery'],
  sfSymbols: [
    const CNIcon.symbol('list.bullet'),
    const CNIcon.symbol('square.grid.2x2'),
    const CNIcon.symbol('photo.on.rectangle'),
  ],
  selectedIndex: _viewMode,
  onValueChanged: (index) {
    setState(() => _viewMode = index);
  },
  shrinkWrap: true, // Size to content
)
```

### Liquid Glass Container

```dart
LiquidGlassContainer(
  config: LiquidGlassConfig(
    effect: CNGlassEffect.regular,
    shape: CNGlassEffectShape.rect,
    cornerRadius: 16,
    interactive: true,
  ),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Text('Glass Effect'),
  ),
)

// Or use the extension
Text('Glass Effect')
  .liquidGlass(cornerRadius: 16)
```

### Experimental: Glass Card

```dart
CNGlassCard(
  child: Text("Hello"),
  breathing: true, // Optional subtle glow animation
)
```

## Platform Fallbacks

| Platform | Liquid Glass | SF Symbols | Other Widgets |
|----------|:------------:|:----------:|:-------------:|
| iOS 26+ | Native | Native | Native |
| iOS 13-25 | CupertinoButton | Native via CNIcon | CupertinoWidgets |
| macOS 26+ | Native | Native | Native |
| macOS 11-25 | CupertinoButton | Native via CNIcon | CupertinoWidgets |
| Android/Web/etc | Material fallback | Flutter Icon | Material fallback |

## Version Detection

Check platform capabilities:

```dart
// Check if Liquid Glass is available
if (PlatformVersion.shouldUseNativeGlass) {
  // iOS 26+ or macOS 26+
}

// Check if SF Symbols are available (iOS 13+, macOS 11+)
if (PlatformVersion.supportsSFSymbols) {
  // Use CNIcon for native rendering
}

// Get specific version
print('iOS version: ${PlatformVersion.iosVersion}');
print('macOS version: ${PlatformVersion.macOSVersion}');
```

## Requirements

- **Flutter**: >= 3.3.0
- **Dart SDK**: >= 3.9.0
- **iOS**: >= 13.0 (Liquid Glass requires iOS 26+)
- **macOS**: >= 11.0 (Liquid Glass requires macOS 26+)

## Migration from Previous Versions

Version 0.0.7 introduces **breaking changes** to the icon/image API. See [MIGRATION.md](MIGRATION.md) for the full guide.

### Quick Reference

| Before | After |
|---|---|
| `CNSymbol('house', size: 20)` | `CNIcon.symbol('house', size: Size(20, 20))` |
| `CNIcon('path', size: 20)` | `CNIcon.asset('path', size: Size(20, 20))` |
| `customIcon: CupertinoIcons.home` | `icon: CNIcon.symbol('house.fill'), tint: color` |
| `CNButtonData(icon: CNSymbol(...))` | `CNButtonData(icon: CNIcon.symbol(...))` |
| `CNButtonDataConfig(glassMaterial: ...)` | `CNButtonData(theme: CNButtonTheme(glassMaterial: ...))` |

```yaml
dependencies:
  cupertino_native_plus: ^0.0.7
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Credits

This package is inspired by:
- [cupertino_native](https://pub.dev/packages/cupertino_native) by Serverpod

Special thanks to [gunumdogdu](https://github.com/gunumdogdu) for the improvements and fixes contributed through [cupertino_native_better](https://github.com/gunumdogdu/cupertino_native_better), including enhanced version detection, improved icon support, and various bug fixes.

## License

MIT License - see [LICENSE](LICENSE) for details.
