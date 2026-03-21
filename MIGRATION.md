# Migration Guide

## Migrating to 0.0.7

Version 0.0.7 unifies all icon and image handling under a single `CNImageAsset` type. The old `CNSymbol` class, the positional `CNImageAsset(path, size:)` constructor, and the `customIcon: IconData` parameter are all removed.

---

### 1. `CNSymbol` → `CNImageAsset.symbol()`

`CNSymbol` no longer exists. Replace every usage with `CNImageAsset.symbol()`.

**Before:**
```dart
import 'package:cupertino_native_plus/cupertino_native_plus.dart';

CNButton(
  label: 'Home',
  icon: CNSymbol('house.fill', size: 20),
  onPressed: () {},
)
```

**After:**
```dart
CNButton(
  label: 'Home',
  icon: const CNImageAsset.symbol('house.fill', size: Size(20, 20)),
  onPressed: () {},
)
```

Key differences:
- `size` is now `Size(width, height)` instead of a single `double`
- The constructor is `const`-safe
- `color` and `mode` parameters remain the same

**Full parameter mapping:**

| Old | New |
|---|---|
| `CNSymbol('name')` | `CNImageAsset.symbol('name')` |
| `CNSymbol('name', size: 24)` | `CNImageAsset.symbol('name', size: Size(24, 24))` |
| `CNSymbol('name', color: Colors.red)` | `CNImageAsset.symbol('name', color: Colors.red)` |
| `CNSymbol('name', mode: CNSymbolRenderingMode.multicolor)` | `CNImageAsset.symbol('name', mode: CNSymbolRenderingMode.multicolor)` |

---

### 2. `CNImageAsset(path, size:)` → `CNImageAsset.asset()`

The old positional constructor is gone. Use the named `.asset()` constructor.

**Before:**
```dart
CNButton(
  label: 'Custom',
  imageAsset: CNImageAsset('assets/icons/logo.svg', size: 24),
  onPressed: () {},
)
```

**After:**
```dart
CNButton(
  label: 'Custom',
  icon: const CNImageAsset.asset('assets/icons/logo.svg', size: Size(24, 24)),
  onPressed: () {},
)
```

Note that the parameter name changed from `imageAsset:` to `icon:`.

---

### 3. `customIcon: IconData` → removed

The `customIcon` parameter no longer exists on `CNButton` or `CNButtonData`. Flutter `IconData` (e.g., `CupertinoIcons`, `Icons`) cannot be passed directly to native views.

**Replacement options:**

**Option A — Use an equivalent SF Symbol with tint:**
```dart
// Before
CNButton(
  label: 'Favorite',
  customIcon: CupertinoIcons.heart_fill,
  tint: Colors.red,
  onPressed: () {},
)

// After
CNButton(
  label: 'Favorite',
  icon: const CNImageAsset.symbol('heart.fill', size: Size(20, 20)),
  tint: Colors.red,
  onPressed: () {},
)
```

**Option B — Render your Flutter icon to PNG bytes and use `CNImageAsset.png()`:**
```dart
// Render IconData to bytes first, then:
CNButton(
  label: 'Favorite',
  icon: CNImageAsset.png(iconBytes, size: Size(20, 20)),
  onPressed: () {},
)
```

For most cases Option A is the right choice — every `CupertinoIcons` value has an equivalent SF Symbol name.

---

### 4. `CNButtonData` API changes

**Before:**
```dart
CNButtonData(
  label: 'Save',
  icon: CNSymbol('checkmark'),        // was CNSymbol?
  customIcon: CupertinoIcons.check_mark, // removed
  imageAsset: CNImageAsset('path'),    // removed
  enabled: true,
)
```

**After:**
```dart
CNButtonData(
  label: 'Save',
  icon: const CNImageAsset.symbol('checkmark'), // unified CNImageAsset?
  enabled: true,
)
```

---

### 5. `glassMaterial` moved to `CNButtonTheme`

`CNButtonDataConfig.glassMaterial` is removed. Set it through `CNButtonTheme` instead.

**Before:**
```dart
CNButtonData(
  label: 'OK',
  config: CNButtonDataConfig(
    glassMaterial: CNButtonGlassMaterial.clear,
  ),
)
```

**After:**
```dart
CNButtonData(
  label: 'OK',
  theme: const CNButtonTheme(
    glassMaterial: CNButtonGlassMaterial.clear,
  ),
)
```

---

### 6. New `CNButtonTheme` for dual light/dark colors

`CNButtonTheme` replaces the flat `tint`, `iconColor`, `labelColor` properties when you need separate light and dark values.

```dart
// Simple tint (same as before — still supported on CNButton directly)
CNButton(
  label: 'Action',
  tint: Colors.blue,
  onPressed: () {},
)

// Per-scheme colors via CNButtonData
CNButtonData(
  label: 'Action',
  theme: const CNButtonTheme(
    tint: Colors.blue,            // light mode
    tintDark: Colors.lightBlue,   // dark mode
    glassMaterial: CNButtonGlassMaterial.regular,
  ),
)

// Separate label/icon colors
CNButtonData(
  label: 'Mixed',
  theme: const CNButtonTheme(
    labelColor: Colors.black,
    labelColorDark: Colors.white,
    iconColor: Colors.blue,
    iconColorDark: Colors.lightBlue,
  ),
)
```

Color priority: `tint`/`tintDark` > `labelColor`/`iconColor` > system default.

---

### 7. Tab Bar icons

`CNTabBarItem`, `CNTab`, and segmented control icons all accept `CNImageAsset` instead of `CNSymbol`.

**Before:**
```dart
CNTabBarItem(
  label: 'Home',
  icon: CNSymbol('house'),
  activeIcon: CNSymbol('house.fill'),
)
```

**After:**
```dart
CNTabBarItem(
  label: 'Home',
  icon: const CNImageAsset.symbol('house'),
  activeIcon: const CNImageAsset.symbol('house.fill'),
)
```

---

### 8. `CNIcon` widget

**Before:**
```dart
CNIcon(symbol: CNSymbol('star.fill', size: 32, color: Colors.amber))
```

**After:**
```dart
CNIcon(asset: const CNImageAsset.symbol('star.fill', size: Size(32, 32), color: Colors.amber))
```

---

### 9. `CNPopupMenuItem` icons

**Before:**
```dart
CNPopupMenuItem(label: 'Edit', icon: CNSymbol('pencil'))
```

**After:**
```dart
CNPopupMenuItem(label: 'Edit', icon: const CNImageAsset.symbol('pencil'))
```

---

## New capabilities in 0.0.7

Beyond the migration, 0.0.7 unlocks new icon sources that were not previously available:

```dart
// xcasset from your app's asset catalog
icon: const CNImageAsset.xcasset('MyAppLogo', size: Size(24, 24))

// SVG bytes (loaded from network, file, etc.)
icon: CNImageAsset.svg(svgBytes, size: Size(24, 24))

// PNG bytes
icon: CNImageAsset.png(pngBytes, size: Size(24, 24))

// JPG bytes
icon: CNImageAsset.jpg(jpgBytes, size: Size(24, 24))

// BoxFit for scaling behavior
icon: const CNImageAsset.asset('assets/logo.png', size: Size(40, 40), fit: BoxFit.cover)
```
