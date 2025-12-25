import UIKit
import CoreMotion
import Combine

/// Manages gyroscope-based spotlight effects using CoreMotion
@available(iOS 13.0, *)
final class SpotlightManager: ObservableObject {

    // MARK: - Singleton
    static let shared = SpotlightManager()

    // MARK: - Published Properties
    @Published var spotlightOffset: CGPoint = .zero
    @Published var isGyroscopeActive: Bool = false

    // MARK: - Private Properties
    private let motionManager = CMMotionManager()
    private var activeViewIds: Set<Int64> = []
    private let lock = NSLock()

    // Sensitivity multiplier for tilt-to-offset conversion
    private var sensitivity: CGFloat = 50.0

    // Smoothing factor for low-pass filter (0.0 - 1.0)
    private var smoothing: CGFloat = 0.3

    // MARK: - Initialization
    private init() {
        setupMotionManager()
    }

    // MARK: - Public API

    /// Registers a view to receive gyroscope updates
    /// - Parameter viewId: Unique identifier for the view
    func registerView(_ viewId: Int64) {
        lock.lock()
        defer { lock.unlock() }

        activeViewIds.insert(viewId)

        // Start updates if this is the first view
        if activeViewIds.count == 1 {
            startGyroscopeUpdates()
        }
    }

    /// Unregisters a view from gyroscope updates
    /// - Parameter viewId: Unique identifier for the view
    func unregisterView(_ viewId: Int64) {
        lock.lock()
        defer { lock.unlock() }

        activeViewIds.remove(viewId)

        // Stop updates if no more views are listening
        if activeViewIds.isEmpty {
            stopGyroscopeUpdates()
        }
    }

    /// Sets the sensitivity for gyroscope-to-offset conversion
    /// - Parameter value: Sensitivity multiplier (default: 50.0)
    func setSensitivity(_ value: CGFloat) {
        sensitivity = value
    }

    /// Sets the smoothing factor for motion data
    /// - Parameter value: Smoothing factor 0.0-1.0 (default: 0.3)
    func setSmoothing(_ value: CGFloat) {
        smoothing = max(0.0, min(1.0, value))
    }

    /// Checks if the device supports gyroscope
    var isGyroscopeAvailable: Bool {
        return motionManager.isDeviceMotionAvailable
    }

    // MARK: - Private Methods

    private func setupMotionManager() {
        // Configure update interval (60 FPS)
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
    }

    private func startGyroscopeUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            return
        }

        motionManager.startDeviceMotionUpdates(
            using: .xArbitraryZVertical,
            to: .main
        ) { [weak self] motion, error in
            guard let self = self,
                  let attitude = motion?.attitude,
                  error == nil else {
                return
            }

            // Convert pitch and roll to spotlight offset
            // Roll: left/right tilt (-pi to pi)
            // Pitch: forward/back tilt (-pi/2 to pi/2)
            let roll = CGFloat(attitude.roll)
            let pitch = CGFloat(attitude.pitch)

            // Apply sensitivity
            let newX = roll * self.sensitivity
            let newY = pitch * self.sensitivity

            // Apply low-pass filter for smoothing
            let smoothedX = self.spotlightOffset.x + (newX - self.spotlightOffset.x) * self.smoothing
            let smoothedY = self.spotlightOffset.y + (newY - self.spotlightOffset.y) * self.smoothing

            self.spotlightOffset = CGPoint(x: smoothedX, y: smoothedY)
            self.isGyroscopeActive = true
        }
    }

    private func stopGyroscopeUpdates() {
        motionManager.stopDeviceMotionUpdates()
        isGyroscopeActive = false
        spotlightOffset = .zero
    }

    deinit {
        stopGyroscopeUpdates()
    }
}

// MARK: - SwiftUI View Extension

import SwiftUI

@available(iOS 26.0, *)
struct SpotlightOverlay: View {
    let spotlightOffset: CGPoint
    let color: Color
    let intensity: Double
    let radius: Double

    var body: some View {
        GeometryReader { geometry in
            let center = UnitPoint(
                x: 0.5 + spotlightOffset.x / geometry.size.width,
                y: 0.5 + spotlightOffset.y / geometry.size.height
            )

            RadialGradient(
                gradient: Gradient(colors: [
                    color.opacity(intensity),
                    Color.clear
                ]),
                center: center,
                startRadius: 0,
                endRadius: geometry.size.width * radius
            )
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Spotlight View Modifier

@available(iOS 26.0, *)
struct SpotlightModifier: ViewModifier {
    @ObservedObject var spotlightManager = SpotlightManager.shared
    let touchOffset: CGPoint?
    let mode: String  // "none", "touch", "gyroscope", "both"
    let color: Color
    let intensity: Double
    let radius: Double

    private var effectiveOffset: CGPoint {
        switch mode {
        case "touch":
            return touchOffset ?? .zero
        case "gyroscope":
            return spotlightManager.spotlightOffset
        case "both":
            if let touch = touchOffset {
                return CGPoint(
                    x: touch.x + spotlightManager.spotlightOffset.x * 0.4,
                    y: touch.y + spotlightManager.spotlightOffset.y * 0.4
                )
            }
            return spotlightManager.spotlightOffset
        default:
            return .zero
        }
    }

    func body(content: Content) -> some View {
        if mode == "none" {
            content
        } else {
            content.overlay(
                SpotlightOverlay(
                    spotlightOffset: effectiveOffset,
                    color: color,
                    intensity: intensity,
                    radius: radius
                )
                .animation(.easeOut(duration: 0.08), value: effectiveOffset)
            )
        }
    }
}

@available(iOS 26.0, *)
extension View {
    /// Applies a spotlight overlay that follows touch or device tilt
    func spotlight(
        touchOffset: CGPoint? = nil,
        mode: String = "none",
        color: Color = .white,
        intensity: Double = 0.3,
        radius: Double = 0.5
    ) -> some View {
        modifier(SpotlightModifier(
            touchOffset: touchOffset,
            mode: mode,
            color: color,
            intensity: intensity,
            radius: radius
        ))
    }
}
