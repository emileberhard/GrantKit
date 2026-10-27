#if os(macOS)
import Foundation
import Testing
@testable import GrantKit

@Suite struct SystemPermissionTests {
    @Test func settingsURLsUseThePrivacySecurityPane() {
        for permission in SystemPermission.allCases {
            let url = permission.settingsURL.absoluteString
            #expect(url.hasPrefix("x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_"))
        }
    }

    @Test func paneAnchorsMatchSystemSettings() {
        #expect(SystemPermission.microphone.paneAnchor == "Privacy_Microphone")
        #expect(SystemPermission.accessibility.paneAnchor == "Privacy_Accessibility")
        #expect(SystemPermission.inputMonitoring.paneAnchor == "Privacy_ListenEvent")
        #expect(SystemPermission.screenRecording.paneAnchor == "Privacy_ScreenCapture")
    }

    @Test func tccServiceNamesMatchTccutil() {
        #expect(SystemPermission.microphone.tccServiceName == "Microphone")
        #expect(SystemPermission.accessibility.tccServiceName == "Accessibility")
        #expect(SystemPermission.inputMonitoring.tccServiceName == "ListenEvent")
        #expect(SystemPermission.screenRecording.tccServiceName == "ScreenCapture")
    }
}

@Suite struct AppIdentityTests {
    @Test func mainFallsBackToExecutableName() {
        let identity = AppIdentity.main
        #expect(!identity.displayName.isEmpty)
        #expect(identity.bundleURL == Bundle.main.bundleURL)
    }
}

@Suite @MainActor struct FlightTests {
    @Test func flightEndsAtDestination() {
        let start = CGRect(x: 0, y: 0, width: 32, height: 32)
        let end = CGRect(x: 600, y: 400, width: 520, height: 120)
        let landed = GuidancePanelController.Flight.interpolate(from: start, to: end, progress: 1)
        #expect(landed.integral == end.integral)
    }

    @Test func flightArcLiftsAboveTheStraightLine() {
        let start = CGRect(x: 0, y: 0, width: 32, height: 32)
        let end = CGRect(x: 600, y: 0, width: 32, height: 32)
        let midway = GuidancePanelController.Flight.interpolate(from: start, to: end, progress: 0.5)
        #expect(midway.midY > start.midY)
    }
}
#endif

#if os(macOS)
@Suite @MainActor struct OwnerProbeTests {
    @Test func foreignOwnerDeterminesStatus() async throws {
        var calls = 0
        let granted = try await PermissionGuide.guide(
            to: .fullDiskAccess,
            app: AppIdentity(displayName: "Other Owner", bundleURL: URL(filePath: "/Applications/Other.app")),
            check: { calls += 1; return true }
        )
        #expect(granted)
        #expect(calls == 1)
    }

    @Test func unavailableOwnerIsNotPermissionDenial() async {
        struct Unavailable: Error {}
        await #expect(throws: Unavailable.self) {
            try await PermissionMonitor.waitForGrant(check: { throw Unavailable() })
        }
    }

    @Test func expiredNegativeProbeDoesNotGrant() async throws {
        let granted = try await PermissionMonitor.waitForGrant(check: { false }, timeout: .zero)
        #expect(!granted)
    }

    @Test func cancellationStopsProbing() async throws {
        let task = Task { @MainActor in
            try await PermissionMonitor.waitForGrant(check: { false })
        }
        task.cancel()
        #expect(try await task.value == false)
    }
}
#endif
