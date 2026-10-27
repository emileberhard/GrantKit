#if os(macOS)
import AppKit
import CoreGraphics

/// Locates the frontmost System Settings window so the guidance panel can
/// dock to it and follow it around.
///
/// `CGWindowListCopyWindowInfo` returns window metadata (owner, bounds,
/// layer) without any permission; only reading pixels needs Screen Recording.
enum SettingsWindowLocator {
    static let settingsBundleIdentifier = "com.apple.systempreferences"

    struct Snapshot: Equatable {
        let frame: CGRect
        let visibleFrame: CGRect
    }

    static var isSettingsRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: settingsBundleIdentifier).isEmpty
    }

    static var isSettingsFrontmost: Bool {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier == settingsBundleIdentifier
    }

    /// The System Settings main window in AppKit screen coordinates, or nil
    /// while Settings is not frontmost or has no usable window yet.
    static func frontmostWindow() -> Snapshot? {
        guard isSettingsFrontmost,
              let app = NSRunningApplication.runningApplications(withBundleIdentifier: settingsBundleIdentifier).first,
              let windowInfo = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]
        else { return nil }

        let candidates = windowInfo.compactMap { info -> Snapshot? in
            guard let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t,
                  ownerPID == app.processIdentifier,
                  let layer = info[kCGWindowLayer as String] as? Int, layer == 0,
                  let bounds = info[kCGWindowBounds as String] as? [String: CGFloat]
            else { return nil }

            let cgFrame = CGRect(
                x: bounds["X"] ?? 0,
                y: bounds["Y"] ?? 0,
                width: bounds["Width"] ?? 0,
                height: bounds["Height"] ?? 0
            )
            // Ignore sheets, toolbars, and other small accessory windows.
            guard cgFrame.width > 320, cgFrame.height > 240 else { return nil }
            return appKitSnapshot(from: cgFrame)
        }

        return candidates.max { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }
    }

    /// Converts a CG window frame (origin top-left of the main display) to
    /// AppKit screen coordinates (origin bottom-left), on the screen the
    /// window mostly overlaps.
    private static func appKitSnapshot(from cgFrame: CGRect) -> Snapshot {
        let screens = NSScreen.screens.compactMap { screen -> (frame: CGRect, visibleFrame: CGRect, cgBounds: CGRect)? in
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return nil
            }
            let displayID = CGDirectDisplayID(number.uint32Value)
            return (screen.frame, screen.visibleFrame, CGDisplayBounds(displayID))
        }

        let matched = screens
            .filter { $0.cgBounds.intersects(cgFrame) }
            .max { lhs, rhs in
                lhs.cgBounds.intersection(cgFrame).area < rhs.cgBounds.intersection(cgFrame).area
            }

        guard let matched else {
            let visibleFrame = NSScreen.main?.visibleFrame ?? CGRect(origin: .zero, size: cgFrame.size)
            return Snapshot(frame: cgFrame, visibleFrame: visibleFrame)
        }

        let localX = cgFrame.minX - matched.cgBounds.minX
        let localY = cgFrame.minY - matched.cgBounds.minY
        let frame = CGRect(
            x: matched.frame.minX + localX,
            y: matched.frame.maxY - localY - cgFrame.height,
            width: cgFrame.width,
            height: cgFrame.height
        )
        return Snapshot(frame: frame, visibleFrame: matched.visibleFrame)
    }
}

private extension CGRect {
    var area: CGFloat { width * height }
}
#endif
