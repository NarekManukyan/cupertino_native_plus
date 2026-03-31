/// Visual styles for [CNButton] and related controls.
///
/// On iOS 26+ and macOS 26+, [glass] and [prominentGlass] render as native
/// Liquid Glass effects. On older OS versions they fall back to a
/// [CupertinoButton]-based appearance.
enum CNButtonStyle {
  /// Minimal, text-only style with no background.
  plain,

  /// Subtle gray background style.
  gray,

  /// Tinted style — label and background use the accent color.
  tinted,

  /// Bordered button with a visible stroke.
  bordered,

  /// Prominent bordered style with an accent-colored stroke and fill.
  borderedProminent,

  /// Solid filled background style using the accent color.
  filled,

  /// Liquid Glass effect. Requires iOS 26+ or macOS 26+.
  ///
  /// Falls back to a translucent [CupertinoButton] on older OS versions.
  glass,

  /// More prominent Liquid Glass effect. Requires iOS 26+ or macOS 26+.
  ///
  /// Falls back to a filled [CupertinoButton] on older OS versions.
  prominentGlass,
}
