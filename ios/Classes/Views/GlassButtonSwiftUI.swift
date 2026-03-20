import SwiftUI
import UIKit

/// Individual glass button using iOS 26 glassEffect() modifier.
@available(iOS 26.0, *)
struct GlassButtonSwiftUI: View {
  let title: String?
  let iconName: String?
  let iconImage: UIImage?
  let iconSize: CGFloat
  let iconColor: Color?
  let tint: Color?
  let style: String
  let isEnabled: Bool
  let onPressed: () -> Void
  let glassEffectUnionId: String?
  let glassEffectId: String?
  let glassEffectInteractive: Bool
  var namespace: Namespace.ID
  let config: GlassButtonConfig
  /// Icon placement relative to text: "leading" | "trailing" | "top" | "bottom".
  let imagePlacement: String
  /// Glass material: "clear" | "regular".
  let glassMaterial: String

  @Environment(\.colorScheme) private var colorScheme

  /// Tint takes priority over explicit iconColor; nil falls back to semantic .primary.
  private var effectiveIconStyle: Color? { iconColor ?? tint }
  private var effectiveLabelStyle: Color? { tint }

  var body: some View {
    // Compute shape once and reuse for both contentShape and glassEffect.
    let shape = buttonShape
    Button(action: onPressed) {
      labelContent
        .padding(config.padding)
        .frame(minWidth: frameMinWidth, maxWidth: frameMaxWidth, minHeight: config.minHeight)
        .contentShape(shape)
        .glassEffect(glassEffectValue, in: shape)
        .applyGlassEffectModifiers(
          unionId: glassEffectUnionId,
          id: glassEffectId,
          namespace: namespace
        )
        .animation(.easeInOut(duration: 0.25), value: animState)
    }
    .disabled(!isEnabled)
    .buttonStyle(NoHighlightButtonStyle())
  }

  // MARK: - Frame helpers

  private var frameMinWidth: CGFloat? { config.width }
  private var frameMaxWidth: CGFloat? {
    if let w = config.width { return w }
    return config.expandWidth ? .infinity : nil
  }

  // MARK: - Label content

  @ViewBuilder
  private var labelContent: some View {
    if let title, hasIcon {
      switch imagePlacement {
      case "trailing":
        HStack(spacing: config.spacing) {
          Text(title).foregroundStyle(effectiveLabelStyle ?? .primary)
          iconView
        }
      case "top":
        VStack(spacing: config.spacing) {
          iconView
          Text(title).foregroundStyle(effectiveLabelStyle ?? .primary)
        }
      case "bottom":
        VStack(spacing: config.spacing) {
          Text(title).foregroundStyle(effectiveLabelStyle ?? .primary)
          iconView
        }
      default: // "leading"
        HStack(spacing: config.spacing) {
          iconView
          Text(title).foregroundStyle(effectiveLabelStyle ?? .primary)
        }
      }
    } else if hasIcon {
      iconView
    } else if let text = title {
      Text(text)
        .foregroundStyle(effectiveLabelStyle ?? .primary)
    }
  }

  @ViewBuilder
  private var iconView: some View {
    if let img = iconImage {
      Image(uiImage: img)
        .renderingMode(effectiveIconStyle != nil ? .template : .original)
        .resizable()
        .foregroundStyle(effectiveIconStyle ?? .primary)
        .frame(width: iconSize, height: iconSize)
    } else if let name = iconName {
      Image(systemName: name)
        .renderingMode(.template)
        .resizable()
        .foregroundStyle(effectiveIconStyle ?? .primary)
        .frame(width: iconSize, height: iconSize)
    }
  }

  private var hasIcon: Bool { iconImage != nil || iconName != nil }

  // MARK: - Helpers

  private var buttonShape: AnyShape {
    if let radius = config.borderRadius {
      return AnyShape(RoundedRectangle(cornerRadius: radius))
    }
    return AnyShape(Capsule())
  }

  private var glassEffectValue: Glass {
    var glass: Glass = glassMaterial == "regular" ? Glass.regular : Glass.clear
    if glassEffectInteractive { glass = glass.interactive() }
    return glass
  }

  // MARK: - Animation state

  /// Equatable struct capturing every property that triggers an animation.
  /// Using a typed struct instead of a String avoids relying on Color.description,
  /// which has no stable format guarantee.
  private struct AnimState: Equatable {
    let iconSize: CGFloat
    let iconColor: Color?
    let tint: Color?
    let colorScheme: ColorScheme
    let style: String
    let imagePlacement: String
    let spacing: CGFloat
    let minHeight: CGFloat
    let borderRadius: CGFloat?
    let width: CGFloat?
    let expandWidth: Bool
    let glassMaterial: String
  }

  private var animState: AnimState {
    AnimState(
      iconSize: iconSize,
      iconColor: iconColor,
      tint: tint,
      colorScheme: colorScheme,
      style: style,
      imagePlacement: imagePlacement,
      spacing: config.spacing,
      minHeight: config.minHeight,
      borderRadius: config.borderRadius,
      width: config.width,
      expandWidth: config.expandWidth,
      glassMaterial: glassMaterial
    )
  }
}
