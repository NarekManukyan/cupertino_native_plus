import Foundation
import CoreGraphics

/// Parsed configuration for LiquidGlassContainer. Shared between iOS and macOS.
/// Platform views convert [tintARGB] to UIColor/NSColor via ImageUtils.colorFromARGB.
struct LiquidGlassContainerConfig {
  static let defaultEffect = "regular"
  static let defaultShape = "capsule"

  let effect: String
  let shape: String
  let cornerRadius: CGFloat?
  let tintARGB: Int?
  let interactive: Bool
  let isDark: Bool

  /// Parses config from platform view [args] (e.g. creation params or updateConfig payload).
  static func parse(from args: Any?) -> LiquidGlassContainerConfig {
    var effect = defaultEffect
    var shape = defaultShape
    var cornerRadius: CGFloat?
    var tintARGB: Int?
    var interactive = false
    var isDark = false

    if let dict = args as? [String: Any] {
      if let s = dict["effect"] as? String { effect = s }
      if let s = dict["shape"] as? String { shape = s }
      if let n = dict["cornerRadius"] as? NSNumber { cornerRadius = CGFloat(n.doubleValue) }
      if let n = (dict["tint"] as? NSNumber) ?? (dict["tint"] as? Int).map(NSNumber.init) {
        tintARGB = n.intValue
      }
      if let b = dict["interactive"] as? Bool { interactive = b }
      if let b = dict["isDark"] as? Bool { isDark = b }
    }

    return LiquidGlassContainerConfig(
      effect: effect,
      shape: shape,
      cornerRadius: cornerRadius,
      tintARGB: tintARGB,
      interactive: interactive,
      isDark: isDark
    )
  }
}
