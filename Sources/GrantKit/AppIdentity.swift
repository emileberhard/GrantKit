#if os(macOS)
import AppKit

/// The app presented in the guidance panel: the name shown in the
/// instruction, and the bundle the user drags into the System Settings
/// permission list.
public struct AppIdentity: Sendable {
    public let displayName: String
    public let bundleURL: URL

    public init(displayName: String, bundleURL: URL) {
        self.displayName = displayName
        self.bundleURL = bundleURL
    }

    /// The current app.
    public static var main: AppIdentity {
        let bundle = Bundle.main
        let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String
            ?? bundle.bundleURL.deletingPathExtension().lastPathComponent
        return AppIdentity(displayName: displayName, bundleURL: bundle.bundleURL)
    }

    @MainActor
    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: bundleURL.path)
    }
}
#endif
