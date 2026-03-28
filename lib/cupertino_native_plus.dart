/// cupertino_native_plus — native Cupertino widgets for Flutter.
///
/// Import this library to access all public components, styles, and utilities:
/// ```dart
/// import 'package:cupertino_native_plus/cupertino_native_plus.dart';
/// ```
///
/// ## Components
/// - [CNButton] — native push button with Liquid Glass support
/// - [CNIcon] — native SF Symbol / custom image renderer
/// - [CNSlider] — native UISlider / NSSlider
/// - [CNSwitch] — native UISwitch / NSSwitch
/// - [CNTabBar] — native tab bar with optional search tab
/// - [CNTabBarNative] — iOS 26+ UITabBarController integration
/// - [CNPopupMenuButton] — native popup/context menu
/// - [CNPopupGesture] — long-press popup gesture wrapper
/// - [CNSegmentedControl] — native UISegmentedControl / NSSegmentedControl
/// - [CNGlassButtonGroup] — unified Liquid Glass button group
/// - [LiquidGlassContainer] — Liquid Glass effect container
/// - [CNSearchBar] — native search bar with expand/collapse
/// - [CNSearchScaffold] — full-screen native tab bar + search scaffold
/// - [CNToast] — lightweight toast notifications
/// - [CNFloatingIsland] — floating pill with compact/expanded states
/// - [CNLiquidText] — text with native Liquid Glass effect
/// - [CNGlassCard] — EXPERIMENTAL glass card with spotlight
///
/// ## Styles & Configuration
/// - [CNButtonStyle], [CNButtonConfig], [CNButtonTheme], [CNButtonData]
/// - [CNImageAsset], [CNSymbol], [CNSymbolRenderingMode]
/// - [CNImagePlacement], [CNGlassEffect], [CNGlassEffectShape]
/// - [CNButtonGlassMaterial], [LiquidGlassConfig]
/// - [CNSpotlightMode], [CNTabBarSearchItem], [CNTabBarSearchStyle]
///
/// ## Utilities
/// - [PlatformVersion] — cached OS version detection (auto-initializes)
/// - [ThemeHelper] — brightness and primary-color helpers
/// - [LiquidGlassExtension] — `.liquidGlass()` extension on [Widget]
library;

export 'cupertino_native.dart';
