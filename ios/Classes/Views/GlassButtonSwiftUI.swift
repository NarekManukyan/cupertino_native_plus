import SwiftUI
import UIKit

/// SwiftUI button view with full Liquid Glass support using glassEffect() modifier.
/// This provides full blending and morphing capabilities when used in groups.
@available(iOS 26.0, *)
struct GlassButtonSwiftUI: View {
  let title: String?
  let iconName: String?
  let iconImage: UIImage?
  let iconSize: CGFloat
  let iconColor: Color?
  let tint: Color?
  let tintWhenGlassInverted: Color?
  let isRound: Bool
  let style: String
  let isEnabled: Bool
  let onPressed: () -> Void
  let glassEffectUnionId: String?
  let glassEffectId: String?
  let glassEffectInteractive: Bool
  var namespace: Namespace.ID
  let config: GlassButtonConfig
  
  /// Only set an explicit foreground when the user provided a tint. When nil, we do not set
  /// .foregroundStyle so the glass effect's built-in foreground effects apply — the system then
  /// adapts label/icon color based on content behind the glass (not interface dark/light).
  /// tintWhenGlassInverted cannot be honored for content-based inversion because Apple does not
  /// expose a "glass appearance" API; for adaptation, leave both tint and tintWhenGlassInverted unset.
  private var explicitLabelStyle: Color? { tint }
  private var explicitIconStyle: Color? { iconColor ?? tint }

  var body: some View {
    Button(action: onPressed) {
      HStack(spacing: config.spacing) {
        if let icon = iconImage {
          Image(uiImage: icon)
            .resizable()
            .scaledToFit()
            .frame(width: iconSize, height: iconSize)
        } else if let iconName = iconName {
          Image(systemName: iconName)
            .font(.system(size: iconSize))
            .applyForegroundStyle(explicitIconStyle)
        }
        
        if let title = title {
          Text(title)
            .applyForegroundStyle(explicitLabelStyle)
        }
      }
      .padding(config.padding)
      .frame(minHeight: config.minHeight)
      .contentShape(shapeForStyle(isRound, borderRadius: config.borderRadius))
      .glassEffect(glassEffectForStyle(style, interactive: glassEffectInteractive), in: shapeForStyle(isRound, borderRadius: config.borderRadius))
      .applyGlassEffectModifiers(unionId: glassEffectUnionId, id: glassEffectId, namespace: namespace)
      .animation(.easeInOut(duration: 0.25), value: iconSize)
      .animation(.easeInOut(duration: 0.25), value: iconColor)
      .animation(.easeInOut(duration: 0.25), value: tint)
      .animation(.easeInOut(duration: 0.25), value: style)
      .animation(.easeInOut(duration: 0.25), value: config.spacing)
      .animation(.easeInOut(duration: 0.25), value: config.padding)
      .animation(.easeInOut(duration: 0.25), value: config.minHeight)
      .animation(.easeInOut(duration: 0.25), value: config.borderRadius)
    }
    .disabled(!isEnabled)
    .buttonStyle(NoHighlightButtonStyle())
  }
  
  private func glassEffectForStyle(_ style: String, interactive: Bool) -> Glass {
    // Always use .regular for now - prominent glass API may be available in future
    var glass = Glass.regular
    
    // Make glass interactive if requested
    if interactive {
      glass = glass.interactive()
    }
    
    return glass
  }
  
  private func shapeForStyle(_ isRound: Bool, borderRadius: CGFloat?) -> some Shape {
    // If borderRadius is provided, use it
    if let radius = borderRadius {
      return AnyShape(RoundedRectangle(cornerRadius: radius))
    }
    // If no borderRadius provided, use capsule for round buttons
    if isRound {
      return AnyShape(Capsule())
    }
    // For non-round buttons without radius, also use capsule (as per user requirement)
    return AnyShape(Capsule())
  }
}

// Apply foregroundStyle only when a color is provided; otherwise leave foreground to the glass effect.
@available(iOS 26.0, *)
extension View {
  @ViewBuilder
  func applyForegroundStyle(_ color: Color?) -> some View {
    if let color = color {
      self.foregroundStyle(color)
    } else {
      self
    }
  }

  @ViewBuilder
  func applyGlassEffectModifiers(unionId: String?, id: String?, namespace: Namespace.ID) -> some View {
    if let unionId = unionId {
      if let id = id {
        self
          .glassEffectUnion(id: unionId, namespace: namespace)
          .glassEffectID(id, in: namespace)
      } else {
        self
          .glassEffectUnion(id: unionId, namespace: namespace)
      }
    } else if let id = id {
      self
        .glassEffectID(id, in: namespace)
    } else {
      self
    }
  }
}

// Custom button style that removes all highlights and press effects
@available(iOS 26.0, *)
struct NoHighlightButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      // No opacity or scale changes - let the glass effect handle visual feedback
  }
}

// Type erasure for Shape
@available(iOS 26.0, *)
struct AnyShape: Shape {
  private let _path: (CGRect) -> Path
  
  init<S: Shape>(_ shape: S) {
    _path = shape.path(in:)
  }
  
  func path(in rect: CGRect) -> Path {
    return _path(rect)
  }
}

