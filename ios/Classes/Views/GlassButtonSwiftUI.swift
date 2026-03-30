import SwiftUI
import UIKit

/// Individual glass button using iOS 26 glassEffect() modifier.
@available(iOS 26.0, *)
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

  private var effectiveLabelColor: Color? { theme.effectiveLabelColor }
  private var effectiveIconColor: Color? { theme.effectiveIconColor }
  private var effectiveBackgroundColor: Color? { theme.effectiveBackgroundColor }

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
    // The glass vibrancy system overrides foregroundStyle on inner views.
    // Applying .tint() on the button propagates the color through the glass
    // system correctly. nil falls back to the environment/system default.
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
        Label { Text(title).font(theme.labelFont) } icon: { iconView.foregroundStyle(effectiveIconColor ?? .primary) }
          .labelStyle(TrailingIconLabelStyle(spacing: config.spacing))
          .foregroundStyle(effectiveLabelColor ?? .primary)
      case "top":
        Label { Text(title).font(theme.labelFont) } icon: { iconView.foregroundStyle(effectiveIconColor ?? .primary) }
          .labelStyle(TopIconLabelStyle(spacing: config.spacing))
          .foregroundStyle(effectiveLabelColor ?? .primary)
      case "bottom":
        Label { Text(title).font(theme.labelFont) } icon: { iconView.foregroundStyle(effectiveIconColor ?? .primary) }
          .labelStyle(BottomIconLabelStyle(spacing: config.spacing))
          .foregroundStyle(effectiveLabelColor ?? .primary)
      default: // "leading"
        Label { Text(title).font(theme.labelFont) } icon: { iconView.foregroundStyle(effectiveIconColor ?? .primary) }
          .labelStyle(LeadingIconLabelStyle(spacing: config.spacing))
          .foregroundStyle(effectiveLabelColor ?? .primary)
      }
    } else if hasIcon {
      iconView
        .foregroundStyle(effectiveIconColor ?? .primary)
    } else if let text = title {
      Text(text)
        .font(theme.labelFont)
        .foregroundStyle(effectiveLabelColor ?? .primary)
    }
  }

  @ViewBuilder
  private var iconView: some View {
    if let ic = iconConfig, let asset = ic.asset {
      resolvedIconView(ic: ic, asset: asset)
    }
  }

  @ViewBuilder
  private func resolvedIconView(ic: IconConfig, asset: CNIcon) -> some View {
    let resolved = asset.resolve(
      width: ic.width, height: ic.height, scale: UIScreen.main.scale)
    if let image = resolved.0 {
      Image(uiImage: image)
        .renderingMode(effectiveIconColor != nil ? .template : .original)
        .resizable()
        .aspectRatio(contentMode: ic.contentMode)
        .frame(width: ic.width, height: ic.height)
    } else if let symbolName = resolved.1 {
      Image(systemName: symbolName)
        .renderingMode(.template)
        .resizable()
        .aspectRatio(contentMode: ic.contentMode)
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
    var glass: Glass = Self.glassMaterial(from: theme.glassMaterial)
    if let bg = effectiveBackgroundColor { glass = glass.tint(bg) }
    if glassEffectInteractive { glass = glass.interactive() }
    return glass
  }

  private static func glassMaterial(from string: String) -> Glass {
    switch string {
    case "regular": return .regular
    case "identity": return .identity
    default: return .clear
    }
  }

  // MARK: - Animation state

  /// Equatable struct capturing every property that triggers an animation.
  private struct AnimState: Equatable {
    let iconWidth: CGFloat
    let iconHeight: CGFloat
    let iconColor: Color?
    let labelColor: Color?
    let glassMaterial: String
    let style: String
    let imagePlacement: String
    let spacing: CGFloat
    let minHeight: CGFloat
    let borderRadius: CGFloat?
    let width: CGFloat?
    let expandWidth: Bool
    let frameMinWidth: CGFloat?
    let frameMaxWidth: CGFloat?
  }

  private var animState: AnimState {
    AnimState(
      iconWidth: iconConfig?.width ?? 0,
      iconHeight: iconConfig?.height ?? 0,
      iconColor: effectiveIconColor,
      labelColor: effectiveLabelColor,
      glassMaterial: theme.glassMaterial,
      style: style,
      imagePlacement: imagePlacement,
      spacing: config.spacing,
      minHeight: config.minHeight,
      borderRadius: config.borderRadius,
      width: config.width,
      expandWidth: config.expandWidth,
      frameMinWidth: frameMinWidth,
      frameMaxWidth: frameMaxWidth
    )
  }
}

// MARK: - Label styles for icon placement

@available(iOS 26.0, *)
private struct LeadingIconLabelStyle: LabelStyle {
  let spacing: CGFloat
  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: spacing) { configuration.icon; configuration.title }
  }
}

@available(iOS 26.0, *)
private struct TrailingIconLabelStyle: LabelStyle {
  let spacing: CGFloat
  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: spacing) { configuration.title; configuration.icon }
  }
}

@available(iOS 26.0, *)
private struct TopIconLabelStyle: LabelStyle {
  let spacing: CGFloat
  func makeBody(configuration: Configuration) -> some View {
    VStack(spacing: spacing) { configuration.icon; configuration.title }
  }
}

@available(iOS 26.0, *)
private struct BottomIconLabelStyle: LabelStyle {
  let spacing: CGFloat
  func makeBody(configuration: Configuration) -> some View {
    VStack(spacing: spacing) { configuration.title; configuration.icon }
  }
}
