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
    private let title: String
    private let subtitle: String
    private let symbol: String
    private let controlSpacing: CGFloat
    private let primaryActionVerticalPadding: CGFloat
    private let onContinue: () -> Void

    @State private var status: PermissionStatus
    @State private var isRequesting = false
    @State private var hasScheduledAdvance = false

    public init(
        _ permission: SystemPermission,
        title: String? = nil,
        subtitle: String? = nil,
        symbol: String? = nil,
        controlSpacing: CGFloat = 14,
        primaryActionVerticalPadding: CGFloat = 0,
        onContinue: @escaping () -> Void
    ) {
        self.permission = permission
        self.title = title ?? "Allow \(permission.title) Access"
        self.subtitle = subtitle ?? "\(Self.appName) needs \(permission.title.lowercased()) access to continue."
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
                    Label("Granted", systemImage: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.green)
                case .notDetermined:
                    Button("Allow \(permission.title)") {
                        request()
                    }
                    .padding(.vertical, primaryActionVerticalPadding)
                    .disabled(isRequesting)
                case .denied:
                    Button("Open Settings") {
                        request()
                    }
                    .padding(.vertical, primaryActionVerticalPadding)

                    Text("Turn on \(permission.title) — iOS restarts \(Self.appName), and setup continues where you left off.")
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

    private static func defaultSymbol(for permission: SystemPermission) -> String {
        switch permission {
        case .microphone: "mic.fill"
        }
    }

    private static var appName: String {
        let info = Bundle.main
        return (info.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (info.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? "This app"
    }
}
#endif
