#if os(iOS)
import AVFAudio
import UIKit

/// Guides the user through granting an iOS privacy permission: a permission
/// iOS can still prompt for uses the system prompt; an already-denied one
/// opens the app's page in Settings, where its toggle lives.
@MainActor
public enum PermissionGuide {
    /// Requests `permission` and resolves once the outcome is known.
    ///
    /// - A `.notDetermined` permission shows the system prompt (the host app
    ///   must declare the matching usage-description key, or iOS terminates
    ///   it) and resolves with the user's answer.
    /// - A `.denied` permission opens the app's page in Settings and resolves
    ///   `false` immediately: iOS terminates the app when the toggle flips,
    ///   so a fresh grant is only observable after relaunch. Derive setup
    ///   flows from persistent state so they resume at the right step.
    @discardableResult
    public static func request(_ permission: SystemPermission) async -> Bool {
        switch permission.status {
        case .granted:
            return true
        case .notDetermined:
            switch permission {
            case .microphone:
                return await AVAudioApplication.requestRecordPermission()
            }
        case .denied:
            _ = await UIApplication.shared.open(permission.settingsURL)
            return false
        }
    }
}
#endif
