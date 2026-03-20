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
        iconName: button.iconName,
        iconImage: button.iconImage,
        iconSize: button.iconSize,
        iconColor: button.iconColor,
        tint: button.tint,
        style: button.style,
        isEnabled: button.isEnabled,
        onPressed: button.onPressed,
        glassEffectUnionId: button.glassEffectUnionId,
        glassEffectId: button.glassEffectId,
        glassEffectInteractive: button.glassEffectInteractive,
        namespace: namespace,
        config: button.config,
        imagePlacement: button.imagePlacement,
        glassMaterial: button.glassMaterial
      )
    }
  }
}

// MARK: - Data Model

@available(iOS 26.0, *)
struct GlassButtonData: Identifiable {
  let id = UUID()
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
  let config: GlassButtonConfig
  let imagePlacement: String
  let glassMaterial: String
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

  /// Loads a button icon image following the priority: xcasset → assetPath → imageBytes → iconBytes.
  private static func loadButtonImage(
    from dict: [String: Any],
    iconSize: CGFloat,
    iconColorARGB: Int?
  ) -> UIImage? {
    let size = CGSize(width: iconSize, height: iconSize)

    if let name = dict["xcassetName"] as? String, !name.isEmpty {
      return UIImage(named: name, in: Bundle.main, compatibleWith: nil)
    }

    if let assetPath = dict["assetPath"] as? String, !assetPath.isEmpty {
      let format = dict["imageFormat"] as? String
      if let argb = iconColorARGB {
        return ImageUtils.loadAndTintImage(
          from: assetPath, iconSize: iconSize, iconColor: argb,
          providedFormat: format, scale: UIScreen.main.scale
        )
      }
      let image = ImageUtils.loadFlutterAsset(assetPath, size: size, format: format, scale: UIScreen.main.scale)
      if let image, image.size != size {
        return ImageUtils.scaleImage(image, to: size, scale: UIScreen.main.scale)
      }
      return image
    }

    if let imageBytes = dict["imageBytes"] as? FlutterStandardTypedData {
      let format = dict["imageFormat"] as? String
      if let argb = iconColorARGB {
        return ImageUtils.createAndTintImage(
          from: imageBytes.data, iconSize: iconSize, iconColor: argb,
          providedFormat: format, scale: UIScreen.main.scale
        )
      }
      return ImageUtils.createImageFromData(imageBytes.data, format: format, size: size, scale: UIScreen.main.scale)
    }

    if let iconBytes = dict["iconBytes"] as? FlutterStandardTypedData {
      return ImageUtils.createImageFromData(iconBytes.data, format: "png", size: size, scale: UIScreen.main.scale)
    }

    return nil
  }

  /// Parses a button dictionary into a `GlassButtonData`, including image loading and callback setup.
  private static func parseButtonData(
    from dict: [String: Any],
    index: Int,
    channel: FlutterMethodChannel
  ) -> GlassButtonData {
    let title = dict["label"] as? String
    let iconName = dict["iconName"] as? String
    let iconSize = (dict["iconSize"] as? NSNumber).map { CGFloat(truncating: $0) } ?? 20.0
    let iconColorARGB = (dict["iconColor"] as? NSNumber)?.intValue
    let iconColor = iconColorARGB.map { Color(uiColor: ImageUtils.colorFromARGB($0)) }
    let tint = (dict["tint"] as? NSNumber).map { Color(uiColor: ImageUtils.colorFromARGB($0.intValue)) }
    let isEnabled = (dict["enabled"] as? NSNumber)?.boolValue ?? true
    let style = dict["style"] as? String ?? "glass"
    let glassEffectUnionId = dict["glassEffectUnionId"] as? String
    let glassEffectId = dict["glassEffectId"] as? String
    let glassEffectInteractive = (dict["glassEffectInteractive"] as? NSNumber)?.boolValue ?? false

    let iconImage = loadButtonImage(from: dict, iconSize: iconSize, iconColorARGB: iconColorARGB)

    let config = GlassButtonConfig(
      borderRadius: (dict["borderRadius"] as? NSNumber).map { CGFloat(truncating: $0) },
      top: (dict["paddingTop"] as? NSNumber).map { CGFloat(truncating: $0) },
      bottom: (dict["paddingBottom"] as? NSNumber).map { CGFloat(truncating: $0) },
      left: (dict["paddingLeft"] as? NSNumber).map { CGFloat(truncating: $0) },
      right: (dict["paddingRight"] as? NSNumber).map { CGFloat(truncating: $0) },
      horizontal: (dict["paddingHorizontal"] as? NSNumber).map { CGFloat(truncating: $0) },
      vertical: (dict["paddingVertical"] as? NSNumber).map { CGFloat(truncating: $0) },
      minHeight: (dict["minHeight"] as? NSNumber).map { CGFloat(truncating: $0) } ?? 44.0,
      spacing: (dict["imagePadding"] as? NSNumber).map { CGFloat(truncating: $0) } ?? 8.0
    )

    let imagePlacement = dict["imagePlacement"] as? String ?? "leading"
    let glassMaterial = dict["glassMaterial"] as? String ?? "regular"

    let callback: () -> Void = {
      channel.invokeMethod("buttonPressed", arguments: ["index": index], result: nil as FlutterResult?)
    }

    return GlassButtonData(
      title: title,
      iconName: iconName,
      iconImage: iconImage,
      iconSize: iconSize,
      iconColor: iconColor,
      tint: tint,
      style: style,
      isEnabled: isEnabled,
      onPressed: callback,
      glassEffectUnionId: glassEffectUnionId,
      glassEffectId: glassEffectId,
      glassEffectInteractive: glassEffectInteractive,
      config: config,
      imagePlacement: imagePlacement,
      glassMaterial: glassMaterial
    )
  }
}
