#if os(iOS)
import AVFAudio
import UIKit

/// An iOS privacy permission that GrantKit can check and guide the user
/// through granting.
public enum SystemPermission: String, CaseIterable, Identifiable, Sendable {
    case microphone

    public var id: String { rawValue }

    /// The name iOS uses for this permission in Settings.
    public var title: String {
        switch self {
        case .microphone: "Microphone"
        }
    }

    public var status: PermissionStatus {
        switch self {
        case .microphone:
            switch AVAudioApplication.shared.recordPermission {
            case .granted: .granted
            case .denied: .denied
            case .undetermined: .notDetermined
            @unknown default: .denied
            }
        }
    }

    /// Whether the permission is currently granted.
    public var isGranted: Bool { status == .granted }

    /// The app's own page in the Settings app, where every permission toggle
    /// lives on iOS.
    public var settingsURL: URL {
        URL(string: UIApplication.openSettingsURLString)!
    }
}

public enum PermissionStatus: Sendable {
    case notDetermined
    case denied
    case granted
}
#endif
