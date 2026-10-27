import AppKit
import GrantKit
import SwiftUI

// Run with: swift run GrantKitDemo
//
// Note: the demo runs as a bare executable, so the drag chip offers the
// binary itself. That is enough to exercise the panel, the flight animation,
// and Settings-window following. Microphone is status-only here because the
// system prompt requires an Info.plist usage description.

struct DemoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("GrantKit Demo")
                .font(.title2.bold())
            ForEach(SystemPermission.allCases) { permission in
                PermissionRow(permission: permission)
            }
        }
        .padding(24)
        .frame(width: 380)
    }
}

struct PermissionRow: View {
    let permission: SystemPermission
    @State private var isGranted = false

    var body: some View {
        HStack {
            Circle()
                .fill(isGranted ? .green : .secondary)
                .frame(width: 10, height: 10)
            Text(permission.title)
            Spacer()
            if permission == .microphone {
                Text(isGranted ? "Granted" : "Not granted")
                    .foregroundStyle(.secondary)
            } else {
                Button(isGranted ? "Granted" : "Guide me") {
                    Task {
                        isGranted = await PermissionGuide.request(permission)
                    }
                }
                .disabled(isGranted)
            }
        }
        .task {
            for await granted in PermissionMonitor.updates(for: permission) {
                isGranted = granted
            }
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)

let window = NSWindow(
    contentRect: .zero,
    styleMask: [.titled, .closable, .miniaturizable],
    backing: .buffered,
    defer: false
)
window.title = "GrantKit"
let hosting = NSHostingView(rootView: DemoView())
hosting.setFrameSize(hosting.fittingSize)
window.contentView = hosting
window.setContentSize(hosting.fittingSize)
window.center()
window.makeKeyAndOrderFront(nil)

app.activate()
app.run()
