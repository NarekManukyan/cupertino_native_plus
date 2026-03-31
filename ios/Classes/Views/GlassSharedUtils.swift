import SwiftUI

// MARK: - NoHighlightButtonStyle

/// Removes all default button press highlights so the glass effect handles visual feedback.
@available(iOS 26.0, *)
struct NoHighlightButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
  }
}

// MARK: - Glass effect modifier helpers

@available(iOS 26.0, *)
extension View {
  /// Conditionally applies glassEffectUnion and glassEffectID modifiers.
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
