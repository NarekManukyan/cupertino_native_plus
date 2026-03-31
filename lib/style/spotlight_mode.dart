/// Defines the input mode for spotlight effects on glass components.
///
/// Used by [CNGlassCard] to determine how the spotlight position is calculated.
enum CNSpotlightMode {
  /// No spotlight effect
  none,

  /// Spotlight follows touch/pointer position
  touch,

  /// Spotlight responds to device tilt via gyroscope (iOS only)
  gyroscope,

  /// Combines both touch and gyroscope inputs
  both,
}
