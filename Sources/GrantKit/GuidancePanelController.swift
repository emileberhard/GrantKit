#if os(macOS)
import AppKit
import QuartzCore
import SwiftUI

/// The floating guidance panel: a borderless, non-activating window that
/// flies in next to the System Settings window and follows it around while
/// the user drags the app into the permission list.
@MainActor
final class GuidancePanelController: NSObject {
    private let panel: NSPanel
    private let panelState = GuidancePanelState()
    private let onUserDismiss: () -> Void

    private var followTask: Task<Void, Never>?
    private var displayLink: CADisplayLink?
    private var flight: Flight?
    private var pendingSourceFrame: CGRect?
    private var isPresented = false
    private var isDismissed = false

    init(permission: PermissionPane, app: AppIdentity, onUserDismiss: @escaping () -> Void) {
        self.onUserDismiss = onUserDismiss
        panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        super.init()

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .statusBar
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        panel.animationBehavior = .none

        let hosting = NSHostingView(rootView: GuidancePanelView(permission: permission, app: app, state: panelState) { [weak self] in
            self?.userDismissed()
        })
        hosting.setFrameSize(hosting.fittingSize)
        panel.contentView = hosting
        panel.setContentSize(hosting.fittingSize)
    }

    func show(flyingFrom sourceFrame: CGRect?) {
        pendingSourceFrame = sourceFrame
        followTask = Task { [weak self] in
            await self?.follow()
        }
    }

    func dismiss() {
        guard !isDismissed else { return }
        isDismissed = true
        followTask?.cancel()
        stopFlight()
        panel.orderOut(nil)
        panel.contentView = nil
    }

    private func userDismissed() {
        dismiss()
        onUserDismiss()
    }

    // MARK: Following System Settings

    /// Repositions against the System Settings window until dismissed, and
    /// ends the whole flow when the user quits System Settings.
    private func follow() async {
        var settingsSeenRunning = false
        while !Task.isCancelled {
            if SettingsWindowLocator.isSettingsRunning {
                settingsSeenRunning = true
            } else if settingsSeenRunning {
                userDismissed()
                return
            }

            if let snapshot = SettingsWindowLocator.frontmostWindow() {
                dock(to: snapshot)
            } else if isPresented, flight == nil {
                // Settings lost frontmost or has no usable window; hide until
                // it comes back rather than floating over unrelated apps.
                panel.orderOut(nil)
            }

            try? await Task.sleep(for: .milliseconds(150))
        }
    }

    private func dock(to snapshot: SettingsWindowLocator.Snapshot) {
        let target = dockFrame(for: snapshot)

        guard isPresented else {
            isPresented = true
            if let sourceFrame = pendingSourceFrame {
                startFlight(from: sourceFrame, to: target)
            } else {
                panel.setFrame(target, display: true)
                panel.orderFrontRegardless()
            }
            return
        }

        if flight != nil {
            flight?.destination = target
        } else {
            panel.setFrameOrigin(target.origin)
            panel.orderFrontRegardless()
        }
    }

    /// System Settings' sidebar has a fixed width. The left dock lays the
    /// panel over it so the panel's right edge meets the content pane where
    /// the permission list begins — visually attached to the window, arrow
    /// pointing straight at the list.
    private static let settingsSidebarWidth: CGFloat = 210

    /// Over the Settings window's sidebar at the top left, ending where the
    /// content pane begins. The sidebar is the only thing under the panel
    /// there, so it never crowds the permission list — unlike the right side,
    /// where the list and its toggles live. When the window hugs the left
    /// screen edge, the panel docks fully outside on the right instead, and
    /// only if both fail does it rest inside the window, tucked into its
    /// bottom-right corner with the up-arrow pointing at the list above.
    /// Always clamped to the visible frame.
    private func dockFrame(for snapshot: SettingsWindowLocator.Snapshot) -> CGRect {
        let size = panel.frame.size
        var direction = GuidanceArrowDirection.right
        var origin = CGPoint(
            x: snapshot.frame.minX + Self.settingsSidebarWidth - size.width,
            y: snapshot.frame.maxY - size.height - 72
        )
        if origin.x < snapshot.visibleFrame.minX + 8 {
            origin.x = snapshot.frame.maxX + 12
            direction = .left
        }
        if origin.x + size.width > snapshot.visibleFrame.maxX - 8 {
            origin.x = snapshot.frame.maxX - size.width - 20
            origin.y = snapshot.frame.minY + 16
            direction = .up
        }
        if panelState.arrowDirection != direction {
            panelState.arrowDirection = direction
        }
        origin.x = max(origin.x, snapshot.visibleFrame.minX + 8)
        origin.y = min(
            max(origin.y, snapshot.visibleFrame.minY + 8),
            snapshot.visibleFrame.maxY - size.height - 8
        )
        return CGRect(origin: origin, size: size)
    }

    // MARK: Flight animation

    /// The Codex-style entrance: a critically damped spring along a quadratic
    /// Bézier arc from where the user clicked to the dock position. A display
    /// link (not an async loop) because window-frame animation must step at
    /// display refresh rate to look right.
    struct Flight {
        let start: CGRect
        var destination: CGRect
        let startTime = CACurrentMediaTime()
        static let duration: TimeInterval = 0.72

        var isFinished: Bool { CACurrentMediaTime() - startTime >= Self.duration }

        func frame() -> CGRect {
            let elapsed = max(0, CACurrentMediaTime() - startTime)
            let omega = (2 * Double.pi) / Self.duration
            let progress = min(1, 1 - exp(-omega * elapsed) * (1 + omega * elapsed))
            return Self.interpolate(from: start, to: destination, progress: progress)
        }

        static func interpolate(from start: CGRect, to end: CGRect, progress: Double) -> CGRect {
            let p = CGFloat(progress)
            let size = CGSize(
                width: start.width + (end.width - start.width) * p,
                height: start.height + (end.height - start.height) * p
            )
            let s = CGPoint(x: start.midX, y: start.midY)
            let e = CGPoint(x: end.midX, y: end.midY)
            let distance = hypot(e.x - s.x, e.y - s.y)
            let lift = min(140, max(44, distance * 0.18))
            let control = CGPoint(x: (s.x + e.x) / 2, y: max(s.y, e.y) + lift)
            let q = 1 - p
            let center = CGPoint(
                x: q * q * s.x + 2 * q * p * control.x + p * p * e.x,
                y: q * q * s.y + 2 * q * p * control.y + p * p * e.y
            )
            return CGRect(
                x: center.x - size.width / 2,
                y: center.y - size.height / 2,
                width: size.width,
                height: size.height
            )
        }
    }

    private func startFlight(from sourceFrame: CGRect, to target: CGRect) {
        flight = Flight(start: sourceFrame, destination: target)
        panel.alphaValue = 0.9
        panel.setFrame(sourceFrame, display: false)
        panel.orderFrontRegardless()

        let link = panel.displayLink(target: self, selector: #selector(stepFlight))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc
    private func stepFlight() {
        guard let flight else {
            stopFlight()
            return
        }
        if flight.isFinished {
            panel.alphaValue = 1
            panel.setFrame(flight.destination, display: true)
            self.flight = nil
            stopFlight()
            return
        }
        let frame = flight.frame()
        panel.alphaValue = 0.9 + 0.1 * min(1, (CACurrentMediaTime() - flight.startTime) / Flight.duration)
        panel.setFrame(frame, display: true)
    }

    private func stopFlight() {
        displayLink?.invalidate()
        displayLink = nil
    }
}
#endif
