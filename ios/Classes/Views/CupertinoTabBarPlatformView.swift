import Flutter
import UIKit
import SVGKit

class CupertinoTabBarPlatformView: NSObject, FlutterPlatformView, UITabBarDelegate {
  private let channel: FlutterMethodChannel
  private let container: UIView
  private var tabBar: UITabBar?
  private var tabBarLeft: UITabBar?
  private var tabBarRight: UITabBar?
  
  // MARK: - State Properties
  private var isSplit: Bool = false
  private var rightCountVal: Int = 1
  private var currentLabels: [String] = []
  private var currentSymbols: [String] = []
  private var currentActiveSymbols: [String] = []
  private var currentBadges: [String] = []
  private var currentHasBadgeFlags: [Bool] = []
  private var currentBadgeColors: [UIColor?] = []
  private static let badgeViewTagBase = 0xC0FFEE
  private var currentCustomIconBytes: [Data?] = []
  private var currentActiveCustomIconBytes: [Data?] = []
  private var currentImageAssetPaths: [String] = []
  private var currentActiveImageAssetPaths: [String] = []
  private var currentImageAssetData: [Data?] = []
  private var currentActiveImageAssetData: [Data?] = []
  private var currentImageAssetFormats: [String] = []
  private var currentActiveImageAssetFormats: [String] = []
  private var iconScale: CGFloat = UIScreen.main.scale
  private var leftInsetVal: CGFloat = 0
  private var rightInsetVal: CGFloat = 0
  private var splitSpacingVal: CGFloat = 12 // Apple's recommended spacing for visual separation
  private var currentIconSizes: [CGFloat] = [] // Track icon sizes for dynamic height calculation

  init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
    self.channel = FlutterMethodChannel(name: "CupertinoNativeTabBar_\(viewId)", binaryMessenger: messenger)
    self.container = UIView(frame: frame)

    var labels: [String] = []
    var symbols: [String] = []
    var activeSymbols: [String] = []
    var badges: [String] = []
    var hasBadgeFlags: [Bool] = []
    var badgeColors: [UIColor?] = []
    var customIconBytes: [Data?] = []
    var activeCustomIconBytes: [Data?] = []
    var imageAssetPaths: [String] = []
    var activeImageAssetPaths: [String] = []
    var imageAssetData: [Data?] = []
    var activeImageAssetData: [Data?] = []
    var imageAssetFormats: [String] = []
    var activeImageAssetFormats: [String] = []
    var iconScale: CGFloat = UIScreen.main.scale
    var sizes: [NSNumber?] = []
    var colors: [NSNumber] = [] // ignored; use tintColor
    var selectedIndex: Int = 0
    var isDark: Bool = false
    var tint: UIColor? = nil
    var bg: UIColor? = nil
    var split: Bool = false
    var rightCount: Int = 1
    var leftInset: CGFloat = 0
    var rightInset: CGFloat = 0

    if let dict = args as? [String: Any] {
      labels = (dict["labels"] as? [String]) ?? []
      symbols = (dict["sfSymbols"] as? [String]) ?? []
      activeSymbols = (dict["activeSfSymbols"] as? [String]) ?? []
      badges = (dict["badges"] as? [String]) ?? []
      hasBadgeFlags = (dict["hasBadgeFlags"] as? [Bool]) ?? []
      badgeColors = Self.parseUIColorArray(dict["badgeColors"])
      if let bytesArray = dict["customIconBytes"] as? [FlutterStandardTypedData?] {
        customIconBytes = bytesArray.map { $0?.data }
      }
      if let bytesArray = dict["activeCustomIconBytes"] as? [FlutterStandardTypedData?] {
        activeCustomIconBytes = bytesArray.map { $0?.data }
      }
      imageAssetPaths = (dict["imageAssetPaths"] as? [String]) ?? []
      activeImageAssetPaths = (dict["activeImageAssetPaths"] as? [String]) ?? []
      if let bytesArray = dict["imageAssetData"] as? [FlutterStandardTypedData?] {
        imageAssetData = bytesArray.map { $0?.data }
      }
      if let bytesArray = dict["activeImageAssetData"] as? [FlutterStandardTypedData?] {
        activeImageAssetData = bytesArray.map { $0?.data }
      }
      imageAssetFormats = (dict["imageAssetFormats"] as? [String]) ?? []
      activeImageAssetFormats = (dict["activeImageAssetFormats"] as? [String]) ?? []
      if let scale = dict["iconScale"] as? NSNumber {
        iconScale = CGFloat(truncating: scale)
      }
      sizes = (dict["sfSymbolSizes"] as? [NSNumber?]) ?? []
      colors = (dict["sfSymbolColors"] as? [NSNumber]) ?? []
      if let v = dict["selectedIndex"] as? NSNumber { selectedIndex = v.intValue }
      if let v = dict["isDark"] as? NSNumber { isDark = v.boolValue }
      if let style = dict["style"] as? [String: Any] {
        if let n = style["tint"] as? NSNumber { tint = Self.colorFromARGB(n.intValue) }
        if let n = style["backgroundColor"] as? NSNumber { bg = Self.colorFromARGB(n.intValue) }
      }
      if let s = dict["split"] as? NSNumber { split = s.boolValue }
      if let rc = dict["rightCount"] as? NSNumber { rightCount = rc.intValue }
      if let sp = dict["splitSpacing"] as? NSNumber { splitSpacingVal = CGFloat(truncating: sp) }
      // content insets controlled by Flutter padding; keep zero here
    }

    // Preload SVG assets dynamically based on what's actually being used
    let allAssetPaths = Set(imageAssetPaths + activeImageAssetPaths).filter { !$0.isEmpty }
    if !allAssetPaths.isEmpty {
      SVGImageLoader.shared.preloadAssetsFromPaths(Array(allAssetPaths))
    }

    super.init()

    container.backgroundColor = .clear
    if #available(iOS 13.0, *) { container.overrideUserInterfaceStyle = isDark ? .dark : .light }

    let appearance: UITabBarAppearance? = {
    if #available(iOS 13.0, *) { let ap = UITabBarAppearance(); ap.configureWithDefaultBackground(); return ap }
    return nil
  }()
    func buildItems(_ range: Range<Int>) -> [UITabBarItem] {
      var items: [UITabBarItem] = []
      for i in range {
        var image: UIImage? = nil
        var selectedImage: UIImage? = nil

        // Extract size for this item from sizes array
        let imgSize: CGSize? = (i < sizes.count) ? sizes[i].flatMap { $0.doubleValue > 0 ? CGSize(width: $0.doubleValue, height: $0.doubleValue) : nil } : nil

        // Priority: imageAsset > customIconBytes > SF Symbol
        // Unselected image
        if i < imageAssetData.count, let data = imageAssetData[i] {
          image = Self.createImageFromData(data, format: (i < imageAssetFormats.count) ? imageAssetFormats[i] : nil, scale: iconScale, size: imgSize)
        } else if i < imageAssetPaths.count && !imageAssetPaths[i].isEmpty {
          image = Self.loadFlutterAsset(imageAssetPaths[i], size: imgSize)
        } else if i < customIconBytes.count, let data = customIconBytes[i] {
          image = UIImage(data: data, scale: self.iconScale)?.withRenderingMode(.alwaysTemplate)
        } else if i < symbols.count && !symbols[i].isEmpty {
          // Apply size configuration if specified
          if i < sizes.count, let sizeNum = sizes[i], sizeNum.doubleValue > 0 {
            let config = UIImage.SymbolConfiguration(pointSize: CGFloat(sizeNum.doubleValue))
            image = UIImage(systemName: symbols[i], withConfiguration: config)
          } else {
            image = UIImage(systemName: symbols[i])
          }
        }
        
        // Selected image: Use active versions if available
        if i < activeImageAssetData.count, let data = activeImageAssetData[i] {
          selectedImage = Self.createImageFromData(data, format: (i < activeImageAssetFormats.count) ? activeImageAssetFormats[i] : nil, scale: iconScale, size: imgSize)
        } else if i < activeImageAssetPaths.count && !activeImageAssetPaths[i].isEmpty {
          selectedImage = Self.loadFlutterAsset(activeImageAssetPaths[i], size: imgSize)
        } else if i < activeCustomIconBytes.count, let data = activeCustomIconBytes[i] {
          selectedImage = UIImage(data: data, scale: self.iconScale)?.withRenderingMode(.alwaysTemplate)
        } else if i < activeSymbols.count && !activeSymbols[i].isEmpty {
          // Apply size configuration if specified
          if i < sizes.count, let sizeNum = sizes[i], sizeNum.doubleValue > 0 {
            let config = UIImage.SymbolConfiguration(pointSize: CGFloat(sizeNum.doubleValue))
            selectedImage = UIImage(systemName: activeSymbols[i], withConfiguration: config)
          } else {
            selectedImage = UIImage(systemName: activeSymbols[i])
          }
        } else {
          selectedImage = image // Fallback to same image
        }
        
        let title = (i < labels.count && !labels[i].isEmpty) ? labels[i] : nil
        let item = UITabBarItem(title: title, image: image, selectedImage: selectedImage)
        // Adjust title position for larger icons to prevent overlap
        // Default icon size is ~25pt
        if i < sizes.count, let sizeNum = sizes[i], sizeNum.doubleValue > 25 {
          let offset = CGFloat(sizeNum.doubleValue - 25)
          item.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: offset)
        }
        items.append(item)
      }
      return items
    }
    let count = max(labels.count, symbols.count)
    if split && count > rightCount {
      let leftEnd = count - rightCount
      let left = UITabBar(frame: .zero)
      let right = UITabBar(frame: .zero)
      tabBarLeft = left; tabBarRight = right
      left.translatesAutoresizingMaskIntoConstraints = false
      right.translatesAutoresizingMaskIntoConstraints = false
      left.delegate = self; right.delegate = self
      if let bg = bg { left.barTintColor = bg; right.barTintColor = bg }
      if #available(iOS 10.0, *), let tint = tint { left.tintColor = tint; right.tintColor = tint }
      if let ap = appearance { if #available(iOS 13.0, *) { left.standardAppearance = ap; right.standardAppearance = ap } }
      
      left.items = buildItems(0..<leftEnd)
      right.items = buildItems(leftEnd..<count)
      if selectedIndex < leftEnd, let items = left.items {
        left.selectedItem = items[selectedIndex]
        right.selectedItem = nil
      } else if let items = right.items {
        let idx = selectedIndex - leftEnd
        if idx >= 0 && idx < items.count { right.selectedItem = items[idx] }
        left.selectedItem = nil
      }
      container.addSubview(left); container.addSubview(right)
      // Compute content-fitting widths for both bars and apply symmetric spacing
      let spacing: CGFloat = splitSpacingVal
      let leftWidth = left.sizeThatFits(.zero).width + leftInset * 2
      let rightWidth = right.sizeThatFits(.zero).width + rightInset * 2
      let total = leftWidth + rightWidth + spacing
      
      // Ensure minimum width for single items to maintain circular shape
      // Following Apple's HIG: minimum 44pt touch target, with 8pt spacing
      let minItemWidth: CGFloat = 44.0 // Apple's minimum touch target size
      let adjustedRightWidth = max(rightWidth, minItemWidth * CGFloat(rightCount))
      let adjustedLeftWidth = max(leftWidth, minItemWidth * CGFloat(count - rightCount))
      let adjustedTotal = adjustedLeftWidth + adjustedRightWidth + spacing
      
      // If total exceeds container, fall back to proportional widths
      if adjustedTotal > container.bounds.width {
        let rightFraction = CGFloat(rightCount) / CGFloat(count)
        NSLayoutConstraint.activate([
          right.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -rightInset),
          right.topAnchor.constraint(equalTo: container.topAnchor),
          right.bottomAnchor.constraint(equalTo: container.bottomAnchor),
          right.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: rightFraction),
          left.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: leftInset),
          left.trailingAnchor.constraint(equalTo: right.leadingAnchor, constant: -spacing),
          left.topAnchor.constraint(equalTo: container.topAnchor),
          left.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
      } else {
        NSLayoutConstraint.activate([
          // Right bar fixed width, pinned to trailing
          right.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -rightInset),
          right.topAnchor.constraint(equalTo: container.topAnchor),
          right.bottomAnchor.constraint(equalTo: container.bottomAnchor),
          right.widthAnchor.constraint(equalToConstant: adjustedRightWidth),
          // Left bar fixed width, pinned to leading
          left.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: leftInset),
          left.topAnchor.constraint(equalTo: container.topAnchor),
          left.bottomAnchor.constraint(equalTo: container.bottomAnchor),
          left.widthAnchor.constraint(equalToConstant: adjustedLeftWidth),
          // Spacing between
          left.trailingAnchor.constraint(lessThanOrEqualTo: right.leadingAnchor, constant: -spacing),
        ])
      }
      // Force layout update for background and text rendering on iOS < 16
      // Re-assign items after layout to ensure labels render properly
      DispatchQueue.main.async { [weak self, weak left, weak right] in
        guard let self = self, let left = left, let right = right else { return }
        self.container.setNeedsLayout()
        self.container.layoutIfNeeded()
        left.setNeedsLayout()
        left.layoutIfNeeded()
        right.setNeedsLayout()
        right.layoutIfNeeded()
        // Re-assign items to force label rendering
        let leftItems = left.items
        let rightItems = right.items
        left.items = leftItems
        right.items = rightItems
        // Force another update cycle for text rendering
        DispatchQueue.main.async { [weak left, weak right] in
          guard let left = left, let right = right else { return }
          left.setNeedsDisplay()
          right.setNeedsDisplay()
          left.setNeedsLayout()
          left.layoutIfNeeded()
          right.setNeedsLayout()
          right.layoutIfNeeded()
        }
      }
    } else {
      let bar = UITabBar(frame: .zero)
      tabBar = bar
      bar.delegate = self
      bar.translatesAutoresizingMaskIntoConstraints = false
      if let bg = bg { bar.barTintColor = bg }
      if #available(iOS 10.0, *), let tint = tint { bar.tintColor = tint }
      if let ap = appearance { if #available(iOS 13.0, *) { bar.standardAppearance = ap; if #available(iOS 15.0, *) { bar.scrollEdgeAppearance = ap } } }
      bar.items = buildItems(0..<count)
      if selectedIndex >= 0, let items = bar.items, selectedIndex < items.count { bar.selectedItem = items[selectedIndex] }
      container.addSubview(bar)
      NSLayoutConstraint.activate([
        bar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
        bar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        bar.topAnchor.constraint(equalTo: container.topAnchor),
        bar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
      ])
      // Force layout update for background and text rendering on iOS < 16
      // Re-assign items after layout to ensure labels render properly
      DispatchQueue.main.async { [weak self, weak bar] in
        guard let self = self, let bar = bar else { return }
        self.container.setNeedsLayout()
        self.container.layoutIfNeeded()
        bar.setNeedsLayout()
        bar.layoutIfNeeded()
        // Re-assign items to force label rendering
        let items = bar.items
        bar.items = items
        // Force another update cycle for text rendering
        DispatchQueue.main.async { [weak bar] in
          guard let bar = bar else { return }
          bar.setNeedsDisplay()
          bar.setNeedsLayout()
          bar.layoutIfNeeded()
        }
      }
    }
    // Store split settings for future updates
    self.isSplit = split
    self.rightCountVal = rightCount
    self.currentLabels = labels
    self.currentSymbols = symbols
    self.currentActiveSymbols = activeSymbols
    self.currentBadges = badges
    self.currentHasBadgeFlags = hasBadgeFlags
    self.currentBadgeColors = badgeColors
    self.currentCustomIconBytes = customIconBytes
    self.currentActiveCustomIconBytes = activeCustomIconBytes
    self.currentImageAssetPaths = imageAssetPaths
    self.currentActiveImageAssetPaths = activeImageAssetPaths
    self.currentImageAssetData = imageAssetData
    self.currentActiveImageAssetData = activeImageAssetData
    self.currentImageAssetFormats = imageAssetFormats
    self.currentActiveImageAssetFormats = activeImageAssetFormats
    self.iconScale = iconScale
    self.leftInsetVal = leftInset
    self.rightInsetVal = rightInset
    self.currentIconSizes = sizes.compactMap { $0 }.map { CGFloat(truncating: $0) }
channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { result(nil); return }
      switch call.method {
      case "getIntrinsicSize":
        if let bar = self.tabBar ?? self.tabBarLeft ?? self.tabBarRight {
          let size = bar.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
          // Adjust height for larger icons - default icon is ~25pt, default height is ~49pt
          let defaultIconSize: CGFloat = 25.0
          let maxIconSize = self.currentIconSizes.max() ?? defaultIconSize
          let extraHeight = max(0, maxIconSize - defaultIconSize)
          let dynamicHeight = size.height + extraHeight
          result(["width": Double(size.width), "height": Double(dynamicHeight)])
        } else {
          result(["width": Double(self.container.bounds.width), "height": 50.0])
        }
      case "setItems":
        if let args = call.arguments as? [String: Any] {
          let labels = (args["labels"] as? [String]) ?? []
          let symbols = (args["sfSymbols"] as? [String]) ?? []
          let activeSymbols = (args["activeSfSymbols"] as? [String]) ?? []
          let badges = (args["badges"] as? [String]) ?? []
          let hasBadgeFlags = (args["hasBadgeFlags"] as? [Bool]) ?? []
          let badgeColors = Self.parseUIColorArray(args["badgeColors"])
          var customIconBytes: [Data?] = []
          var activeCustomIconBytes: [Data?] = []
          var imageAssetPaths: [String] = []
          var activeImageAssetPaths: [String] = []
          var imageAssetData: [Data?] = []
          var activeImageAssetData: [Data?] = []
          var imageAssetFormats: [String] = []
          var activeImageAssetFormats: [String] = []
          let sizes = (args["sfSymbolSizes"] as? [NSNumber?]) ?? []
          if let bytesArray = args["customIconBytes"] as? [FlutterStandardTypedData?] {
            customIconBytes = bytesArray.map { $0?.data }
          }
          if let bytesArray = args["activeCustomIconBytes"] as? [FlutterStandardTypedData?] {
            activeCustomIconBytes = bytesArray.map { $0?.data }
          }
          imageAssetPaths = (args["imageAssetPaths"] as? [String]) ?? []
          activeImageAssetPaths = (args["activeImageAssetPaths"] as? [String]) ?? []
          if let bytesArray = args["imageAssetData"] as? [FlutterStandardTypedData?] {
            imageAssetData = bytesArray.map { $0?.data }
          }
          if let bytesArray = args["activeImageAssetData"] as? [FlutterStandardTypedData?] {
            activeImageAssetData = bytesArray.map { $0?.data }
          }
          imageAssetFormats = (args["imageAssetFormats"] as? [String]) ?? []
          activeImageAssetFormats = (args["activeImageAssetFormats"] as? [String]) ?? []
          if let scale = args["iconScale"] as? NSNumber {
            self.iconScale = CGFloat(truncating: scale)
          }
          let selectedIndex = (args["selectedIndex"] as? NSNumber)?.intValue ?? 0
          self.currentLabels = labels
          self.currentSymbols = symbols
          self.currentActiveSymbols = activeSymbols
          self.currentBadges = badges
          self.currentHasBadgeFlags = hasBadgeFlags
          self.currentBadgeColors = badgeColors
          self.currentCustomIconBytes = customIconBytes
          self.currentActiveCustomIconBytes = activeCustomIconBytes
          self.currentImageAssetPaths = imageAssetPaths
          self.currentActiveImageAssetPaths = activeImageAssetPaths
          self.currentImageAssetData = imageAssetData
          self.currentActiveImageAssetData = activeImageAssetData
          self.currentImageAssetFormats = imageAssetFormats
          self.currentActiveImageAssetFormats = activeImageAssetFormats
          // Store icon sizes for dynamic height calculation
          self.currentIconSizes = sizes.compactMap { $0?.doubleValue }.map { CGFloat($0) }
          func buildItems(_ range: Range<Int>) -> [UITabBarItem] {
            var items: [UITabBarItem] = []
            for i in range {
              var image: UIImage? = nil
              var selectedImage: UIImage? = nil

              // Extract size for this item from sizes array
              let imgSize: CGSize? = (i < sizes.count) ? sizes[i].flatMap { $0.doubleValue > 0 ? CGSize(width: $0.doubleValue, height: $0.doubleValue) : nil } : nil

              // Priority: imageAsset > customIconBytes > SF Symbol
              // Unselected image
              if i < imageAssetData.count, let data = imageAssetData[i] {
                image = Self.createImageFromData(data, format: (i < imageAssetFormats.count) ? imageAssetFormats[i] : nil, scale: self.iconScale, size: imgSize)
              } else if i < imageAssetPaths.count && !imageAssetPaths[i].isEmpty {
                image = Self.loadFlutterAsset(imageAssetPaths[i], size: imgSize)
              } else if i < customIconBytes.count, let data = customIconBytes[i] {
                image = UIImage(data: data, scale: self.iconScale)?.withRenderingMode(.alwaysTemplate)
              } else if i < symbols.count && !symbols[i].isEmpty {
                // Apply size configuration if specified
                if i < sizes.count, let sizeNum = sizes[i], sizeNum.doubleValue > 0 {
                  let config = UIImage.SymbolConfiguration(pointSize: CGFloat(sizeNum.doubleValue))
                  image = UIImage(systemName: symbols[i], withConfiguration: config)
                } else {
                  image = UIImage(systemName: symbols[i])
                }
              }

              // Selected image: Use active versions if available
              if i < activeImageAssetData.count, let data = activeImageAssetData[i] {
                selectedImage = Self.createImageFromData(data, format: (i < activeImageAssetFormats.count) ? activeImageAssetFormats[i] : nil, scale: self.iconScale, size: imgSize)
              } else if i < activeImageAssetPaths.count && !activeImageAssetPaths[i].isEmpty {
                selectedImage = Self.loadFlutterAsset(activeImageAssetPaths[i], size: imgSize)
              } else if i < activeCustomIconBytes.count, let data = activeCustomIconBytes[i] {
                selectedImage = UIImage(data: data, scale: self.iconScale)?.withRenderingMode(.alwaysTemplate)
              } else if i < activeSymbols.count && !activeSymbols[i].isEmpty {
                // Apply size configuration if specified
                if i < sizes.count, let sizeNum = sizes[i], sizeNum.doubleValue > 0 {
                  let config = UIImage.SymbolConfiguration(pointSize: CGFloat(sizeNum.doubleValue))
                  selectedImage = UIImage(systemName: activeSymbols[i], withConfiguration: config)
                } else {
                  selectedImage = UIImage(systemName: activeSymbols[i])
                }
              } else {
                selectedImage = image // Fallback to same image
              }

              let title = (i < labels.count && !labels[i].isEmpty) ? labels[i] : nil
              let item = UITabBarItem(title: title, image: image, selectedImage: selectedImage)
              // Adjust title position for larger icons to prevent overlap
              if i < sizes.count, let sizeNum = sizes[i] {
                let pointSize = sizeNum.doubleValue
                if pointSize > 25 {
                  let offset = CGFloat(pointSize - 25)
                  item.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: offset)
                }
              }
              items.append(item)
            }
            return items
          }
          let count = max(labels.count, symbols.count)
          if self.isSplit && count > self.rightCountVal, let left = self.tabBarLeft, let right = self.tabBarRight {
            let leftEnd = count - self.rightCountVal
            left.items = buildItems(0..<leftEnd)
            right.items = buildItems(leftEnd..<count)
            if selectedIndex < leftEnd, let items = left.items { left.selectedItem = items[selectedIndex]; right.selectedItem = nil }
            else if let items = right.items {
              let idx = selectedIndex - leftEnd
              if idx >= 0 && idx < items.count { right.selectedItem = items[idx]; left.selectedItem = nil }
            }
            self.scheduleBadgeLayout()
            result(nil)
          } else if let bar = self.tabBar {
            bar.items = buildItems(0..<count)
            if let items = bar.items, selectedIndex >= 0, selectedIndex < items.count { bar.selectedItem = items[selectedIndex] }
            self.scheduleBadgeLayout()
            result(nil)
          } else {
            result(FlutterError(code: "state_error", message: "Tab bars not initialized", details: nil))
          }
        } else { result(FlutterError(code: "bad_args", message: "Missing items", details: nil)) }
      case "setLayout":
        if let args = call.arguments as? [String: Any] {
          let split = (args["split"] as? NSNumber)?.boolValue ?? false
          let rightCount = (args["rightCount"] as? NSNumber)?.intValue ?? 1
          // Insets are controlled by Flutter padding; keep stored zeros here
          let leftInset = self.leftInsetVal
          let rightInset = self.rightInsetVal
          if let sp = args["splitSpacing"] as? NSNumber { self.splitSpacingVal = CGFloat(truncating: sp) }
          let selectedIndex = (args["selectedIndex"] as? NSNumber)?.intValue ?? 0
          // Remove existing bars
          self.tabBar?.removeFromSuperview(); self.tabBar = nil
          self.tabBarLeft?.removeFromSuperview(); self.tabBarLeft = nil
          self.tabBarRight?.removeFromSuperview(); self.tabBarRight = nil
          let labels = self.currentLabels
          let symbols = self.currentSymbols
          let activeSymbols = self.currentActiveSymbols
          let badges = self.currentBadges
          let customIconBytes = self.currentCustomIconBytes
          let activeCustomIconBytes = self.currentActiveCustomIconBytes
          let imageAssetPaths = self.currentImageAssetPaths
          let activeImageAssetPaths = self.currentActiveImageAssetPaths
          let imageAssetData = self.currentImageAssetData
          let activeImageAssetData = self.currentActiveImageAssetData
          let imageAssetFormats = self.currentImageAssetFormats
          let activeImageAssetFormats = self.currentActiveImageAssetFormats
          let appearance: UITabBarAppearance? = {
            if #available(iOS 13.0, *) { let ap = UITabBarAppearance(); ap.configureWithDefaultBackground(); return ap }
            return nil
          }()
          let iconSizes = self.currentIconSizes
          func buildItems(_ range: Range<Int>) -> [UITabBarItem] {
            var items: [UITabBarItem] = []
            for i in range {
              var image: UIImage? = nil
              var selectedImage: UIImage? = nil

              // Extract size for this item from stored icon sizes
              let imgSize: CGSize? = (i < iconSizes.count && iconSizes[i] > 0) ? CGSize(width: iconSizes[i], height: iconSizes[i]) : nil

              // Priority: imageAsset > customIconBytes > SF Symbol
              // Unselected image
              if i < imageAssetData.count, let data = imageAssetData[i] {
                image = Self.createImageFromData(data, format: (i < imageAssetFormats.count) ? imageAssetFormats[i] : nil, scale: self.iconScale, size: imgSize)
              } else if i < imageAssetPaths.count && !imageAssetPaths[i].isEmpty {
                image = Self.loadFlutterAsset(imageAssetPaths[i], size: imgSize)
              } else if i < customIconBytes.count, let data = customIconBytes[i] {
                image = UIImage(data: data, scale: self.iconScale)?.withRenderingMode(.alwaysTemplate)
              } else if i < symbols.count && !symbols[i].isEmpty {
                // Apply size configuration if stored
                if i < iconSizes.count && iconSizes[i] > 0 {
                  let config = UIImage.SymbolConfiguration(pointSize: iconSizes[i])
                  image = UIImage(systemName: symbols[i], withConfiguration: config)
                } else {
                  image = UIImage(systemName: symbols[i])
                }
              }

              // Selected image: Use active versions if available
              if i < activeImageAssetData.count, let data = activeImageAssetData[i] {
                selectedImage = Self.createImageFromData(data, format: (i < activeImageAssetFormats.count) ? activeImageAssetFormats[i] : nil, scale: self.iconScale, size: imgSize)
              } else if i < activeImageAssetPaths.count && !activeImageAssetPaths[i].isEmpty {
                selectedImage = Self.loadFlutterAsset(activeImageAssetPaths[i], size: imgSize)
              } else if i < activeCustomIconBytes.count, let data = activeCustomIconBytes[i] {
                selectedImage = UIImage(data: data, scale: self.iconScale)?.withRenderingMode(.alwaysTemplate)
              } else if i < activeSymbols.count && !activeSymbols[i].isEmpty {
                // Apply size configuration if stored
                if i < iconSizes.count && iconSizes[i] > 0 {
                  let config = UIImage.SymbolConfiguration(pointSize: iconSizes[i])
                  selectedImage = UIImage(systemName: activeSymbols[i], withConfiguration: config)
                } else {
                  selectedImage = UIImage(systemName: activeSymbols[i])
                }
              } else {
                selectedImage = image // Fallback to same image
              }
              
              let title = (i < labels.count && !labels[i].isEmpty) ? labels[i] : nil
              let item = UITabBarItem(title: title, image: image, selectedImage: selectedImage)
              items.append(item)
            }
            return items
          }
          let count = max(labels.count, symbols.count)
          if split && count > rightCount {
            let leftEnd = count - rightCount
            let left = UITabBar(frame: .zero)
            let right = UITabBar(frame: .zero)
            self.tabBarLeft = left; self.tabBarRight = right
            left.translatesAutoresizingMaskIntoConstraints = false
            right.translatesAutoresizingMaskIntoConstraints = false
            left.delegate = self; right.delegate = self
            if let ap = appearance { if #available(iOS 13.0, *) { left.standardAppearance = ap; right.standardAppearance = ap } }
            left.items = buildItems(0..<leftEnd)
            right.items = buildItems(leftEnd..<count)
            if selectedIndex < leftEnd, let items = left.items { left.selectedItem = items[selectedIndex]; right.selectedItem = nil }
            else if let items = right.items { let idx = selectedIndex - leftEnd; if idx >= 0 && idx < items.count { right.selectedItem = items[idx]; left.selectedItem = nil } }
            self.container.addSubview(left); self.container.addSubview(right)
            let spacing: CGFloat = splitSpacingVal
            let leftWidth = left.sizeThatFits(.zero).width + leftInset * 2
            let rightWidth = right.sizeThatFits(.zero).width + rightInset * 2
            let total = leftWidth + rightWidth + spacing
            
            // Ensure minimum width for single items to maintain circular shape
            let minItemWidth: CGFloat = 50.0 // Minimum width per item
            let adjustedRightWidth = max(rightWidth, minItemWidth * CGFloat(rightCount))
            let adjustedLeftWidth = max(leftWidth, minItemWidth * CGFloat(count - rightCount))
            let adjustedTotal = adjustedLeftWidth + adjustedRightWidth + spacing
            
            if adjustedTotal > self.container.bounds.width {
              let rightFraction = CGFloat(rightCount) / CGFloat(count)
              NSLayoutConstraint.activate([
                right.trailingAnchor.constraint(equalTo: self.container.trailingAnchor, constant: -rightInset),
                right.topAnchor.constraint(equalTo: self.container.topAnchor),
                right.bottomAnchor.constraint(equalTo: self.container.bottomAnchor),
                right.widthAnchor.constraint(equalTo: self.container.widthAnchor, multiplier: rightFraction),
                left.leadingAnchor.constraint(equalTo: self.container.leadingAnchor, constant: leftInset),
                left.trailingAnchor.constraint(equalTo: right.leadingAnchor, constant: -spacing),
                left.topAnchor.constraint(equalTo: self.container.topAnchor),
                left.bottomAnchor.constraint(equalTo: self.container.bottomAnchor),
              ])
            } else {
              NSLayoutConstraint.activate([
                right.trailingAnchor.constraint(equalTo: self.container.trailingAnchor, constant: -rightInset),
                right.topAnchor.constraint(equalTo: self.container.topAnchor),
                right.bottomAnchor.constraint(equalTo: self.container.bottomAnchor),
                right.widthAnchor.constraint(equalToConstant: adjustedRightWidth),
                left.leadingAnchor.constraint(equalTo: self.container.leadingAnchor, constant: leftInset),
                left.topAnchor.constraint(equalTo: self.container.topAnchor),
                left.bottomAnchor.constraint(equalTo: self.container.bottomAnchor),
                left.widthAnchor.constraint(equalToConstant: adjustedLeftWidth),
                left.trailingAnchor.constraint(lessThanOrEqualTo: right.leadingAnchor, constant: -spacing),
              ])
            }
            // Force layout update for background and text rendering on iOS < 16
            // Re-assign items after layout to ensure labels render properly
            DispatchQueue.main.async { [weak self, weak left, weak right] in
              guard let self = self, let left = left, let right = right else { return }
              self.container.setNeedsLayout()
              self.container.layoutIfNeeded()
              left.setNeedsLayout()
              left.layoutIfNeeded()
              right.setNeedsLayout()
              right.layoutIfNeeded()
              // Re-assign items to force label rendering
              let leftItems = left.items
              let rightItems = right.items
              left.items = leftItems
              right.items = rightItems
              // Force another update cycle for text rendering
              DispatchQueue.main.async { [weak left, weak right] in
                guard let left = left, let right = right else { return }
                left.setNeedsDisplay()
                right.setNeedsDisplay()
                left.setNeedsLayout()
                left.layoutIfNeeded()
                right.setNeedsLayout()
                right.layoutIfNeeded()
              }
            }
          } else {
            let bar = UITabBar(frame: .zero)
            self.tabBar = bar
            bar.delegate = self
            bar.translatesAutoresizingMaskIntoConstraints = false
            if let ap = appearance { if #available(iOS 13.0, *) { bar.standardAppearance = ap; if #available(iOS 15.0, *) { bar.scrollEdgeAppearance = ap } } }
            bar.items = buildItems(0..<count)
            if let items = bar.items, selectedIndex >= 0, selectedIndex < items.count { bar.selectedItem = items[selectedIndex] }
            self.container.addSubview(bar)
            NSLayoutConstraint.activate([
              bar.leadingAnchor.constraint(equalTo: self.container.leadingAnchor),
              bar.trailingAnchor.constraint(equalTo: self.container.trailingAnchor),
              bar.topAnchor.constraint(equalTo: self.container.topAnchor),
              bar.bottomAnchor.constraint(equalTo: self.container.bottomAnchor),
            ])
            // Force layout update for background and text rendering on iOS < 16
            // Re-assign items after layout to ensure labels render properly
            DispatchQueue.main.async { [weak self, weak bar] in
              guard let self = self, let bar = bar else { return }
              self.container.setNeedsLayout()
              self.container.layoutIfNeeded()
              bar.setNeedsLayout()
              bar.layoutIfNeeded()
              // Re-assign items to force label rendering
              let items = bar.items
              bar.items = items
              // Force another update cycle for text rendering
              DispatchQueue.main.async { [weak bar] in
                guard let bar = bar else { return }
                bar.setNeedsDisplay()
                bar.setNeedsLayout()
                bar.layoutIfNeeded()
              }
            }
          }
          self.isSplit = split; self.rightCountVal = rightCount; self.leftInsetVal = leftInset; self.rightInsetVal = rightInset
          self.scheduleBadgeLayout()
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing layout", details: nil)) }
      case "setSelectedIndex":
        if let args = call.arguments as? [String: Any], let idx = (args["index"] as? NSNumber)?.intValue {
          // Single bar
          if let bar = self.tabBar, let items = bar.items, idx >= 0, idx < items.count {
            bar.selectedItem = items[idx]
            result(nil)
            return
          }
          // Split bars
          if let left = self.tabBarLeft, let leftItems = left.items {
            if idx < leftItems.count, idx >= 0 {
              left.selectedItem = leftItems[idx]
              self.tabBarRight?.selectedItem = nil
              result(nil)
              return
            }
            if let right = self.tabBarRight, let rightItems = right.items {
              let ridx = idx - leftItems.count
              if ridx >= 0, ridx < rightItems.count {
                right.selectedItem = rightItems[ridx]
                self.tabBarLeft?.selectedItem = nil
                result(nil)
                return
              }
            }
          }
          result(FlutterError(code: "bad_args", message: "Index out of range", details: nil))
        } else { result(FlutterError(code: "bad_args", message: "Missing index", details: nil)) }
      case "setStyle":
        if let args = call.arguments as? [String: Any] {
          if let n = args["tint"] as? NSNumber {
            let c = Self.colorFromARGB(n.intValue)
            if let bar = self.tabBar { bar.tintColor = c }
            if let left = self.tabBarLeft { left.tintColor = c }
            if let right = self.tabBarRight { right.tintColor = c }
          }
          if let n = args["backgroundColor"] as? NSNumber {
            let c = Self.colorFromARGB(n.intValue)
            if let bar = self.tabBar { bar.barTintColor = c }
            if let left = self.tabBarLeft { left.barTintColor = c }
            if let right = self.tabBarRight { right.barTintColor = c }
          }
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing style", details: nil)) }
      case "setBrightness":
        if let args = call.arguments as? [String: Any], let isDark = (args["isDark"] as? NSNumber)?.boolValue {
          if #available(iOS 13.0, *) { self.container.overrideUserInterfaceStyle = isDark ? .dark : .light }
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing isDark", details: nil)) }
      case "refresh":
        // Force refresh for label rendering on iOS < 16
        // UITabBar only fully layouts labels when items are selected
        // So we need to temporarily select each item to force layout
        if let bar = self.tabBar, let items = bar.items, !items.isEmpty {
          let originalSelected = bar.selectedItem
          // Temporarily remove delegate to prevent callbacks during refresh
          bar.delegate = nil
          DispatchQueue.main.async { [weak self, weak bar, weak originalSelected] in
            guard let self = self, let bar = bar, let items = bar.items, !items.isEmpty else { return }
            // Cycle through each item to force label layout
            var index = 0
            func selectNext() {
              guard index < items.count else {
                // Restore original selection
                if let original = originalSelected {
                  bar.selectedItem = original
                } else {
                  bar.selectedItem = items.first
                }
                bar.setNeedsLayout()
                bar.layoutIfNeeded()
                // Restore delegate
                bar.delegate = self
                return
              }
              bar.selectedItem = items[index]
              bar.setNeedsLayout()
              bar.layoutIfNeeded()
              index += 1
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                selectNext()
              }
            }
            selectNext()
          }
        } else if let left = self.tabBarLeft, let right = self.tabBarRight {
          let leftOriginal = left.selectedItem
          let rightOriginal = right.selectedItem
          // Temporarily remove delegates to prevent callbacks during refresh
          left.delegate = nil
          right.delegate = nil
          DispatchQueue.main.async { [weak self, weak left, weak right, weak leftOriginal, weak rightOriginal] in
            guard let self = self, let left = left, let right = right,
                  let leftItems = left.items, let rightItems = right.items else { return }
            
            // Process left items
            var leftIndex = 0
            func selectNextLeft() {
              if leftIndex < leftItems.count {
                left.selectedItem = leftItems[leftIndex]
                left.setNeedsLayout()
                left.layoutIfNeeded()
                leftIndex += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                  selectNextLeft()
                }
              } else {
                // Restore original or first item
                if let original = leftOriginal {
                  left.selectedItem = original
                } else {
                  left.selectedItem = leftItems.first
                }
                left.setNeedsLayout()
                left.layoutIfNeeded()
                
                // Process right items
                var rightIndex = 0
                func selectNextRight() {
                  if rightIndex < rightItems.count {
                    right.selectedItem = rightItems[rightIndex]
                    right.setNeedsLayout()
                    right.layoutIfNeeded()
                    rightIndex += 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                      selectNextRight()
                    }
                  } else {
                    // Restore original or first item
                    if let original = rightOriginal {
                      right.selectedItem = original
                    } else {
                      right.selectedItem = rightItems.first
                    }
                    right.setNeedsLayout()
                    right.layoutIfNeeded()
                    // Restore delegates
                    left.delegate = self
                    right.delegate = self
                  }
                }
                selectNextRight()
              }
            }
            selectNextLeft()
          }
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    scheduleBadgeLayout()
  }

  // MARK: - Badge Helpers

  private static func parseUIColorArray(_ raw: Any?) -> [UIColor?] {
    if raw == nil { return [] }
    if let arr = raw as? [Any?] {
      return arr.map { v in
        if v == nil || v is NSNull { return nil }
        if let n = v as? NSNumber { return Self.colorFromARGB(n.intValue) }
        return nil
      }
    }
    if let arr = raw as? [Any] {
      return arr.map { v in
        if v is NSNull { return nil }
        if let n = v as? NSNumber { return Self.colorFromARGB(n.intValue) }
        return nil
      }
    }
    return []
  }

  private func isBlankBadgeText(_ text: String) -> Bool {
    return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  /// Returns the best-guess icon frame for a given slot index.
  private func iconAnchor(forSlot slot: Int, in bar: UITabBar, count: Int) -> CGRect {
    guard count > 0 else { return bar.bounds }
    let barWidth = bar.bounds.width
    let slotWidth = barWidth / CGFloat(count)
    let slotX = slotWidth * CGFloat(slot)
    let slotRect = CGRect(x: slotX, y: 0, width: slotWidth, height: bar.bounds.height)
    func findImageView(_ view: UIView) -> UIImageView? {
      for sub in view.subviews {
        let frame = sub.convert(sub.bounds, to: bar)
        if frame.intersects(slotRect) {
          if let iv = sub as? UIImageView, iv.bounds.width > 5 { return iv }
          if let iv = findImageView(sub) { return iv }
        }
      }
      return nil
    }
    if let iv = findImageView(bar) { return iv.convert(iv.bounds, to: bar) }
    let topY = bar.bounds.height * 0.12
    let iconH = bar.bounds.height * 0.4
    return CGRect(x: slotX, y: topY, width: slotWidth, height: iconH)
  }

  private func applyBadges(to bar: UITabBar, itemOffset: Int) {
    let count = bar.items?.count ?? 0
    guard count > 0 else { return }
    for localIndex in 0..<count {
      let globalIndex = itemOffset + localIndex
      let tag = Self.badgeViewTagBase + globalIndex
      let existing = bar.viewWithTag(tag)
      let shouldShow = globalIndex < currentHasBadgeFlags.count && currentHasBadgeFlags[globalIndex]
      let badgeText = (globalIndex < currentBadges.count) ? currentBadges[globalIndex] : ""
      let hasText = shouldShow && !isBlankBadgeText(badgeText)
      let wantsDotOnly = shouldShow && !hasText

      if !shouldShow {
        existing?.removeFromSuperview()
        continue
      }

      let badgeView = existing ?? UIView(frame: .zero)
      badgeView.tag = tag
      badgeView.isUserInteractionEnabled = false
      badgeView.layer.zPosition = 999
      let rawColor = (globalIndex < currentBadgeColors.count ? currentBadgeColors[globalIndex] : nil)
      badgeView.backgroundColor = rawColor ?? UIColor.systemRed
      badgeView.layer.masksToBounds = true
      badgeView.layer.borderWidth = 0
      bar.clipsToBounds = false
      let anchor = iconAnchor(forSlot: localIndex, in: bar, count: count)

      if wantsDotOnly {
        let size: CGFloat = 10.0
        badgeView.layer.cornerRadius = size / 2
        badgeView.subviews.forEach { $0.removeFromSuperview() }
        if badgeView.superview == nil { bar.addSubview(badgeView) }
        bar.bringSubviewToFront(badgeView)
        badgeView.frame = CGRect(x: anchor.maxX - size / 2, y: anchor.minY - size / 2 + 4, width: size, height: size)
      } else if hasText {
        let label: UILabel = (badgeView.subviews.compactMap { $0 as? UILabel }.first) ?? UILabel(frame: .zero)
        if label.superview == nil { badgeView.addSubview(label) }
        label.text = badgeText
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.textAlignment = .center
        label.sizeToFit()
        let h: CGFloat = 18
        let padX: CGFloat = 6
        let w = max(h, label.bounds.width + padX * 2)
        badgeView.layer.cornerRadius = h / 2
        label.frame = CGRect(x: (w - label.bounds.width) / 2, y: (h - label.bounds.height) / 2, width: label.bounds.width, height: label.bounds.height)
        if badgeView.superview == nil { bar.addSubview(badgeView) }
        bar.bringSubviewToFront(badgeView)
        badgeView.frame = CGRect(x: anchor.maxX - w / 2, y: anchor.minY - h / 2 + 4, width: w, height: h)
      }
    }
  }

  private func scheduleBadgeLayout() {
    let apply = { [weak self] in
      guard let self = self else { return }
      if let bar = self.tabBar {
        bar.layoutIfNeeded()
        self.applyBadges(to: bar, itemOffset: 0)
      }
      if let left = self.tabBarLeft, let right = self.tabBarRight {
        left.layoutIfNeeded(); right.layoutIfNeeded()
        self.applyBadges(to: left, itemOffset: 0)
        self.applyBadges(to: right, itemOffset: left.items?.count ?? 0)
      }
    }
    DispatchQueue.main.async(execute: apply)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: apply)
  }

  func view() -> UIView { container }

  func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    // Single bar case
    if let single = self.tabBar, single === tabBar, let items = single.items, let idx = items.firstIndex(of: item) {
      channel.invokeMethod("valueChanged", arguments: ["index": idx])
      return
    }
    // Split left
    if let left = tabBarLeft, left === tabBar, let items = left.items, let idx = items.firstIndex(of: item) {
      tabBarRight?.selectedItem = nil
      channel.invokeMethod("valueChanged", arguments: ["index": idx])
      return
    }
    // Split right
    if let right = tabBarRight, right === tabBar, let items = right.items, let idx = items.firstIndex(of: item), let left = tabBarLeft, let leftItems = left.items {
      tabBarLeft?.selectedItem = nil
      channel.invokeMethod("valueChanged", arguments: ["index": leftItems.count + idx])
      return
    }
  }


  // Use shared utility functions
  private static func colorFromARGB(_ argb: Int) -> UIColor {
    return ImageUtils.colorFromARGB(argb)
  }

  private static func loadFlutterAsset(_ assetPath: String, size: CGSize? = nil) -> UIImage? {
    return ImageUtils.loadFlutterAsset(assetPath, size: size)
  }

  private static func createImageFromData(_ data: Data, format: String?, scale: CGFloat, size: CGSize? = nil) -> UIImage? {
    return ImageUtils.createImageFromData(data, format: format, size: size, scale: scale)
  }

}

