#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import SwiftUI

/// Configuration for GlassButtonSwiftUI with default values.
/// This is shared between iOS and macOS implementations.
@available(iOS 26.0, macOS 26.0, *)
public struct GlassButtonConfig {
  let borderRadius: CGFloat?
  let padding: EdgeInsets
  let minHeight: CGFloat
  let spacing: CGFloat
  /// Optional fixed width for the button content area. nil means unconstrained.
  let width: CGFloat?
  /// When true, the glass content expands to fill available width (maxWidth: .infinity).
  let expandWidth: Bool

  public init(
    borderRadius: CGFloat? = nil,
    padding: EdgeInsets = EdgeInsets(top: 8.0, leading: 12.0, bottom: 8.0, trailing: 12.0),
    minHeight: CGFloat = 44.0,
    spacing: CGFloat = 8.0,
    width: CGFloat? = nil,
    expandWidth: Bool = false
  ) {
    self.borderRadius = borderRadius
    self.padding = padding
    self.minHeight = minHeight
    self.spacing = spacing
    self.width = width
    self.expandWidth = expandWidth
  }

  /// Convenience initializer for individual padding values
  public init(
    borderRadius: CGFloat? = nil,
    top: CGFloat? = nil,
    bottom: CGFloat? = nil,
    left: CGFloat? = nil,
    right: CGFloat? = nil,
    horizontal: CGFloat? = nil,
    vertical: CGFloat? = nil,
    minHeight: CGFloat = 44.0,
    spacing: CGFloat = 8.0,
    width: CGFloat? = nil,
    expandWidth: Bool = false
  ) {
    self.borderRadius = borderRadius
    self.minHeight = minHeight
    self.spacing = spacing
    self.width = width
    self.expandWidth = expandWidth

    // Build EdgeInsets from provided values
    let defaultPadding = EdgeInsets(top: 8.0, leading: 12.0, bottom: 8.0, trailing: 12.0)
    self.padding = EdgeInsets(
      top: top ?? vertical ?? defaultPadding.top,
      leading: left ?? horizontal ?? defaultPadding.leading,
      bottom: bottom ?? vertical ?? defaultPadding.bottom,
      trailing: right ?? horizontal ?? defaultPadding.trailing
    )
  }
}
