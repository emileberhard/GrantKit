#if os(iOS)
import SwiftUI

/// One focused permission step for an onboarding flow. Shows the right
/// action for the permission's current state — the system prompt while iOS
/// can still ask, Settings after an earlier denial — then animates the grant
/// in with a success haptic and advances on its own shortly after.
///
/// A grant that flips in Settings never lands here: iOS terminates the app
/// when the toggle changes, so derive the surrounding flow from persistent
/// state and this step is simply skipped on relaunch.
@MainActor
public struct PermissionStep: View {
    private let permission: SystemPermission
    private let title: LocalizedStringResource
    private let subtitle: LocalizedStringResource
    private let symbol: String
    private let controlSpacing: CGFloat
    private let primaryActionVerticalPadding: CGFloat
    private let onContinue: () -> Void

    @State private var status: PermissionStatus
    @State private var isRequesting = false
    @State private var hasScheduledAdvance = false

    public init(
        _ permission: SystemPermission,
        title: LocalizedStringResource? = nil,
        subtitle: LocalizedStringResource? = nil,
        symbol: String? = nil,
        controlSpacing: CGFloat = 14,
        primaryActionVerticalPadding: CGFloat = 0,
        onContinue: @escaping () -> Void
    ) {
        self.permission = permission
        self.title = title ?? Self.defaultTitle(for: permission)
        self.subtitle = subtitle ?? Self.defaultSubtitle(for: permission)
        self.symbol = symbol ?? Self.defaultSymbol(for: permission)
        self.controlSpacing = controlSpacing
        self.primaryActionVerticalPadding = primaryActionVerticalPadding
        self.onContinue = onContinue
        _status = State(initialValue: permission.status)
    }

    public var body: some View {
        StepScaffold(title: title, subtitle: subtitle) {
            HeroSymbol(
                systemImage: status == .granted ? "checkmark.circle.fill" : symbol,
                tint: status == .granted ? .green : .accentColor
            )
        } controls: {
            VStack(spacing: controlSpacing) {
                switch status {
                case .granted:
                    Label {
                        Text("Granted", bundle: #bundle, comment: "Shown on a permission step once the permission is allowed.")
                    } icon: {
                        Image(systemName: "checkmark")
                    }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.green)
                case .notDetermined:
                    Button {
                        request()
                    } label: {
                        Text(Self.allowAction(for: permission))
                    }
                    .padding(.vertical, primaryActionVerticalPadding)
                    .disabled(isRequesting)
                case .denied:
                    Button {
                        request()
                    } label: {
                        Text("Open Settings", bundle: #bundle, comment: "Opens the app's page in iOS Settings after the permission was denied.")
                    }
                    .padding(.vertical, primaryActionVerticalPadding)

                    Text("Turn on \(String(localized: permission.title)) — iOS restarts \(Self.appName), and setup continues where you left off.", bundle: #bundle, comment: "Below Open Settings. The first variable is the Settings switch, such as Microphone; the second is the app's name.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .animation(.spring(duration: 0.35, bounce: 0.15), value: status)
        }
        .sensoryFeedback(.success, trigger: status) { old, new in
            new == .granted && old != .granted
        }
        .task(id: permission) {
            var isInitialValue = true
            for await granted in PermissionMonitor.updates(for: permission) {
                withAnimation(.spring(duration: 0.4, bounce: 0.25)) {
                    status = permission.status
                }
                // Granted steps advance on their own: after a short beat for
                // a grant that lands while the step is showing, almost
                // immediately when the step is already satisfied as it
                // appears — there is nothing left to do on it.
                if granted, !hasScheduledAdvance {
                    hasScheduledAdvance = true
                    try? await Task.sleep(for: .seconds(isInitialValue ? 0.6 : 0.9))
                    guard !Task.isCancelled else { return }
                    onContinue()
                    return
                }
                isInitialValue = false
            }
        }
    }

    private func request() {
        isRequesting = true
        Task {
            await PermissionGuide.request(permission)
            withAnimation(.spring(duration: 0.4, bounce: 0.25)) {
                status = permission.status
            }
            isRequesting = false
        }
    }

    private static func defaultTitle(for permission: SystemPermission) -> LocalizedStringResource {
        switch permission {
        case .microphone: LocalizedStringResource("Allow Microphone Access", bundle: #bundle, comment: "Title of the microphone permission step.")
        }
    }

    private static func defaultSubtitle(for permission: SystemPermission) -> LocalizedStringResource {
        switch permission {
        case .microphone: LocalizedStringResource("\(appName) needs microphone access to continue.", bundle: #bundle, comment: "Explanation on the microphone permission step. The variable is the app's name.")
        }
    }

    private static func allowAction(for permission: SystemPermission) -> LocalizedStringResource {
        switch permission {
        case .microphone: LocalizedStringResource("Allow Microphone", bundle: #bundle, comment: "Button that shows the system microphone prompt.")
        }
    }

    private static func defaultSymbol(for permission: SystemPermission) -> String {
        switch permission {
        case .microphone: "mic.fill"
        }
    }

    private static var appName: String {
        let info = Bundle.main
        return (info.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (info.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? String(localized: "This app", bundle: #bundle, comment: "Stands in for the app's name when its bundle has none.")
    }
}
#endif
