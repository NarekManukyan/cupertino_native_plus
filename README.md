# Liquid Glass for Flutter

Native Liquid Glass widgets for iOS and macOS in Flutter with pixel‑perfect fidelity.

This package provides native iOS and macOS widgets with Liquid Glass effects for Flutter applications. It uses Platform Views to embed real UIKit/AppKit controls inside Flutter, ensuring pixel-perfect fidelity with native look and feel while still fitting naturally into Flutter code.

## About This Package

This package (`cupertino_native_plus`) is based on the original [`cupertino_native`](https://github.com/serverpod/cupertino_native) package. It was created as a fork to provide continued development and support, as the original package's maintainer does not accept contributions and has stopped actively supporting the library. This package aims to maintain compatibility while providing ongoing improvements and bug fixes.

## Installation

Add the dependency in your app’s `pubspec.yaml`:

```bash
flutter pub add cupertino_native_plus
```

Then run `flutter pub get`.

Ensure your platform minimums are compatible:

- iOS `platform :ios, '13.0'`
- macOS 11.0+

**Note:** This package includes SVGKit dependency for native SVG rendering support.

**Liquid Glass Effects:** Native Liquid Glass effects require iOS 26+ or macOS 26+. On older versions, the package falls back to standard button styles and effects.

### Initialization

For Liquid Glass effects to work properly, initialize platform version detection early in your app:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize platform version detection early
  await PlatformVersion.initialize();
  runApp(const MyApp());
}
```

This ensures proper version detection for conditional Liquid Glass feature availability.

## What's in the package

This package ships a handful of native Liquid Glass widgets. Each widget exposes a simple, Flutter‑friendly API and falls back to a reasonable Flutter implementation on non‑Apple platforms.

**Icon Support:** All components that display icons support three types with a unified priority system:
- **Image Assets** (highest priority) - Custom SVG or PNG icons from your app's assets with automatic resolution selection
- **Custom Icons** (medium priority) - Flutter `IconData` (CupertinoIcons, Material Icons, etc.)
- **SF Symbols** (lowest priority) - Native Apple SF Symbols

When multiple icon types are provided, the component uses the highest priority one available.

### Slider

![Liquid Glass Slider](https://github.com/NarekManukyan/cupertino_native_plus/raw/main/misc/screenshots/slider.png)

```dart
double _value = 50;

CNSlider(
  value: _value,
  min: 0,
  max: 100,
  onChanged: (v) => setState(() => _value = v),
)
```

### Switch

![Liquid Glass Switch](https://github.com/NarekManukyan/cupertino_native_plus/raw/main/misc/screenshots/switch.png)

```dart
bool _on = true;

CNSwitch(
  value: _on,
  onChanged: (v) => setState(() => _on = v),
)
```

### Segmented Control

![Liquid Glass Segmented Control](https://github.com/NarekManukyan/cupertino_native_plus/raw/main/misc/screenshots/segmented-control.png)

```dart
int _index = 0;

CNSegmentedControl(
  labels: const ['One', 'Two', 'Three'],
  selectedIndex: _index,
  onValueChanged: (i) => setState(() => _index = i),
)
```

### Button

![Liquid Glass Button](https://github.com/NarekManukyan/cupertino_native_plus/raw/main/misc/screenshots/button.png)

```dart
CNButton(
  label: 'Press me',
  onPressed: () {},
)

// Icon button with SF Symbol
CNButton.icon(
  icon: const CNSymbol('heart.fill'),
  onPressed: () {},
)

// Icon button with custom icon (IconData)
CNButton.icon(
  customIcon: CupertinoIcons.heart_fill,
  onPressed: () {},
)

// Icon button with SVG asset
CNButton.icon(
  imageAsset: const CNImageAsset('assets/icons/heart.svg', size: 18),
  onPressed: () {},
)

// Button with image and custom placement
CNButton(
  label: 'Settings',
  imageAsset: CNImageAsset('assets/icons/settings.svg', size: 16),
  imagePlacement: CNImagePlacement.leading,
  imagePadding: 8.0,
  horizontalPadding: 16.0,
  onPressed: () {},
)

// Button with top image placement
CNButton(
  label: 'Profile',
  imageAsset: CNImageAsset('assets/icons/profile.svg', size: 16),
  imagePlacement: CNImagePlacement.top,
  onPressed: () {},
)
```

**Button Features:**
- Multiple button styles: `plain`, `gray`, `tinted`, `bordered`, `borderedProminent`, `filled`, `glass`, `prominentGlass`
- Image placement options: `leading`, `trailing`, `top`, `bottom` (for buttons with both image and label)
- Customizable image padding (spacing between image and text)
- Customizable horizontal padding (internal button spacing)
- Supports SVG assets, custom icons (IconData), and SF Symbols with unified priority system
- Liquid Glass effects with union IDs, effect IDs, and interactive effects (iOS 26+ and macOS 26+)

### Icon

![Liquid Glass Icon](https://github.com/NarekManukyan/cupertino_native_plus/raw/main/misc/screenshots/icon.png)

The `CNIcon` widget supports three types of icons with a unified priority system: **SVG Assets** > **Custom Icons** > **SF Symbols**.

```dart
// SF Symbol (default)
const CNIcon(symbol: CNSymbol('star'));

// SF Symbol with multicolor / hierarchical rendering
const CNIcon(
  symbol: CNSymbol('paintpalette.fill'),
  mode: CNSymbolRenderingMode.multicolor,
)

// Custom icon from IconData (CupertinoIcons, Material Icons, etc.)
const CNIcon(
  customIcon: CupertinoIcons.home,
  size: 24,
)

// SVG asset from your app's assets
const CNIcon(
  imageAsset: CNImageAsset('assets/icons/home.svg', size: 24),
)

// SVG with custom color
const CNIcon(
  imageAsset: CNImageAsset(
    'assets/icons/search.svg', 
    size: 32,
    color: CupertinoColors.systemBlue,
  ),
)
```

### Popup Menu Button

![Liquid Glass Popup Menu Button](https://github.com/NarekManukyan/cupertino_native_plus/raw/main/misc/screenshots/popup-menu-button.png)

Popup menu buttons support all icon types (SVG assets, custom icons, and SF Symbols):

```dart
// Using SF Symbols
final items = [
  const CNPopupMenuItem(label: 'New File', icon: CNSymbol('doc', size: 18)),
  const CNPopupMenuItem(label: 'New Folder', icon: CNSymbol('folder', size: 18)),
  const CNPopupMenuDivider(),
  const CNPopupMenuItem(label: 'Rename', icon: CNSymbol('rectangle.and.pencil.and.ellipsis', size: 18)),
];

CNPopupMenuButton(
  buttonLabel: 'Actions',
  items: items,
  onSelected: (index) {
    // Handle selection
  },
)

// Using custom icons (IconData)
final itemsWithCustomIcons = [
  const CNPopupMenuItem(label: 'Home', customIcon: CupertinoIcons.home),
  const CNPopupMenuItem(label: 'Settings', customIcon: CupertinoIcons.settings),
];

// Using SVG assets
final itemsWithSVG = [
  const CNPopupMenuItem(
    label: 'Home',
    imageAsset: CNImageAsset('assets/icons/home.svg', size: 18),
  ),
  const CNPopupMenuItem(
    label: 'Search',
    imageAsset: CNImageAsset('assets/icons/search.svg', size: 18),
  ),
];

// Icon-only popup menu button
CNPopupMenuButton.icon(
  buttonImageAsset: const CNImageAsset('assets/icons/menu.svg', size: 18),
  items: items,
  onSelected: (index) {},
)
```

### Tab Bar

![Liquid Glass Tab Bar](https://github.com/NarekManukyan/cupertino_native_plus/raw/main/misc/screenshots/tab-bar.png)

Tab bars support all icon types (SVG assets, custom icons, and SF Symbols):

```dart
int _tabIndex = 0;

// Using SF Symbols
CNTabBar(
  items: const [
    CNTabBarItem(label: 'Home', icon: CNSymbol('house.fill')),
    CNTabBarItem(label: 'Profile', icon: CNSymbol('person.crop.circle')),
    CNTabBarItem(label: 'Settings', icon: CNSymbol('gearshape.fill')),
  ],
  currentIndex: _tabIndex,
  onTap: (i) => setState(() => _tabIndex = i),
)

// Using custom icons (IconData)
CNTabBar(
  items: const [
    CNTabBarItem(
      label: 'Home',
      customIcon: CupertinoIcons.home,
      activeCustomIcon: CupertinoIcons.home_fill,
    ),
    CNTabBarItem(
      label: 'Profile',
      customIcon: CupertinoIcons.person,
    ),
  ],
  currentIndex: _tabIndex,
  onTap: (i) => setState(() => _tabIndex = i),
)

// Using SVG assets
CNTabBar(
  items: const [
    CNTabBarItem(
      label: 'Home',
      imageAsset: CNImageAsset('assets/icons/home.svg'),
      activeImageAsset: CNImageAsset('assets/icons/home-filled.svg'),
    ),
    CNTabBarItem(
      label: 'Search',
      imageAsset: CNImageAsset('assets/icons/search.svg'),
    ),
  ],
  currentIndex: _tabIndex,
  onTap: (i) => setState(() => _tabIndex = i),
)
```

## Liquid Glass Effects (iOS 26+ & macOS 26+)

This package provides native Liquid Glass effects for iOS 26+ and macOS 26+. Liquid Glass effects create beautiful, blurry, translucent surfaces that blend seamlessly with their backgrounds.

### Liquid Glass Container

Apply Liquid Glass effects to any widget using the `liquidGlass()` extension method:

```dart
// Simple glass effect
Text('Hello, World!').liquidGlass()

// Rectangle shape with corner radius
Text('Hello, World!').liquidGlass(
  shape: CNGlassEffectShape.rect,
  cornerRadius: 16.0,
)

// Tinted and interactive glass effect
Text('Hello, World!').liquidGlass(
  effect: CNGlassEffect.regular,
  tint: CupertinoColors.systemOrange,
  interactive: true,
)

// Prominent glass effect with circle shape
Container(
  width: 100,
  height: 100,
  child: Center(child: Text('Circle')),
).liquidGlass(
  effect: CNGlassEffect.prominent,
  shape: CNGlassEffectShape.circle,
)
```

**Liquid Glass Configuration:**
- **Effect variants:** `regular` (standard blur) or `prominent` (enhanced blur)
- **Shapes:** `capsule` (default), `rect` (with corner radius), or `circle`
- **Tint colors:** Optional color tinting for the glass effect
- **Interactive:** Makes the glass effect respond to touch/pointer interactions

### Glass Button Group

Group buttons together for proper Liquid Glass blending effects. Buttons in a group can blend together when using `glassEffectUnionId`:

```dart
CNGlassButtonGroup(
  axis: Axis.horizontal,
  spacing: 8.0,
  spacingForGlass: 40.0,
  buttons: [
    CNButton(
      label: 'Home',
      imageAsset: CNImageAsset('assets/icons/home.svg', size: 16),
      onPressed: () {},
      config: const CNButtonConfig(
        style: CNButtonStyle.glass,
        glassEffectUnionId: 'toolbar-group',
        glassEffectId: 'toolbar-home',
      ),
    ),
    CNButton(
      label: 'Search',
      imageAsset: CNImageAsset('assets/icons/search.svg', size: 16),
      onPressed: () {},
      config: const CNButtonConfig(
        style: CNButtonStyle.glass,
        glassEffectUnionId: 'toolbar-group',
        glassEffectId: 'toolbar-search',
      ),
    ),
    CNButton(
      label: 'Profile',
      imageAsset: CNImageAsset('assets/icons/profile.svg', size: 16),
      onPressed: () {},
      config: const CNButtonConfig(
        style: CNButtonStyle.glass,
        glassEffectUnionId: 'toolbar-group',
        glassEffectId: 'toolbar-profile',
      ),
    ),
  ],
)
```

**Glass Button Group Features:**
- **Horizontal or vertical layouts:** Control button arrangement with `axis`
- **Spacing control:** `spacing` controls layout spacing, `spacingForGlass` controls blending distance
- **Union IDs:** Buttons with the same `glassEffectUnionId` blend together
- **Effect IDs:** Buttons with the same `glassEffectId` can morph into each other during transitions
- **Interactive effects:** Enable `glassEffectInteractive` for real-time touch/pointer responses

### Glass Button Styles

Buttons support two new glass styles for iOS 26+ and macOS 26+:

```dart
// Regular glass button
CNButton(
  label: 'Glass',
  onPressed: () {},
  config: const CNButtonConfig(
    style: CNButtonStyle.glass,
  ),
)

// Prominent glass button (more prominent blur)
CNButton(
  label: 'Prominent Glass',
  onPressed: () {},
  config: const CNButtonConfig(
    style: CNButtonStyle.prominentGlass,
  ),
)

// Glass button with interactive effect
CNButton(
  label: 'Interactive',
  onPressed: () {},
  config: const CNButtonConfig(
    style: CNButtonStyle.glass,
    glassEffectInteractive: true,
  ),
)

// Glass buttons with morphing transitions
CNGlassButtonGroup(
  axis: Axis.horizontal,
  spacing: 24.0,
  spacingForGlass: 24.0,
  buttons: [
    CNButton(
      label: 'Morph Button 1',
      onPressed: () {},
      config: const CNButtonConfig(
        style: CNButtonStyle.glass,
        glassEffectId: 'morph-button', // Same ID = morphing
      ),
    ),
    CNButton(
      label: 'Morph Button 2',
      onPressed: () {},
      config: const CNButtonConfig(
        style: CNButtonStyle.glass,
        glassEffectId: 'morph-button', // Same ID = morphing
      ),
    ),
  ],
)
```

### Platform Version Detection

Liquid Glass effects require iOS 26+ or macOS 26+. The package automatically detects platform versions and falls back gracefully on older versions. Initialize version detection early in your app:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize platform version detection early
  await PlatformVersion.initialize();
  runApp(const MyApp());
}
```

On unsupported platforms or versions, glass effects are automatically disabled and widgets render normally.

## Custom Icons & Image Asset Support

This package supports three types of icons with a unified priority system: **Image Assets (SVG/PNG)** > **Custom Icons** > **SF Symbols**.

### Image Assets (SVG & PNG)

Render custom SVG or PNG icons natively with full color and size customization. The package automatically selects the appropriate resolution-specific asset based on device pixel ratio (e.g., `assets/icons/3.0x/checkcircle.png` for @3x devices), similar to Flutter's automatic asset selection:

```dart
// SVG icon from assets
const CNIcon(
  imageAsset: CNImageAsset('assets/icons/home.svg', size: 24),
)

// SVG with custom color
const CNIcon(
  imageAsset: CNImageAsset(
    'assets/icons/search.svg', 
    size: 32,
    color: CupertinoColors.systemBlue,
  ),
)

// SVG in tab bar
CNTabBar(
  items: const [
    CNTabBarItem(
      label: 'Home',
      imageAsset: CNImageAsset('assets/icons/home.svg'),
      activeImageAsset: CNImageAsset('assets/icons/home-filled.svg'),
    ),
    CNTabBarItem(
      label: 'Search',
      imageAsset: CNImageAsset('assets/icons/search.svg'),
    ),
  ],
  currentIndex: _tabIndex,
  onTap: (i) => setState(() => _tabIndex = i),
)

// SVG in buttons
CNButton.icon(
  imageAsset: const CNImageAsset('assets/icons/heart.svg', size: 18),
  onPressed: () {},
)

// SVG in popup menus
CNPopupMenuButton.icon(
  buttonImageAsset: const CNImageAsset('assets/icons/menu.svg', size: 18),
  items: const [
    CNPopupMenuItem(
      label: 'Home',
      imageAsset: CNImageAsset('assets/icons/home.svg', size: 18),
    ),
    CNPopupMenuItem(
      label: 'Search',
      imageAsset: CNImageAsset('assets/icons/search.svg', size: 18),
    ),
  ],
  onSelected: (index) {},
)
```

### Custom Icons (IconData)

Use any Flutter `IconData` including CupertinoIcons, Material Icons, or custom font icons:

```dart
// Custom icon from CupertinoIcons
const CNIcon(
  customIcon: CupertinoIcons.home,
  size: 24,
)

// Custom icon in tab bar
CNTabBar(
  items: const [
    CNTabBarItem(
      label: 'Home',
      customIcon: CupertinoIcons.home,
      activeCustomIcon: CupertinoIcons.home_fill,
    ),
    CNTabBarItem(
      label: 'Profile',
      customIcon: CupertinoIcons.person,
    ),
  ],
  currentIndex: _tabIndex,
  onTap: (i) => setState(() => _tabIndex = i),
)

// Custom icon in buttons
CNButton.icon(
  customIcon: CupertinoIcons.heart_fill,
  onPressed: () {},
)

// Custom icon in popup menus
CNPopupMenuButton.icon(
  buttonCustomIcon: CupertinoIcons.ellipsis_circle,
  items: const [
    CNPopupMenuItem(
      label: 'Home',
      customIcon: CupertinoIcons.home,
    ),
    CNPopupMenuItem(
      label: 'Settings',
      customIcon: CupertinoIcons.settings,
    ),
  ],
  onSelected: (index) {},
)
```

### SF Symbols (Default)

Native SF Symbols with full rendering mode support:

```dart
// Monochrome symbol
const CNIcon(symbol: CNSymbol('star'));

// Hierarchical symbol
const CNIcon(
  symbol: CNSymbol('paintpalette.fill'),
  mode: CNSymbolRenderingMode.hierarchical,
)

// Multicolor symbol
const CNIcon(
  symbol: CNSymbol('paintpalette.fill'),
  mode: CNSymbolRenderingMode.multicolor,
)
```

### Icon Priority System

All components follow the same priority order:

1. **`imageAsset`** - SVG/PNG assets with automatic resolution selection (highest priority)
2. **`customIcon`** - Flutter IconData (medium priority)  
3. **`symbol`** - SF Symbols (lowest priority)

### Automatic Asset Resolution

The package automatically resolves asset paths based on device pixel ratio, similar to Flutter's automatic asset selection. For example, if you provide `assets/icons/checkcircle.png`, the system will automatically look for:
- `assets/icons/3.0x/checkcircle.png` (for @3x devices)
- `assets/icons/2.0x/checkcircle.png` (for @2x devices)
- `assets/icons/checkcircle.png` (fallback)

If the exact resolution isn't found, it selects the closest bigger size. This ensures optimal image quality on all devices without manual asset management.

```dart
// This will use the image asset (SVG or PNG), ignoring the customIcon and symbol
const CNIcon(
  symbol: CNSymbol('house.fill'),
  customIcon: CupertinoIcons.home,
  imageAsset: CNImageAsset('assets/icons/home.svg'), // or .png
)
```

### PNG Image Support

PNG images are fully supported with automatic format detection, color tinting, and proper scaling:

```dart
// PNG icon with automatic resolution selection
CNButton.icon(
  imageAsset: CNImageAsset('assets/icons/checkcircle.png', size: 20),
  onPressed: () {},
)

// PNG icon with custom color
CNButton.icon(
  imageAsset: CNImageAsset(
    'assets/icons/checkcircle.png',
    size: 20,
    color: CupertinoColors.systemBlue,
  ),
  onPressed: () {},
)
```

### Badge Support

Display notification badges on tab bar items (iOS only):

```dart
CNTabBar(
  items: const [
    CNTabBarItem(
      label: 'Home',
      icon: CNSymbol('house.fill'),
      badge: '3', // Red badge with "3"
    ),
    CNTabBarItem(
      label: 'Messages',
      icon: CNSymbol('message.fill'),
      badge: '12',
    ),
  ],
  currentIndex: _tabIndex,
  onTap: (i) => setState(() => _tabIndex = i),
)
```

## Future Improvements

This package provides comprehensive native widget support with Liquid Glass effects. Future improvements include:

- Adding more native components (DatePicker, ActionSheet, etc.)
- Extending SVG support to remaining components (SegmentedControl, Slider, Switch)
- Reviewing the Flutter APIs to ensure consistency and eliminate redundancies
- Extending the flexibility and styling options of the widgets
- Investigating how to best combine scroll views with the native components
- Performance optimizations for SVG rendering and caching
- Additional Liquid Glass effect variants and configurations

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This package is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
