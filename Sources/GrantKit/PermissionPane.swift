#if os(macOS)
import Foundation

/// A settings destination, not a claim that another app has permission.
public enum PermissionPane: Sendable {
    case system(SystemPermission)
    case fullDiskAccess

    public var title: LocalizedStringResource {
        switch self {
        case .system(let permission): permission.title
        case .fullDiskAccess: LocalizedStringResource("Full Disk Access", bundle: #bundle, comment: "The Full Disk Access pane in System Settings > Privacy & Security.")
        }
    }

    public var settingsURL: URL {
        switch self {
        case .system(let permission): permission.settingsURL
        case .fullDiskAccess:
            URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles")!
        }
    }
}
#endif
