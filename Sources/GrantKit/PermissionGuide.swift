#if os(macOS)
import AppKit
import AVFoundation

@MainActor
public enum PermissionGuide {
    /// Requests a permission for the calling app. Existing grants are never reset.
    @discardableResult
    public static func request(
        _ permission: SystemPermission,
        timeout: Duration = .seconds(180)
    ) async -> Bool {
        if permission.isGranted { return true }
        if permission == .microphone {
            return await AVCaptureDevice.requestAccess(for: .audio)
        }
        // This check cannot throw: the own-process API supplies a Boolean.
        return (try? await guide(
            to: .system(permission), app: .main, timeout: timeout,
            check: { permission.isGranted }
        )) ?? false
    }

    /// Guides approval for an explicit owner. The check must run through that
    /// owner's execution path; querying the presenting app is not sufficient.
    /// Throw when status is unknown or the owner is unavailable. A timeout or
    /// dismissal returns false, never a fabricated successful grant.
    @discardableResult
    public static func guide(
        to pane: PermissionPane,
        app: AppIdentity,
        timeout: Duration = .seconds(180),
        check: @escaping @MainActor () async throws -> Bool
    ) async throws -> Bool {
        try Task.checkCancellation()
        if try await check() { return true }
        NSWorkspace.shared.open(pane.settingsURL)
        let wait = Task { try await PermissionMonitor.waitForGrant(check: check, timeout: timeout) }
        let panel = GuidancePanelController(permission: pane, app: app) { wait.cancel() }
        panel.show(flyingFrom: mouseSourceFrame())
        defer { wait.cancel(); panel.dismiss() }
        return try await withTaskCancellationHandler {
            try await wait.value
        } onCancel: {
            wait.cancel()
        }
    }

    private static func mouseSourceFrame() -> CGRect {
        let mouse = NSEvent.mouseLocation
        return CGRect(x: mouse.x - 16, y: mouse.y - 16, width: 32, height: 32)
    }
}
#endif
