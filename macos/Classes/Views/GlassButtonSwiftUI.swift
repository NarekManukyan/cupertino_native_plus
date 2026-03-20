import SwiftUI
import AppKit

/// Individual glass button using macOS 26 glassEffect() modifier.
@available(macOS 26.0, *)
struct GlassButtonSwiftUI: View {
  let title: String?
  let iconName: String?
  let iconImage: NSImage?
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
      Image(nsImage: img)
        .renderingMode(effectiveIconStyle != nil ? .template : .original)
        .resizable()
        .scaledToFit()
        .foregroundStyle(effectiveIconStyle ?? .primary)
        .frame(width: iconSize, height: iconSize)
    } else if let name = iconName {
      Image(systemName: name)
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
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

// MARK: - Glass effect modifier helpers

@available(macOS 26.0, *)
extension View {
  @ViewBuilder
  func applyGlassEffectModifiers(unionId: String?, id: String?, namespace: Namespace.ID) -> some View {
    if let unionId = unionId, let id = id {
      self
        .glassEffectUnion(id: unionId, namespace: namespace)
        .glassEffectID(id, in: namespace)
    } else if let unionId = unionId {
      self
        .glassEffectUnion(id: unionId, namespace: namespace)
    } else if let id = id {
      self
        .glassEffectID(id, in: namespace)
    } else {
      self
    }
  }
}

// MARK: - NoHighlightButtonStyle

@available(macOS 26.0, *)
struct NoHighlightButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
  }
}

// MARK: - AnyShape

@available(macOS 26.0, *)
struct AnyShape: Shape {
  private let _path: (CGRect) -> Path

  init<S: Shape>(_ shape: S) {
    _path = shape.path(in:)
  }

  func path(in rect: CGRect) -> Path {
    return _path(rect)
  }
}
