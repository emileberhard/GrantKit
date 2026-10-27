#if os(macOS)
import Foundation

/// A settings destination, not a claim that another app has permission.
public enum PermissionPane: Sendable {
    case system(SystemPermission)
    case fullDiskAccess

    public var title: String {
        switch self {
        case .system(let permission): permission.title
        case .fullDiskAccess: "Full Disk Access"
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
