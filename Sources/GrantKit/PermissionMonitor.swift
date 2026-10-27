import Foundation

/// Observes permission status by polling.
///
/// Polling instead of the undocumented `com.apple.accessibility.api`
/// distributed notification: that notification fires unreliably per pane,
/// requires a signed binary on macOS 15+, and the apps that use it (alt-tab,
/// Loop) pair it with a polling backstop anyway. For a bounded onboarding
/// wait, the backstop alone is simpler and reacts within half a second.
public enum PermissionMonitor {
    #if os(macOS)
    /// Poll only during an explicit onboarding request. Errors remain errors.
    @MainActor
    public static func waitForGrant(
        check: @escaping @MainActor () async throws -> Bool,
        timeout: Duration = .seconds(180)
    ) async throws -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now + timeout
        while !Task.isCancelled {
            if try await check() { return true }
            guard clock.now < deadline else { return false }
            do { try await Task.sleep(for: .milliseconds(500)) }
            catch is CancellationError { return false }
        }
        return false
    }
    #endif

    /// Resolves `true` as soon as `permission` is granted, or `false` on
    /// timeout or task cancellation.
    public static func waitForGrant(
        of permission: SystemPermission,
        timeout: Duration = .seconds(180)
    ) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now + timeout
        while clock.now < deadline, !Task.isCancelled {
            if permission.isGranted { return true }
            try? await Task.sleep(for: .milliseconds(500))
        }
        return permission.isGranted
    }

    /// Yields the current status immediately, then again whenever it changes.
    /// Ends when the consuming task is cancelled.
    public static func updates(
        for permission: SystemPermission,
        every interval: Duration = .seconds(1)
    ) -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let task = Task {
                var last = permission.isGranted
                continuation.yield(last)
                while !Task.isCancelled {
                    try? await Task.sleep(for: interval)
                    let current = permission.isGranted
                    if current != last {
                        last = current
                        continuation.yield(current)
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
