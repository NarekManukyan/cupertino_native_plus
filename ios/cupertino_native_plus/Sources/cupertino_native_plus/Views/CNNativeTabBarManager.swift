import Flutter
import UIKit

/// Manager for iOS 26+ Native Tab Bar with Search Support
/// This class manages a native UITabBarController at the app level
/// and coordinates with Flutter for content display
class CNNativeTabBarManager: NSObject {

    static let shared = CNNativeTabBarManager()

    private var tabBarController: UITabBarController?
    private var flutterViewController: FlutterViewController?
    private var searchController: UISearchController?
    private var methodChannel: FlutterMethodChannel?

    private var tabConfigurations: [TabConfig] = []
    private var searchTabIndex: Int = -1
    private var isEnabled: Bool = false
    private var tintColor: UIColor?
    private var unselectedTintColor: UIColor?
    private var shrinkWhileScroll: Bool = false
    private var shrinkOffset: CGFloat = 16
    private var lastScrollOffset: CGFloat = 0
    private var isTabBarShrunk: Bool = false
    private var isRTL: Bool = false
    /// Raw string from Flutter, mapped to `UITabBarController.MinimizeBehavior`
    /// when applied: "never" | "onScrollDown" | "onScrollUp" | "automatic".
    private var minimizeBehaviorRaw: String = "automatic"

    struct TabConfig {
        let title: String
        let sfSymbol: String?
        let activeSfSymbol: String?
        /// Custom icon sources, checked in this order: xcasset > raw bytes > Flutter asset path.
        /// Any of these takes precedence over `sfSymbol`/`activeSfSymbol` when present.
        let xcassetName: String?
        let activeXcassetName: String?
        let imageData: Data?
        let activeImageData: Data?
        let imageAssetPath: String?
        let activeImageAssetPath: String?
        let imageFormat: String?
        let activeImageFormat: String?
        let isSearchTab: Bool
        let badgeCount: Int?
    }

    private override init() {
        super.init()
    }

    /// Setup native tab bar with Flutter
    func setup(messenger: FlutterBinaryMessenger) {
        // Only setup on iOS 26+
        guard #available(iOS 26.0, *) else {
            NSLog("⚠️ CNNativeTabBarManager: Requires iOS 26+")
            return
        }

        self.methodChannel = FlutterMethodChannel(
            name: "cn_native_tab_bar",
            binaryMessenger: messenger
        )

        methodChannel?.setMethodCallHandler { [weak self] call, result in
            self?.handleMethodCall(call, result: result)
        }
    }

    /// Find Flutter view controller
    private func getFlutterViewController() -> FlutterViewController? {
        if let flutterVC = flutterViewController {
            return flutterVC
        }

        // Try to find it from windows
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first(where: { $0.isKeyWindow })
        {
            if let flutterVC = window.rootViewController as? FlutterViewController {
                self.flutterViewController = flutterVC
                return flutterVC
            }
        }

        return nil
    }

    private var searchOnlyNavController: UINavigationController?

    /// Enable native tab bar mode
    private func enableNativeTabBar(
        tabs: [TabConfig], selectedIndex: Int, isDark: Bool, shrinkWhileScroll: Bool = false,
        badgeCounts: [Int?]? = nil
    ) {
        self.shrinkWhileScroll = shrinkWhileScroll
        self.lastScrollOffset = 0
        self.isTabBarShrunk = false
        guard let flutterVC = getFlutterViewController() else {
            NSLog("❌ CNNativeTabBarManager: Could not find FlutterViewController")
            return
        }

        // Store configuration
        self.tabConfigurations = tabs
        self.searchTabIndex = tabs.firstIndex(where: { $0.isSearchTab }) ?? -1

        // Check if this is search-only mode (single search tab)
        let isSearchOnlyMode = tabs.count == 1 && tabs[0].isSearchTab

        if isSearchOnlyMode {
            // Search-only mode: Use UINavigationController with UISearchController directly
            enableSearchOnlyMode(flutterVC: flutterVC, config: tabs[0], isDark: isDark)
            return
        }

        // Create tab bar controller if needed
        if tabBarController == nil {
            let tabBar = UITabBarController()
            tabBarController = tabBar

            // Setup iOS 26 appearance
            setupTabBarAppearance(tabBar)
        }

        guard let tabBar = tabBarController else { return }

        // Apply dark mode
        tabBar.overrideUserInterfaceStyle = isDark ? .dark : .light

        // Create view controllers for each tab
        var viewControllers: [UIViewController] = []

        for (index, config) in tabs.enumerated() {
            if config.isSearchTab {
                // Create search tab with Flutter content embedded
                let searchVC = FlutterTabViewController()
                searchVC.tabIndex = index
                searchVC.isSearchTab = true
                searchVC.methodChannel = self.methodChannel

                let navController = UINavigationController(rootViewController: searchVC)
                navController.navigationBar.prefersLargeTitles = true

                // Setup search controller
                let search = UISearchController(searchResultsController: nil)
                search.searchResultsUpdater = self
                search.searchBar.delegate = self
                search.obscuresBackgroundDuringPresentation = false
                search.searchBar.placeholder = config.title.isEmpty ? "Search" : config.title
                search.hidesNavigationBarDuringPresentation = false

                searchVC.navigationItem.searchController = search
                searchVC.navigationItem.hidesSearchBarWhenScrolling = false
                searchVC.definesPresentationContext = true
                searchVC.title = "Search"

                self.searchController = search

                // Setup tab bar item with search system item
                navController.tabBarItem = UITabBarItem(tabBarSystemItem: .search, tag: index)
                if !config.title.isEmpty {
                    navController.tabBarItem.title = config.title
                }

                viewControllers.append(navController)
            } else {
                // Regular tab - use Flutter view
                let tabVC = FlutterTabViewController()
                tabVC.tabIndex = index
                tabVC.methodChannel = self.methodChannel

                // Setup tab bar item
                let (image, selectedImage) = icons(for: config)

                tabVC.tabBarItem = UITabBarItem(
                    title: config.title,
                    image: image,
                    selectedImage: selectedImage
                )
                tabVC.tabBarItem.tag = index

                // Set badge value if provided
                if let count = config.badgeCount, count > 0 {
                    tabVC.tabBarItem.badgeValue = count > 99 ? "99+" : String(count)
                }

                viewControllers.append(tabVC)
            }
        }

        // Top-level badgeCounts takes precedence over per-tab CNTab.badgeCount.
        if let counts = badgeCounts {
            for (index, vc) in viewControllers.enumerated() where index < counts.count {
                let count = counts[index]
                if let count = count, count > 0 {
                    vc.tabBarItem.badgeValue = count > 99 ? "99+" : String(count)
                } else {
                    vc.tabBarItem.badgeValue = nil
                }
            }
        }

        tabBar.viewControllers = viewControllers
        applyLayoutDirection(to: tabBar)

        // Apply tint colors
        if let tint = tintColor {
            tabBar.tabBar.tintColor = tint
        }
        if let unselTint = unselectedTintColor {
            tabBar.tabBar.unselectedItemTintColor = unselTint
        }

        // Replace root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first(where: { $0.isKeyWindow })
        {
            // Snapshot Flutter's last rendered frame before we move it
            let snapshot = flutterVC.view.snapshotView(afterScreenUpdates: false)

            // Set root FIRST so the view hierarchy has proper bounds before embedding Flutter.
            // selectedIndex and delegate must be set after entering the window — UITabBarController
            // can silently reset selectedIndex to 0 if set before the controller is in a window.
            window.rootViewController = tabBar
            tabBar.selectedIndex = selectedIndex
            tabBar.delegate = self
            tabBar.view.setNeedsLayout()
            tabBar.view.layoutIfNeeded()

            // Embed Flutter now that layout bounds are resolved
            let selectedVC = viewControllers[selectedIndex]
            if let navController = selectedVC as? UINavigationController,
                let rootVC = navController.topViewController as? FlutterTabViewController
            {
                rootVC.embedFlutter(flutterVC)
            } else if let flutterTabVC = selectedVC as? FlutterTabViewController {
                flutterTabVC.embedFlutter(flutterVC)
            }

            // UITabBarController does not invoke the delegate's didSelect on the
            // initial programmatic selection, so Flutter never learns which tab
            // is active and any state gated on onTabSelected (segment switch,
            // routing, etc.) stays frozen until the user taps. Fire it manually.
            methodChannel?.invokeMethod(
                "onTabSelected", arguments: ["index": selectedIndex])

            // Overlay snapshot to cover the brief gap before Flutter renders its first frame
            if let snapshot = snapshot {
                snapshot.frame = window.bounds
                snapshot.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                window.addSubview(snapshot)
                UIView.animate(withDuration: 0.3, delay: 0.25, options: .curveEaseInOut) {
                    snapshot.alpha = 0
                } completion: { _ in
                    snapshot.removeFromSuperview()
                }
            }

            self.isEnabled = true
            NSLog("✅ CNNativeTabBarManager: Native tab bar enabled")
        }
    }

    private var ignoreInitialSearchUpdate = true

    /// Enable search-only mode (single search tab, no tab bar)
    private func enableSearchOnlyMode(
        flutterVC: FlutterViewController, config: TabConfig, isDark: Bool
    ) {
        // Reset flag
        ignoreInitialSearchUpdate = true

        // Create Flutter container view controller
        let searchVC = FlutterTabViewController()
        searchVC.tabIndex = 0
        searchVC.isSearchTab = true
        searchVC.methodChannel = self.methodChannel

        // Create navigation controller
        let navController = UINavigationController(rootViewController: searchVC)
        navController.navigationBar.prefersLargeTitles = true
        navController.overrideUserInterfaceStyle = isDark ? .dark : .light
        navController.view.semanticContentAttribute = layoutDirection
        navController.navigationBar.semanticContentAttribute = layoutDirection

        // Setup search controller - NOT active by default
        let search = UISearchController(searchResultsController: nil)
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = config.title.isEmpty ? "Search" : config.title
        search.hidesNavigationBarDuringPresentation = false
        // Don't show separate results controller - show results in same view
        search.showsSearchResultsController = false

        // Set delegates
        search.searchResultsUpdater = self
        search.searchBar.delegate = self

        searchVC.navigationItem.searchController = search
        searchVC.navigationItem.hidesSearchBarWhenScrolling = false
        searchVC.definesPresentationContext = true
        searchVC.title = config.title.isEmpty ? "Search" : config.title

        self.searchController = search
        self.searchOnlyNavController = navController

        // Embed Flutter view FIRST
        searchVC.embedFlutter(flutterVC)

        // Replace root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first(where: { $0.isKeyWindow })
        {
            window.rootViewController = navController
            window.makeKeyAndVisible()

            // Deactivate search after a short delay to ensure UI is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                search.isActive = false
                self.ignoreInitialSearchUpdate = false
            }

            self.isEnabled = true
            NSLog("✅ CNNativeTabBarManager: Search-only mode enabled")
        }
    }

    /// Disable native tab bar and return to Flutter-only mode
    private func disableNativeTabBar() {
        guard let flutterVC = flutterViewController else {
            return
        }

        // Fully detach FlutterViewController from whichever FlutterTabViewController
        // is currently hosting it. removeFlutterView() only removes the view; without
        // the full VC-containment teardown UIKit throws the "wrong parent" assertion
        // when flutterVC is later set as the window's rootViewController.
        func detach(from vc: UIViewController) {
            if let tabVC = vc as? FlutterTabViewController {
                tabVC.removeFlutter(flutterVC)
            } else if let nav = vc as? UINavigationController,
                let tabVC = nav.topViewController as? FlutterTabViewController
            {
                tabVC.removeFlutter(flutterVC)
            }
        }

        if let navController = searchOnlyNavController {
            detach(from: navController)
        }

        if let tabBar = tabBarController {
            for vc in tabBar.viewControllers ?? [] {
                detach(from: vc)
            }
        }

        // Restore Flutter as root
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first(where: { $0.isKeyWindow })
        {
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
                window.rootViewController = flutterVC
            }
        }

        self.searchOnlyNavController = nil

        self.isEnabled = false
        self.tabBarController = nil
        self.shrinkWhileScroll = false
        self.isTabBarShrunk = false
        NSLog("✅ CNNativeTabBarManager: Native tab bar disabled")
    }

    /// Mirrors layout (tab order, nav bar chevrons, etc.) to match the
    /// Flutter app's text direction. `.unspecified` is intentionally not
    /// used here — this always reflects an explicit choice from Flutter
    /// rather than inheriting UIKit's own locale-based default.
    private var layoutDirection: UISemanticContentAttribute {
        isRTL ? .forceRightToLeft : .forceLeftToRight
    }

    /// Applies `layoutDirection` to a tab bar controller and its tab bar.
    private func applyLayoutDirection(to tabBar: UITabBarController) {
        let direction = layoutDirection
        tabBar.view.semanticContentAttribute = direction
        tabBar.tabBar.semanticContentAttribute = direction
        for viewController in tabBar.viewControllers ?? [] {
            viewController.view.semanticContentAttribute = direction
            if let nav = viewController as? UINavigationController {
                nav.navigationBar.semanticContentAttribute = direction
            }
        }
    }

    private func setupTabBarAppearance(_ tabBar: UITabBarController) {
        // iOS 26 - use direct properties for liquid glass effect
        tabBar.tabBar.isTranslucent = true
        tabBar.tabBar.backgroundImage = UIImage()
        tabBar.tabBar.shadowImage = UIImage()
        tabBar.tabBar.backgroundColor = .clear

        // Leading/trailing inset from the window edges. `UITabBarAppearance`
        // has no horizontal-margin property — `UIBarAppearance` only exposes
        // colors/images/effects — so this is the documented knob: it gives
        // the tab bar's content area a constant gutter from the screen edges.
        tabBar.tabBar.insetsLayoutMarginsFromSafeArea = true
        tabBar.tabBar.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 0, leading: 24, bottom: 0, trailing: 24)

        // iOS 26 native tab-bar minimize behavior — Apple's first-party
        // collapse-on-scroll handling. Equivalent to SwiftUI's
        // `TabView.tabBarMinimizeBehavior(_:)`.
        applyMinimizeBehavior(to: tabBar)
    }

    /// Maps the raw string from Flutter to `UITabBarController.MinimizeBehavior`
    /// and applies it. iOS 26+ only; no-op on older systems.
    private func applyMinimizeBehavior(to tabBar: UITabBarController) {
        if #available(iOS 26.0, *) {
            let behavior: UITabBarController.MinimizeBehavior
            switch minimizeBehaviorRaw {
            case "never": behavior = .never
            case "onScrollUp": behavior = .onScrollUp
            case "onScrollDown": behavior = .onScrollDown
            case "automatic": behavior = .automatic
            default: behavior = .automatic
            }
            tabBar.tabBarMinimizeBehavior = behavior
        }
    }

    /// Composes a glyph (custom image or SF Symbol) inside a tinted circle and
    /// returns the result as a tab bar item image. Used to give icons a
    /// compact, circular silhouette when the bar is shrunk.
    private func circularizedIcon(
        image customImage: UIImage? = nil,
        symbolName: String? = nil,
        tint: UIColor,
        background: UIColor,
        diameter: CGFloat = 30
    ) -> UIImage? {
        let size = CGSize(width: diameter, height: diameter)
        let maxGlyphSize = diameter * 0.55

        var glyph: UIImage?
        if let customImage = customImage {
            glyph = customImage.withTintColor(tint, renderingMode: .alwaysOriginal)
        } else if let symbolName = symbolName {
            let symbolConfig = UIImage.SymbolConfiguration(
                pointSize: maxGlyphSize, weight: .semibold)
            glyph = UIImage(systemName: symbolName, withConfiguration: symbolConfig)?
                .withTintColor(tint, renderingMode: .alwaysOriginal)
        }

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            background.setFill()
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()

            guard let glyph = glyph else { return }
            let scale = min(
                1, maxGlyphSize / max(glyph.size.width, 1),
                maxGlyphSize / max(glyph.size.height, 1))
            let glyphSize = CGSize(
                width: glyph.size.width * scale, height: glyph.size.height * scale)
            let origin = CGPoint(
                x: (size.width - glyphSize.width) / 2,
                y: (size.height - glyphSize.height) / 2
            )
            glyph.draw(in: CGRect(origin: origin, size: glyphSize))
        }
        return image.withRenderingMode(.alwaysOriginal)
    }

    /// Resolves a single tab bar icon image, preferring a custom source
    /// (xcasset > raw bytes > Flutter asset path) over the SF Symbol
    /// fallback. Pass a non-nil `tint` for `.alwaysOriginal` tinting, or `nil`
    /// for `.alwaysTemplate` (system-tinted) rendering.
    private func resolveIcon(
        xcassetName: String?, imageData: Data?, imageAssetPath: String?, imageFormat: String?,
        symbol: String?, tint: UIColor?, size: CGFloat = 24
    ) -> UIImage? {
        var raw: UIImage?
        if let name = xcassetName, !name.isEmpty {
            raw = UIImage(named: name, in: Bundle.main, compatibleWith: nil)
        } else if let data = imageData {
            raw = ImageUtils.createImageFromData(
                data, format: imageFormat, size: CGSize(width: size, height: size))
        } else if let path = imageAssetPath, !path.isEmpty {
            raw = ImageUtils.loadFlutterAsset(
                path, size: CGSize(width: size, height: size), format: imageFormat)
        }

        if let raw = raw {
            if let tint = tint {
                return raw.withTintColor(tint, renderingMode: .alwaysOriginal)
            }
            return raw.withRenderingMode(.alwaysTemplate)
        }

        guard let symbol = symbol, !symbol.isEmpty else { return nil }
        if let tint = tint {
            return UIImage(systemName: symbol)?.withTintColor(tint, renderingMode: .alwaysOriginal)
        }
        return UIImage(systemName: symbol)?.withRenderingMode(.alwaysTemplate)
    }

    /// Builds the unselected/selected tab bar images for a config. The
    /// selected image falls back to the unselected image when no active-state
    /// icon is configured, mirroring the original SF-Symbol-only behavior.
    private func icons(for config: TabConfig) -> (UIImage?, UIImage?) {
        let image = resolveIcon(
            xcassetName: config.xcassetName, imageData: config.imageData,
            imageAssetPath: config.imageAssetPath, imageFormat: config.imageFormat,
            symbol: config.sfSymbol, tint: unselectedTintColor)

        let hasActiveIcon =
            !(config.activeXcassetName ?? "").isEmpty || config.activeImageData != nil
            || !(config.activeImageAssetPath ?? "").isEmpty
            || !(config.activeSfSymbol ?? "").isEmpty
        guard hasActiveIcon else { return (image, image) }

        let selectedImage = resolveIcon(
            xcassetName: config.activeXcassetName, imageData: config.activeImageData,
            imageAssetPath: config.activeImageAssetPath, imageFormat: config.activeImageFormat,
            symbol: config.activeSfSymbol, tint: nil)
        return (image, selectedImage)
    }

    private func showTabBarAnimated() {
        guard let tabBar = tabBarController, isTabBarShrunk else { return }
        isTabBarShrunk = false
        lastScrollOffset = 0
        applyShrinkState(false, on: tabBar, duration: 0.3)
    }

    private func handleScrollOffset(_ offset: CGFloat) {
        guard let tabBar = tabBarController else { return }
        // `"never"` mirrors UITabBarController.MinimizeBehavior.never — no shrink at all.
        guard minimizeBehaviorRaw != "never" else {
            if isTabBarShrunk {
                isTabBarShrunk = false
                applyShrinkState(false, on: tabBar)
            }
            return
        }

        if offset <= 0 {
            if isTabBarShrunk {
                isTabBarShrunk = false
                applyShrinkState(false, on: tabBar)
            }
            lastScrollOffset = offset
            return
        }

        let delta = offset - lastScrollOffset
        guard abs(delta) > 4 else { return }
        lastScrollOffset = offset

        // Map the behavior to the scroll direction that should *shrink* the bar.
        // `automatic` defaults to `onScrollDown`, which matches the SwiftUI
        // `TabView.tabBarMinimizeBehavior` default Apple ships for iOS 26.
        let shrinkOnScrollDown: Bool
        switch minimizeBehaviorRaw {
        case "onScrollUp": shrinkOnScrollDown = false
        case "onScrollDown", "automatic": shrinkOnScrollDown = true
        default: shrinkOnScrollDown = true
        }

        let isScrollingDown = delta > 0
        let shouldShrink = isScrollingDown == shrinkOnScrollDown

        if shouldShrink && !isTabBarShrunk {
            isTabBarShrunk = true
            applyShrinkState(true, on: tabBar)
        } else if !shouldShrink && isTabBarShrunk {
            isTabBarShrunk = false
            applyShrinkState(false, on: tabBar)
        }
    }

    /// Toggles the shrunken state of the whole tab bar, scaling the entire bar
    /// (including its glass background) and hiding the per-item labels so the
    /// compact bar reads as a pill of icons. Labels are restored from
    /// `tabConfigurations` when expanding.
    private func applyShrinkState(
        _ shrunk: Bool, on tabBar: UITabBarController, duration: TimeInterval = 0.25
    ) {
        // Anchor scaling to the bottom-center so the bar shrinks "into" the
        // home-indicator area rather than drifting up from the screen edge.
        // position must be in the parent layer's coordinate space — use frame, not bounds.
        tabBar.tabBar.layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        tabBar.tabBar.layer.position = CGPoint(
            x: tabBar.tabBar.frame.midX,
            y: tabBar.tabBar.frame.maxY
        )

        if let items = tabBar.tabBar.items {
            for (index, item) in items.enumerated() {
                guard index < tabConfigurations.count else { continue }
                let config = tabConfigurations[index]
                if shrunk {
                    // Drop the label and swap to a circular icon for a compact pill look.
                    item.title = nil
                    let tint = tintColor ?? .label
                    let background = (tintColor ?? UIColor.systemBlue).withAlphaComponent(0.18)
                    let customImage = resolveIcon(
                        xcassetName: config.xcassetName, imageData: config.imageData,
                        imageAssetPath: config.imageAssetPath, imageFormat: config.imageFormat,
                        symbol: nil, tint: nil)
                    if let customImage = customImage {
                        let circular = circularizedIcon(
                            image: customImage, tint: tint, background: background)
                        item.image = circular
                        item.selectedImage = circular
                    } else if let symbol = config.sfSymbol, !symbol.isEmpty {
                        let circular = circularizedIcon(
                            symbolName: symbol, tint: tint, background: background)
                        item.image = circular
                        item.selectedImage = circular
                    }
                } else {
                    item.title = config.title
                    let (image, selectedImage) = icons(for: config)
                    item.image = image
                    item.selectedImage = selectedImage
                }
            }
        }

        // Swap the bar's appearance and per-item layout *without* UIKit's
        // implicit springy transition — wrapping the property changes in a
        // CATransaction with actions disabled suppresses the bounce iOS 26
        // adds when these properties change on a visible UITabBar.
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let appearance = UITabBarAppearance()
        if shrunk {
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
            appearance.shadowColor = .clear
        } else {
            appearance.configureWithDefaultBackground()
        }
        tabBar.tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.tabBar.scrollEdgeAppearance = appearance
        }

        if shrunk {
            tabBar.tabBar.itemPositioning = .centered
            tabBar.tabBar.itemWidth = 44
            tabBar.tabBar.itemSpacing = 24
        } else {
            tabBar.tabBar.itemPositioning = .automatic
            tabBar.tabBar.itemWidth = 0
            tabBar.tabBar.itemSpacing = 0
        }

        CATransaction.commit()

        // Smooth, non-bouncing transform: explicit ease-in-out, no spring.
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction]
        ) {
            if shrunk {
                let sideMargin: CGFloat = self.shrinkOffset
                let bottomInset: CGFloat = self.shrinkOffset / 3
                let barWidth = max(tabBar.tabBar.bounds.width, 1)
                let scale = max(0.5, (barWidth - 2 * sideMargin) / barWidth)
                tabBar.tabBar.transform = CGAffineTransform(translationX: 0, y: -bottomInset)
                    .scaledBy(x: scale, y: scale)
            } else {
                tabBar.tabBar.transform = .identity
            }
        }
    }

    private func notifyTabSelected(_ index: Int) {
        showTabBarAnimated()
        methodChannel?.invokeMethod("onTabSelected", arguments: ["index": index])

        guard let flutterVC = flutterViewController,
            let tabBar = tabBarController
        else { return }

        // Get the selected view controller - handle navigation controller wrapping for search tab
        var targetVC: FlutterTabViewController?
        if let navController = tabBar.selectedViewController as? UINavigationController,
            let rootVC = navController.topViewController as? FlutterTabViewController
        {
            targetVC = rootVC
        } else if let flutterTabVC = tabBar.selectedViewController as? FlutterTabViewController {
            targetVC = flutterTabVC
        }

        if let vc = targetVC {
            vc.embedFlutter(flutterVC)
        }
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "enable":
            guard let args = call.arguments as? [String: Any],
                let tabsData = args["tabs"] as? [[String: Any]]
            else {
                result(
                    FlutterError(code: "invalid_args", message: "Invalid tabs data", details: nil))
                return
            }

            let tabs = tabsData.compactMap { data -> TabConfig? in
                guard let title = data["title"] as? String else { return nil }
                let symbol = data["sfSymbol"] as? String
                let activeSymbol = data["activeSfSymbol"] as? String
                let xcassetName = data["xcassetName"] as? String
                let activeXcassetName = data["activeXcassetName"] as? String
                let imageData = (data["imageData"] as? FlutterStandardTypedData)?.data
                let activeImageData = (data["activeImageData"] as? FlutterStandardTypedData)?.data
                let imageAssetPath = data["imageAssetPath"] as? String
                let activeImageAssetPath = data["activeImageAssetPath"] as? String
                let imageFormat = data["imageFormat"] as? String
                let activeImageFormat = data["activeImageFormat"] as? String
                let isSearch = (data["isSearch"] as? Bool) ?? false
                let badgeCount = data["badgeCount"] as? Int
                return TabConfig(
                    title: title, sfSymbol: symbol, activeSfSymbol: activeSymbol,
                    xcassetName: xcassetName, activeXcassetName: activeXcassetName,
                    imageData: imageData, activeImageData: activeImageData,
                    imageAssetPath: imageAssetPath, activeImageAssetPath: activeImageAssetPath,
                    imageFormat: imageFormat, activeImageFormat: activeImageFormat,
                    isSearchTab: isSearch, badgeCount: badgeCount)
            }

            let selectedIndex = (args["selectedIndex"] as? Int) ?? 0
            let isDark = (args["isDark"] as? Bool) ?? false
            let shrink = (args["shrinkWhileScroll"] as? Bool) ?? false
            self.shrinkOffset = CGFloat((args["shrinkOffset"] as? Double) ?? 16)
            self.minimizeBehaviorRaw = (args["minimizeBehavior"] as? String) ?? "automatic"
            self.isRTL = (args["isRTL"] as? Bool) ?? false

            // Parse colors
            if let tint = args["tint"] as? Int {
                tintColor = ImageUtils.colorFromARGB(tint)
            }
            if let unselTint = args["unselectedTint"] as? Int {
                unselectedTintColor = ImageUtils.colorFromARGB(unselTint)
            }

            let topBadgeCounts = args["badgeCounts"] as? [Int?]
            enableNativeTabBar(
                tabs: tabs, selectedIndex: selectedIndex, isDark: isDark, shrinkWhileScroll: shrink,
                badgeCounts: topBadgeCounts)
            result(nil)

        case "disable":
            disableNativeTabBar()
            result(nil)

        case "setSelectedIndex":
            guard let args = call.arguments as? [String: Any],
                let index = args["index"] as? Int
            else {
                result(FlutterError(code: "invalid_args", message: "Invalid index", details: nil))
                return
            }
            tabBarController?.selectedIndex = index
            notifyTabSelected(index)
            result(nil)

        case "activateSearch":
            if searchTabIndex >= 0 {
                tabBarController?.selectedIndex = searchTabIndex
                searchController?.isActive = true
            }
            result(nil)

        case "deactivateSearch":
            searchController?.isActive = false
            result(nil)

        case "setSearchText":
            if let args = call.arguments as? [String: Any],
                let text = args["text"] as? String
            {
                searchController?.searchBar.text = text
            }
            result(nil)

        case "isEnabled":
            result(isEnabled)

        case "setMinimizeBehavior":
            if let args = call.arguments as? [String: Any],
                let raw = args["minimizeBehavior"] as? String
            {
                self.minimizeBehaviorRaw = raw
                if let tabBar = tabBarController {
                    applyMinimizeBehavior(to: tabBar)
                }
            }
            result(nil)

        case "setBadgeCounts":
            guard let args = call.arguments as? [String: Any],
                let badgeCounts = args["badgeCounts"] as? [Int?]
            else {
                result(
                    FlutterError(
                        code: "invalid_args", message: "Invalid badge counts", details: nil))
                return
            }

            if let tabBar = tabBarController, let viewControllers = tabBar.viewControllers {
                for (index, viewController) in viewControllers.enumerated() {
                    if index < badgeCounts.count {
                        let count = badgeCounts[index]
                        if let count = count, count > 0 {
                            viewController.tabBarItem.badgeValue =
                                count > 99 ? "99+" : String(count)
                        } else {
                            viewController.tabBarItem.badgeValue = nil
                        }
                    } else {
                        viewController.tabBarItem.badgeValue = nil
                    }
                }
            }
            result(nil)

        case "setStyle":
            if let args = call.arguments as? [String: Any] {
                if let tint = args["tint"] as? Int {
                    let color = ImageUtils.colorFromARGB(tint)
                    tabBarController?.tabBar.tintColor = color
                    tintColor = color
                }
                if let unselTint = args["unselectedTint"] as? Int {
                    let color = ImageUtils.colorFromARGB(unselTint)
                    tabBarController?.tabBar.unselectedItemTintColor = color
                    unselectedTintColor = color
                }
            }
            result(nil)

        case "setBrightness":
            if let args = call.arguments as? [String: Any],
                let isDark = args["isDark"] as? Bool
            {
                tabBarController?.overrideUserInterfaceStyle = isDark ? .dark : .light
            }
            result(nil)

        case "setTextDirection":
            if let args = call.arguments as? [String: Any],
                let rtl = args["isRTL"] as? Bool
            {
                self.isRTL = rtl
                if let tabBar = tabBarController {
                    applyLayoutDirection(to: tabBar)
                }
                if let navController = searchOnlyNavController {
                    navController.view.semanticContentAttribute = layoutDirection
                    navController.navigationBar.semanticContentAttribute = layoutDirection
                }
            }
            result(nil)

        case "updateScrollOffset":
            // Drive the manual shrink workaround whenever Flutter reports scroll.
            // The minimize behavior is consulted inside `handleScrollOffset` —
            // `"never"` is a no-op, the rest pick the direction that shrinks.
            if let args = call.arguments as? [String: Any],
                let offset = args["offset"] as? Double,
                shrinkWhileScroll || minimizeBehaviorRaw != "never"
            {
                handleScrollOffset(CGFloat(offset))
            }
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

// MARK: - UITabBarControllerDelegate

extension CNNativeTabBarManager: UITabBarControllerDelegate {
    /// Re-parents the shared Flutter view into the *destination* tab before
    /// UIKit's own selection transition begins. `shouldSelect` fires ahead of
    /// any animation/highlight change, so the target already has Flutter
    /// content by the time the transition renders — no gap where the empty
    /// (clear-background) placeholder view is visible.
    ///
    /// Embedding used to happen in `didSelect`, deferred a runloop tick via
    /// `DispatchQueue.main.async` because doing it synchronously there raced
    /// UIKit's transition and made the bar need a second tap. That race is
    /// what caused a flash of the empty tab before Flutter snapped back in;
    /// doing the re-parent earlier (pre-transition) avoids both problems.
    func tabBarController(
        _ tabBarController: UITabBarController, shouldSelect viewController: UIViewController
    ) -> Bool {
        guard let flutterVC = flutterViewController else { return true }
        var target: FlutterTabViewController?
        if let nav = viewController as? UINavigationController,
            let root = nav.topViewController as? FlutterTabViewController
        {
            target = root
        } else if let vc = viewController as? FlutterTabViewController {
            target = vc
        }
        target?.embedFlutter(flutterVC)
        return true
    }

    func tabBarController(
        _ tabBarController: UITabBarController, didSelect viewController: UIViewController
    ) {
        let index = tabBarController.selectedIndex
        showTabBarAnimated()
        methodChannel?.invokeMethod("onTabSelected", arguments: ["index": index])
    }
}

// MARK: - UISearchResultsUpdating

extension CNNativeTabBarManager: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        // Ignore initial auto-triggered updates
        if ignoreInitialSearchUpdate { return }

        guard let query = searchController.searchBar.text else { return }
        methodChannel?.invokeMethod("onSearchChanged", arguments: ["query": query])
    }
}

// MARK: - UISearchBarDelegate

extension CNNativeTabBarManager: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text else { return }
        methodChannel?.invokeMethod("onSearchSubmitted", arguments: ["query": query])
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        methodChannel?.invokeMethod("onSearchCancelled", arguments: nil)
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        methodChannel?.invokeMethod("onSearchActiveChanged", arguments: ["isActive": true])
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        methodChannel?.invokeMethod("onSearchActiveChanged", arguments: ["isActive": false])
    }
}

// MARK: - Tab View Controllers

private class FlutterTabViewController: UIViewController {
    var tabIndex: Int = 0
    var isSearchTab: Bool = false
    weak var methodChannel: FlutterMethodChannel?
    private var embeddedFlutterView: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        methodChannel?.invokeMethod("onTabAppeared", arguments: ["index": tabIndex])
    }

    func embedFlutterView(_ flutterView: UIView) {

        // Remove any existing embedded view
        embeddedFlutterView?.removeFromSuperview()

        // Remove from previous parent
        flutterView.removeFromSuperview()

        // Ensure Flutter view is visible
        flutterView.isHidden = false
        flutterView.alpha = 1.0
        flutterView.translatesAutoresizingMaskIntoConstraints = false

        // Add to this view controller
        view.addSubview(flutterView)
        view.bringSubviewToFront(flutterView)

        // Fill entire view - Flutter handles its own safe area
        NSLayoutConstraint.activate([
            flutterView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            flutterView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            flutterView.topAnchor.constraint(equalTo: view.topAnchor),
            flutterView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        embeddedFlutterView = flutterView
        // Force layout update
        view.setNeedsLayout()
        view.layoutIfNeeded()

        NSLog("✅ FlutterTabViewController: Embedded Flutter view, frame: \(flutterView.frame)")
    }

    /// Embeds a `FlutterViewController` as a child view controller, not just its
    /// view. UIKit only delivers `viewWillAppear`/`viewDidAppear` to controllers
    /// in the hierarchy, and the Flutter engine resumes its render loop in
    /// response to those callbacks. Moving only the view leaves the controller
    /// orphaned, which is why the engine sticks on its last frame (the splash)
    /// until something else forces a re-layout (e.g. a tab tap).
    func embedFlutter(_ flutterVC: FlutterViewController) {
        // Detach from any previous parent, bracketing with appearance
        // callbacks so the engine sees a clean disappear before re-attach.
        if let oldParent = flutterVC.parent, oldParent !== self {
            flutterVC.willMove(toParent: nil)
            flutterVC.beginAppearanceTransition(false, animated: false)
            flutterVC.view.removeFromSuperview()
            flutterVC.endAppearanceTransition()
            flutterVC.removeFromParent()
        }

        if flutterVC.parent !== self {
            addChild(flutterVC)
            // Manually trigger the appearance transition. Auto-forwarding only
            // happens during the parent's own appearance cycle; when we add a
            // child after the parent is already on-screen, viewWillAppear and
            // viewDidAppear are never delivered, and the Flutter engine waits
            // for them before resuming rendering.
            flutterVC.beginAppearanceTransition(true, animated: false)
            embedFlutterView(flutterVC.view)
            flutterVC.endAppearanceTransition()
            flutterVC.didMove(toParent: self)
        } else {
            embedFlutterView(flutterVC.view)
        }
    }

    func removeFlutterView() {
        embeddedFlutterView?.removeFromSuperview()
        embeddedFlutterView = nil
    }

    /// Fully detaches a `FlutterViewController` from this parent, including
    /// the view-controller containment hierarchy. Call this before making
    /// `FlutterViewController` the window root; without it UIKit throws
    /// "child VC should have parent (null) but actual parent is FlutterTabViewController".
    func removeFlutter(_ flutterVC: FlutterViewController) {
        guard flutterVC.parent === self else {
            removeFlutterView()
            return
        }
        flutterVC.willMove(toParent: nil)
        flutterVC.beginAppearanceTransition(false, animated: false)
        flutterVC.view.removeFromSuperview()
        flutterVC.endAppearanceTransition()
        flutterVC.removeFromParent()
        embeddedFlutterView = nil
    }
}

private class SearchTabViewController: UIViewController {
    var tabIndex: Int = 0
    weak var methodChannel: FlutterMethodChannel?
    var searchPlaceholderText: String = "Search results will appear here"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        // Add placeholder content for search results area
        let label = UILabel()
        label.text = searchPlaceholderText
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 17)
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        methodChannel?.invokeMethod("onTabAppeared", arguments: ["index": tabIndex])
    }
}
