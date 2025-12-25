# Future Features Roadmap

This document tracks planned features for the `cupertino_native_better` package, prioritized by popularity and implementation feasibility.

## iOS 26 Liquid Glass Components - Prioritized List

### Tier 1: Must-Have (Very High Demand)

| # | Component | Customizability | Complexity | Status | Notes |
|---|-----------|-----------------|------------|--------|-------|
| 1 | **CNNavigationBar** | High | Medium | Planned | Liquid Glass nav bar with scroll shrink behavior, large titles |
| 2 | **CNTextField** | High | Medium | Planned | Glass-styled text input with focus animations |
| 3 | **CNSheet** | High | Medium-High | Planned | Bottom sheet with detents (.medium, .large, custom) |
| 4 | **CNAlert/CNDialog** | Medium | Low | Planned | Native alert dialogs with glass blur background |
| 5 | **CNActionSheet** | Medium | Low | Planned | Action sheets with destructive styling |

### Tier 2: High Value (Very Useful)

| # | Component | Customizability | Complexity | Status | Notes |
|---|-----------|-----------------|------------|--------|-------|
| 6 | **CNContextMenu** | High | Medium | Planned | Long-press menus with preview (3D Touch style) |
| 7 | **CNPicker** | Medium | Medium | Planned | Wheel picker with glass styling |
| 8 | **CNDatePicker** | Medium | Medium | Planned | Date/time selection |
| 9 | **CNProgressIndicator** | Medium | Low | Planned | Circular & linear loading indicators |
| 10 | **CNToolbar** | High | Medium | Planned | Bottom toolbars with glass unioning |

### Tier 3: Nice-to-Have (Polish)

| # | Component | Customizability | Complexity | Status | Notes |
|---|-----------|-----------------|------------|--------|-------|
| 11 | **CNStepper** | Low | Low | Planned | +/- increment control |
| 12 | **CNPageControl** | Low | Low | Planned | Dot indicators for carousels |
| 13 | **CNColorPicker** | High | High | Planned | iOS 14+ color picker |
| 14 | **CNRefreshControl** | Medium | Medium | Planned | Pull-to-refresh with glass effect |
| 15 | **CNListTile** | High | Medium | Planned | Glass-styled list cells |

### Tier 4: Advanced (Differentiators)

| # | Component | Customizability | Complexity | Status | Notes |
|---|-----------|-----------------|------------|--------|-------|
| 16 | **CNHapticFeedback** | Low | Low | Planned | Haptic engine wrapper for native feel |
| 17 | **CNTipKit** | High | High | Planned | iOS 17+ tooltips/coach marks |
| 18 | **CNScrollView** | High | High | Planned | Native scroll physics & edge effects |
| 19 | **CNMenu** | Medium | Medium | Planned | iOS 14+ pull-down menus |

---

## Implementation Details

### CNNavigationBar
- **iOS API**: `UINavigationBar` with iOS 26 appearance
- **SwiftUI**: `NavigationStack` with `navigationBarTitleDisplayMode`
- **Features**:
  - Large title that collapses to inline on scroll
  - Glass blur effect behind bar
  - Back button with custom appearance
  - Trailing action buttons
  - Search integration (via `searchable` modifier)

### CNTextField
- **iOS API**: `UITextField` with custom styling
- **SwiftUI**: `TextField` with glass background
- **Features**:
  - Glass container effect on focus
  - Animated placeholder
  - Clear button
  - Secure text entry option
  - Custom keyboard types

### CNSheet (Bottom Sheet)
- **iOS API**: `UISheetPresentationController`
- **SwiftUI**: `.sheet` with `presentationDetents`
- **Features**:
  - Multiple detent sizes (.medium, .large, custom)
  - Drag indicator
  - Dismiss on drag
  - Glass background
  - Scrollable content

### CNContextMenu
- **iOS API**: `UIContextMenuInteraction`
- **SwiftUI**: `contextMenu` modifier
- **Features**:
  - Preview with blur effect
  - Nested menu support
  - SF Symbols in menu items
  - Destructive actions styling

### CNProgressIndicator
- **iOS API**: `UIActivityIndicatorView`, `UIProgressView`
- **SwiftUI**: `ProgressView`
- **Features**:
  - Circular (spinner) style
  - Linear (bar) style
  - Determinate/indeterminate modes
  - Custom tint colors

---

## Tab Bar Enhancements (Completed Features)

### CNTabBar Search Tab
- **Status**: Implemented in v1.2.0
- **Features**:
  - iOS 26 native search role (`Tab(role: .search)`)
  - Floating circular search button
  - Animated expansion to full search bar
  - Tab collapse during search
  - Programmatic control via `CNTabBarSearchController`

### CNTabBar Bottom Accessory (Future)
- **iOS API**: `tabViewBottomAccessory()` modifier
- **Features**:
  - Now Playing style accessory above tab bar
  - Inline/expanded placement states
  - Glass effect integration on scroll

---

## iOS 26 Specific APIs to Consider

### Tab Bar Minimize Behavior
```swift
TabView { ... }
    .tabBarMinimizeBehavior(.onScrollDown)
```

### Glass Effect Modifiers
```swift
.glassEffect(.regular)
.glassEffect(.prominent)
.glassEffect(.regular.interactive())
```

### Search Toolbar Behavior
```swift
.searchToolbarBehavior(.minimize)
```

---

## Sources & References

- [Apple: iOS 26 Liquid Glass Design](https://www.apple.com/newsroom/2025/06/apple-introduces-a-delightful-and-elegant-new-software-design/)
- [Donny Wals: Tab Bars on iOS 26](https://www.donnywals.com/exploring-tab-bars-on-ios-26-with-liquid-glass/)
- [Nil Coalescing: SwiftUI Search iOS 26](https://nilcoalescing.com/blog/SwiftUISearchEnhancementsIniOSAndiPadOS26/)
- [Seb Vidal: What's New in UIKit 26](https://sebvidal.com/blog/whats-new-in-uikit-26/)
- [Apple Developer: Tab Navigation](https://developer.apple.com/documentation/swiftui/enhancing-your-app-content-with-tab-navigation)
- [WWDC25: Build UIKit App with Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/284/)

---

## Contributing

When implementing new components:

1. **Research** the iOS 26 native API thoroughly
2. **Plan** the Flutter API to be intuitive and match iOS patterns
3. **Implement** native Swift/SwiftUI code for iOS 26+
4. **Fallback** to Cupertino widgets for older iOS versions
5. **Test** on both iOS 26+ and older versions
6. **Document** with examples and API reference

---

*Last updated: December 2025*
