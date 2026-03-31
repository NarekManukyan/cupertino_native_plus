## 0.0.7

**cupertino_native_plus** — native Liquid Glass and Cupertino-style controls for iOS and macOS via platform views. This release ships the current public API, unified icon handling, and documentation. See [MIGRATION.md](MIGRATION.md) for breaking changes.

### Breaking changes

- **`CNImageAsset` → `CNIcon`**: Shared icon/image values use **`CNIcon`** with named constructors (`CNIcon.symbol`, `CNIcon.asset`, `CNIcon.xcasset`, `CNIcon.svg`, `CNIcon.png`, `CNIcon.jpg`, `CNIcon.data`).
- **Platform icon widget → `CNIconView`**: The native `StatefulWidget` that draws symbols and assets is **`CNIconView`** (not `CNIcon`, which is the model type).
- **`CNTabBarItem`**: Icons are only **`icon`** / **`activeIcon`** as `CNIcon?`. Fields such as `imageAsset` / `activeImageAsset` and `customIcon` / `activeCustomIcon` are removed in favor of `CNIcon` sources.
- **Buttons & menus**: `CNButton`, `CNButtonData`, glass button groups, and related APIs use **`CNIcon?`** for icon slots.

### Features

- **Buttons & glass**: `CNButton`, `CNButton.icon`, `CNGlassButtonGroup`, `CNButtonData`, glass styles (`CNButtonStyle.glass`, `prominentGlass`, …), glass effect unioning (`glassEffectUnionId`), `LiquidGlassContainer`, `CNLiquidText`, experimental `CNGlassCard`.
- **Icons**: `CNIcon` model and `CNIconView` widget; SF Symbols, xcassets, Flutter asset paths, and raw bytes (SVG/PNG/JPG); `CNSymbol` + `CNSymbolRenderingMode` for legacy/symbol flows.
- **Tab bar**: `CNTabBar` with split mode, badges, lightweight native **`setBadges`** when only badges change; iOS 26-style **search tab** (`CNTabBarSearchItem`, `CNTabBarSearchStyle`, `CNTabBarSearchController`); **`CNTabBarNative`** (UITabBarController integration) and **`CNSearchScaffold`**.
- **Other controls**: `CNSlider`, `CNSwitch`, `CNSegmentedControl`, `CNPopupMenuButton` (including `preserveTopToBottomOrder`), `CNPopupGesture`, `CNSearchBar`, `CNToast`, `CNFloatingIsland`.
- **Platform version**: **`PlatformVersion`** auto-initializes; uses **`Platform.operatingSystemVersion`** parsing (reliable in release); **`supportsSFSymbols`** (iOS 13+, macOS 11+); Liquid Glass vs SF Symbol capability split (iOS 26+ vs iOS 13+).
- **Images on native**: Resolution-aware asset loading (`@2x`/`@3x`), shared **`ImageUtils`** on iOS/macOS; PNG/SVG/JPG pipelines and tinting.

### Improvements

- **Label styles (typography on native)**: `TextStyle` on **`CNButtonTheme.labelStyle`**, **`CNTabBar`** (`labelStyle` / `activeLabelStyle`), **`CNSegmentedControl`**, **`CNPopupMenuButton`** — `fontSize`, `fontWeight` (100–900), italic, `fontFamily` via `encodeTextStyle`; label **color** uses theme/tint/labelColor on native, not `TextStyle.color` in the channel map.
- **Glass & theme**: Clearer glass material and **`CNButtonTheme`** (tint, `labelColor`, `iconColor`, `backgroundColor`, `labelStyle`).
- **Native loading order**: Glass buttons and related paths prefer **xcasset** names, then Flutter asset paths.
- **Tab bar**: Split tab bar constraint fixes; unified `CNIcon` pipeline for items.
- **Swift**: `GlassButtonIconConfig` / `CNIcon` decoding aligned with Dart.

### Bug fixes (highlights)

- Version detection no longer relies on fragile platform channels in release builds.
- **SF Symbols** on iOS **13+** via `supportsSFSymbols` (not gated on iOS 26).
- Tab bar fallbacks, badge-only updates, split-mode selection, search keyboard behavior, popup menu ordering, modal shadow artifacts, **`MissingPluginException`** guards on hot reload, **`LiquidGlassContainer`** gestures (`IgnorePointer` where needed), dark mode / glass sync, PNG/SVG orientation and tinting, **CNButton** tap targets in Cupertino fallback.

### Documentation

- [README.md](README.md): Icon model vs **`CNIconView`**, **Label styles**, migration quick reference, `^0.0.7` snippet.
- [MIGRATION.md](MIGRATION.md): Step-by-step migration for 0.0.7.

---

## 0.0.6

- **Dark Mode Support for LiquidGlassContainer**: Added automatic dark mode detection and synchronization for LiquidGlassContainer, ensuring the glass effect correctly adapts to Flutter's theme changes
- **Gesture Detection Fixes**: Fixed gesture handling in LiquidGlassContainer by wrapping platform views in IgnorePointer, preventing the native view from intercepting touch events and allowing child widgets to receive gestures properly
- **Brightness Syncing Improvements**: Enhanced brightness synchronization for icons and other components, ensuring they automatically update when the system theme changes

---

## 0.0.5

- **Performance Improvements**: Added method channel updates for button groups to prevent full rebuilds and eliminate freezes when updating button parameters
- **Preserved Animations**: Button groups now update smoothly without losing native animations when button properties change (icon, color, image asset, etc.)
- **Efficient Updates**: Implemented granular updates for individual buttons in groups, only updating changed buttons instead of rebuilding the entire group
- **Reactive SwiftUI Updates**: Converted button group SwiftUI views to use ObservableObject pattern for efficient reactive updates
- **Button Parameter Updates**: Individual buttons in groups can now be updated dynamically via method channels without full view rebuilds

---

## 0.0.4

- **PNG Image Support**: Added full support for PNG images in all components (buttons, icons, popup menus, tab bars, glass button groups)
- **Automatic Asset Resolution**: Implemented automatic asset resolution based on device pixel ratio, similar to Flutter's automatic asset selection. The system now automatically selects the appropriate resolution-specific asset (e.g., `assets/icons/3.0x/checkcircle.png` for @3x devices) or falls back to the closest bigger size
- **ImageUtils Consolidation**: Consolidated all image loading, format detection, scaling, and tinting logic into a shared `ImageUtils.swift` class for better code maintainability and consistency
- **Fixed PNG Rendering**: Fixed PNG image rendering issues in buttons and glass button groups
- **Fixed Image Orientation**: Fixed image flipping issues for both PNG and SVG images when colors are applied
- **Made buttonIcon Optional**: Made `buttonIcon` parameter optional in `CNPopupMenuButton.icon` constructor, allowing developers to use only `buttonImageAsset` or `buttonCustomIcon`
- **Improved Glass Effect Appearance**: Fixed glass effect appearance synchronization with Flutter's theme mode to prevent dark-to-light transitions on initial render
- **Enhanced Image Format Detection**: Improved automatic image format detection from file extensions and magic bytes
- **Better Fallback Handling**: Improved fallback behavior when asset paths fail to load, ensuring images still render from provided image bytes

---

## 0.0.3

- Updated README to showcase all icon types (SVG assets, custom icons, and SF Symbols)
- Added comprehensive examples for all icon types in Button, Icon, Popup Menu Button, and Tab Bar sections
- Added icon support overview at the beginning of "What's in the package" section
- Clarified that all components support multiple icon types with unified priority system

---

## 0.0.2

- Updated README with corrected version requirements and improved documentation
- Fixed iOS minimum version requirement (13.0 instead of 14.0)
- Removed incorrect Xcode 26 beta requirement
- Added Contributing and License sections
- Improved package description and introduction

---

## 0.0.1

- Initial release
- Fixed iOS 26+ version detection using Platform.operatingSystemVersion parsing
- Native Liquid Glass widgets for iOS and macOS
- Support for CNButton, native icon widget, CNSlider, CNSwitch, CNTabBar, CNPopupMenuButton, CNSegmentedControl
- Glass effect unioning for grouped buttons
- LiquidGlassContainer for applying glass effects to any widget
