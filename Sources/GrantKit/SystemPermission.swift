#if os(macOS)
import ApplicationServices
import AVFoundation
import CoreGraphics
import Foundation
import IOKit.hid

/// A macOS privacy permission that GrantKit can check and guide the user
/// through granting.
public enum SystemPermission: String, CaseIterable, Identifiable, Sendable {
    case microphone
    case accessibility
    case inputMonitoring
    case screenRecording

    public var id: String { rawValue }

    /// The name macOS uses for this permission in System Settings.
    public var title: String {
        switch self {
        case .microphone: "Microphone"
        case .accessibility: "Accessibility"
        case .inputMonitoring: "Input Monitoring"
        case .screenRecording: "Screen Recording"
        }
    }

    /// Whether the permission is currently granted.
    ///
    /// Screen Recording caveat: `CGPreflightScreenCaptureAccess` reflects the
    /// state the process launched with and does not observe a mid-session
    /// grant, so a fresh grant only reads as granted after relaunch. macOS
    /// itself offers "Quit & Reopen" when the toggle flips, which covers the
    /// guided flow.
    public var isGranted: Bool {
        switch self {
        case .microphone:
            AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        case .accessibility:
            AXIsProcessTrusted()
        case .inputMonitoring:
            CGPreflightListenEventAccess()
                || IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeGranted
        case .screenRecording:
            CGPreflightScreenCaptureAccess()
        }
    }

    /// Deep link to this permission's pane in System Settings.
    public var settingsURL: URL {
        URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?\(paneAnchor)")!
    }

    var paneAnchor: String {
        switch self {
        case .microphone: "Privacy_Microphone"
        case .accessibility: "Privacy_Accessibility"
        case .inputMonitoring: "Privacy_ListenEvent"
        case .screenRecording: "Privacy_ScreenCapture"
        }
    }

    /// The service name `tccutil` uses for this permission.
    var tccServiceName: String {
        switch self {
        case .microphone: "Microphone"
        case .accessibility: "Accessibility"
        case .inputMonitoring: "ListenEvent"
        case .screenRecording: "ScreenCapture"
        }
    }
}
#endif
