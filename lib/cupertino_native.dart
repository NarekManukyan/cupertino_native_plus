// Internal barrel — re-exported by cupertino_native_plus.dart.
// Add new public files here so they are accessible via the package entry point.

export 'cupertino_native_platform_interface.dart';
export 'cupertino_native_method_channel.dart';

// Components
export 'components/button.dart';
export 'components/icon.dart';
export 'components/slider.dart';
export 'components/switch.dart';
export 'components/tab_bar.dart';
export 'components/native_tab_bar.dart';
export 'components/popup_menu_button.dart';
export 'components/popup_gesture.dart';
export 'components/segmented_control.dart';
export 'components/glass_button_group.dart';
export 'components/liquid_glass_container.dart';
export 'components/search_bar.dart';
export 'components/search_scaffold.dart';
export 'components/toast.dart';
export 'components/floating_island.dart';
export 'components/liquid_text.dart';
export 'components/experimental/glass_card.dart';

// Styles
export 'style/button_style.dart';
export 'style/button_data.dart';
export 'style/button_theme.dart';
export 'style/sf_symbol.dart';
export 'style/image_placement.dart';
export 'style/glass_effect.dart';
export 'style/spotlight_mode.dart';
export 'style/tab_bar_search_item.dart';

// Utilities
export 'utils/version_detector.dart';
export 'utils/theme_helper.dart';

import 'cupertino_native_platform_interface.dart';

/// Top-level facade for simple plugin interactions.
///
/// Most developers should use the individual widgets and utilities directly
/// (e.g. [CNButton], [PlatformVersion]) rather than this class. This facade
/// exists primarily for version-checking during plugin setup.
///
/// Example:
/// ```dart
/// final version = await CupertinoNative().getPlatformVersion();
/// debugPrint('Platform: $version');
/// ```
class CupertinoNative {
  /// Returns a user-friendly platform version string from the host platform
  /// (e.g. `"iOS 26.0"` or `"macOS 26.0"`).
  Future<String?> getPlatformVersion() {
    return CupertinoNativePlatform.instance.getPlatformVersion();
  }
}
