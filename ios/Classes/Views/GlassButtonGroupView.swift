import SwiftUI
import UIKit
import Flutter

// MARK: - ViewModel

@available(iOS 26.0, *)
class GlassButtonGroupViewModel: ObservableObject {
  @Published var buttons: [GlassButtonData] = []
  @Published var axis: Axis = .horizontal
  @Published var spacing: CGFloat = 8.0
  @Published var spacingForGlass: CGFloat = 40.0
}

// MARK: - SwiftUI View

@available(iOS 26.0, *)
struct GlassButtonGroupSwiftUI: View {
  @ObservedObject var viewModel: GlassButtonGroupViewModel
  @Namespace private var namespace

  var body: some View {
    GlassEffectContainer(spacing: viewModel.spacingForGlass) {
      if viewModel.axis == .horizontal {
        HStack(alignment: .center, spacing: viewModel.spacing) { buttonViews }
          .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
      } else {
        VStack(alignment: .center, spacing: viewModel.spacing) { buttonViews }
          .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
      }
    }
    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
    .ignoresSafeArea()
  }

  @ViewBuilder
  private var buttonViews: some View {
    ForEach(viewModel.buttons) { button in
      GlassButtonSwiftUI(
        title: button.title,
        iconConfig: button.iconConfig,
        theme: button.theme,
        style: button.style,
        isEnabled: button.isEnabled,
        onPressed: button.onPressed,
        glassEffectUnionId: button.glassEffectUnionId,
        glassEffectId: button.glassEffectId,
        glassEffectInteractive: button.glassEffectInteractive,
        namespace: namespace,
        config: button.config,
        imagePlacement: button.imagePlacement,
        contentAlignment: button.contentAlignment
      )
    }
  }
}

// MARK: - Data Model

@available(iOS 26.0, *)
struct GlassButtonData: Identifiable {
  let id = UUID()
  let title: String?
  let iconConfig: IconConfig?
  let theme: CNButtonTheme
  let style: String
  let isEnabled: Bool
  let onPressed: () -> Void
  let glassEffectUnionId: String?
  let glassEffectId: String?
  let glassEffectInteractive: Bool
  let config: GlassButtonConfig
  let imagePlacement: String
  let contentAlignment: String
}

// MARK: - Platform View

@available(iOS 26.0, *)
class GlassButtonGroupPlatformView: NSObject, FlutterPlatformView {
  private let container: UIView
  private let hostingController: UIHostingController<GlassButtonGroupSwiftUI>
  private let viewModel: GlassButtonGroupViewModel
  private let channel: FlutterMethodChannel

  init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
    self.container = UIView(frame: frame)
    self.container.backgroundColor = .clear
    self.container.clipsToBounds = false
    self.container.insetsLayoutMarginsFromSafeArea = false
    self.container.layoutMargins = .zero
    self.container.directionalLayoutMargins = .zero

    let channel = FlutterMethodChannel(
      name: "\(ChannelConstants.viewIdCupertinoNativeGlassButtonGroup)_\(viewId)",
      binaryMessenger: messenger
    )
    self.channel = channel

    let viewModel = GlassButtonGroupViewModel()
    self.viewModel = viewModel

    var isDark = false

    if let dict = args as? [String: Any] {
      isDark = dict["isDark"] as? Bool ?? false

      if let buttonsData = dict["buttons"] as? [[String: Any]] {
        viewModel.buttons = buttonsData.enumerated().map { index, d in
          Self.parseButtonData(from: d, index: index, channel: channel)
        }
      }
      if let axisStr = dict["axis"] as? String {
        viewModel.axis = axisStr == "horizontal" ? .horizontal : .vertical
      }
      if let v = dict["spacing"] as? NSNumber {
        viewModel.spacing = CGFloat(truncating: v)
      }
      if let v = dict["spacingForGlass"] as? NSNumber {
        viewModel.spacingForGlass = CGFloat(truncating: v)
      }
    }

    let swiftUIView = GlassButtonGroupSwiftUI(viewModel: viewModel)
    self.hostingController = UIHostingController(rootView: swiftUIView)
    self.hostingController.view.backgroundColor = .clear
    self.hostingController.view.insetsLayoutMarginsFromSafeArea = false
    self.hostingController.view.layoutMargins = .zero
    self.hostingController.view.directionalLayoutMargins = .zero
    self.hostingController.additionalSafeAreaInsets = .zero

    super.init()

    self.hostingController.overrideUserInterfaceStyle = isDark ? .dark : .light

    hostingController.view.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(hostingController.view)
    NSLayoutConstraint.activate([
      hostingController.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      hostingController.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      hostingController.view.topAnchor.constraint(equalTo: container.topAnchor),
      hostingController.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])

    container.addObserver(self, forKeyPath: "frame", options: [.new, .old], context: nil)
    container.addObserver(self, forKeyPath: "bounds", options: [.new, .old], context: nil)

    setupMethodChannel()
  }

  func view() -> UIView { container }

  // MARK: - Method Channel

  private func setupMethodChannel() {
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { result(FlutterMethodNotImplemented); return }

      switch call.method {
      case "updateButton":
        guard let args = call.arguments as? [String: Any],
              let index = args["index"] as? Int,
              let dict = args["button"] as? [String: Any] else {
          result(FlutterError(code: "bad_args", message: "Missing index or button", details: nil))
          return
        }
        guard index >= 0, index < self.viewModel.buttons.count else {
          result(FlutterError(code: "bad_index", message: "Index out of range", details: nil))
          return
        }
        self.viewModel.buttons[index] = Self.parseButtonData(from: dict, index: index, channel: self.channel)
        result(nil)

      case "updateButtons":
        guard let args = call.arguments as? [String: Any],
              let buttonsData = args["buttons"] as? [[String: Any]] else {
          result(FlutterError(code: "bad_args", message: "Missing buttons", details: nil))
          return
        }
        self.viewModel.buttons = buttonsData.enumerated().map { index, d in
          Self.parseButtonData(from: d, index: index, channel: self.channel)
        }
        result(nil)

      case "setBrightness":
        guard let args = call.arguments as? [String: Any],
              let isDark = (args["isDark"] as? NSNumber)?.boolValue else {
          result(FlutterError(code: "bad_args", message: "Missing isDark", details: nil))
          return
        }
        self.hostingController.overrideUserInterfaceStyle = isDark ? .dark : .light
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Frame observation

  override func observeValue(
    forKeyPath keyPath: String?,
    of object: Any?,
    change: [NSKeyValueChangeKey: Any]?,
    context: UnsafeMutableRawPointer?
  ) {
    guard keyPath == "frame" || keyPath == "bounds",
          let view = object as? UIView, view === container else {
      super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
      return
    }
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      self.container.setNeedsLayout()
      self.container.layoutIfNeeded()
      self.hostingController.view.setNeedsLayout()
      self.hostingController.view.layoutIfNeeded()
    }
  }

  deinit {
    container.removeObserver(self, forKeyPath: "frame")
    container.removeObserver(self, forKeyPath: "bounds")
  }

  // MARK: - Parsing helpers

  /// Pre-converts any `FlutterStandardTypedData` values to `Data` in the dict
  /// so that `IconConfig.from(dict:)` and `CNIcon.from(dict:)` can read them.
  private static func preprocessDict(_ dict: [String: Any]) -> [String: Any] {
    var out = dict
    for (key, value) in dict {
      if let typedData = value as? FlutterStandardTypedData {
        out[key] = typedData.data
      }
    }
    return out
  }

  /// Parses a button dictionary into a `GlassButtonData`.
  private static func parseButtonData(
    from dict: [String: Any],
    index: Int,
    channel: FlutterMethodChannel
  ) -> GlassButtonData {
    let processed = preprocessDict(dict)

    let title = processed["label"] as? String
    let isEnabled = (processed["enabled"] as? NSNumber)?.boolValue ?? true
    let style = processed["style"] as? String ?? "glass"
    let glassEffectUnionId = processed["glassEffectUnionId"] as? String
    let glassEffectId = processed["glassEffectId"] as? String
    let glassEffectInteractive = (processed["glassEffectInteractive"] as? NSNumber)?.boolValue ?? false

    let iconConfig = IconConfig.from(dict: processed)
    let theme = CNButtonTheme.from(dict: processed)

    let config = GlassButtonConfig(
      borderRadius: (processed["borderRadius"] as? NSNumber).map { CGFloat(truncating: $0) },
      top: (processed["paddingTop"] as? NSNumber).map { CGFloat(truncating: $0) },
      bottom: (processed["paddingBottom"] as? NSNumber).map { CGFloat(truncating: $0) },
      left: (processed["paddingLeft"] as? NSNumber).map { CGFloat(truncating: $0) },
      right: (processed["paddingRight"] as? NSNumber).map { CGFloat(truncating: $0) },
      horizontal: (processed["paddingHorizontal"] as? NSNumber).map { CGFloat(truncating: $0) },
      vertical: (processed["paddingVertical"] as? NSNumber).map { CGFloat(truncating: $0) },
      minHeight: (processed["minHeight"] as? NSNumber).map { CGFloat(truncating: $0) } ?? 44.0,
      spacing: (processed["imagePadding"] as? NSNumber).map { CGFloat(truncating: $0) } ?? 8.0,
      contentAlignment: processed["contentAlignment"] as? String ?? "center"
    )

    let imagePlacement = processed["imagePlacement"] as? String ?? "leading"
    let contentAlignment = processed["contentAlignment"] as? String ?? "center"

    let callback: () -> Void = {
      channel.invokeMethod("buttonPressed", arguments: ["index": index], result: nil as FlutterResult?)
    }

    return GlassButtonData(
      title: title,
      iconConfig: iconConfig.hasIcon ? iconConfig : nil,
      theme: theme,
      style: style,
      isEnabled: isEnabled,
      onPressed: callback,
      glassEffectUnionId: glassEffectUnionId,
      glassEffectId: glassEffectId,
      glassEffectInteractive: glassEffectInteractive,
      config: config,
      imagePlacement: imagePlacement,
      contentAlignment: contentAlignment
    )
  }
}
