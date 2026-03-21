import SwiftUI
import AppKit

/// Individual glass button using macOS 26 glassEffect() modifier.
@available(macOS 26.0, *)
struct GlassButtonSwiftUI: View {
  let title: String?
  let iconConfig: IconConfig?
  let theme: CNButtonTheme
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

  @Environment(\.colorScheme) private var colorScheme

  private var effectiveLabelColor: Color? { theme.effectiveLabelColor(for: colorScheme) }
  private var effectiveIconColor: Color? { theme.effectiveIconColor(for: colorScheme) }

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
          Text(title).foregroundStyle(effectiveLabelColor ?? .primary)
          iconView
        }
      case "top":
        VStack(spacing: config.spacing) {
          iconView
          Text(title).foregroundStyle(effectiveLabelColor ?? .primary)
        }
      case "bottom":
        VStack(spacing: config.spacing) {
          Text(title).foregroundStyle(effectiveLabelColor ?? .primary)
          iconView
        }
      default: // "leading"
        HStack(spacing: config.spacing) {
          iconView
          Text(title).foregroundStyle(effectiveLabelColor ?? .primary)
        }
      }
    } else if hasIcon {
      iconView
    } else if let text = title {
      Text(text).foregroundStyle(effectiveLabelColor ?? .primary)
    }
  }

  @ViewBuilder
  private var iconView: some View {
    if let ic = iconConfig, let asset = ic.asset {
      resolvedIconView(ic: ic, asset: asset)
    }
  }

  @ViewBuilder
  private func resolvedIconView(ic: IconConfig, asset: CNImageAsset) -> some View {
    let scale = NSScreen.main?.backingScaleFactor ?? 2.0
    let resolved = asset.resolve(width: ic.width, height: ic.height, scale: scale)
    if let image = resolved.0 {
      Image(nsImage: image)
        .renderingMode(effectiveIconColor != nil ? .template : .original)
        .resizable()
        .aspectRatio(contentMode: ic.contentMode)
        .foregroundStyle(effectiveIconColor ?? .primary)
        .frame(width: ic.width, height: ic.height)
    } else if let symbolName = resolved.1 {
      Image(systemName: symbolName)
        .renderingMode(.template)
        .resizable()
        .aspectRatio(contentMode: ic.contentMode)
        .foregroundStyle(effectiveIconColor ?? .primary)
        .frame(width: ic.width, height: ic.height)
    }
  }

  private var hasIcon: Bool { iconConfig?.hasIcon ?? false }

  // MARK: - Helpers

  private var buttonShape: AnyShape {
    if let radius = config.borderRadius {
      return AnyShape(RoundedRectangle(cornerRadius: radius))
    }
    return AnyShape(Capsule())
  }

  private var glassEffectValue: Glass {
    var glass: Glass = theme.glassMaterial == "regular" ? Glass.regular : Glass.clear
    if glassEffectInteractive { glass = glass.interactive() }
    return glass
  }

  // MARK: - Animation state

  private struct AnimState: Equatable {
    let iconWidth: CGFloat
    let iconHeight: CGFloat
    let iconColor: Color?
    let labelColor: Color?
    let glassMaterial: String
    let colorScheme: ColorScheme
    let style: String
    let imagePlacement: String
    let spacing: CGFloat
    let minHeight: CGFloat
    let borderRadius: CGFloat?
    let width: CGFloat?
    let expandWidth: Bool
  }

  private var animState: AnimState {
    AnimState(
      iconWidth: iconConfig?.width ?? 0,
      iconHeight: iconConfig?.height ?? 0,
      iconColor: effectiveIconColor,
      labelColor: effectiveLabelColor,
      glassMaterial: theme.glassMaterial,
      colorScheme: colorScheme,
      style: style,
      imagePlacement: imagePlacement,
      spacing: config.spacing,
      minHeight: config.minHeight,
      borderRadius: config.borderRadius,
      width: config.width,
      expandWidth: config.expandWidth
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
