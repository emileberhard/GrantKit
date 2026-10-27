# GrantKit

macOS and iOS permission onboarding: check a privacy permission with one
property, request it with one call. Permissions macOS can prompt for use the
system prompt; the rest open the exact System Settings pane with a floating
panel that the user drags the app from straight into the permission list —
the flow popularized by OpenAI's Codex app (and Sky before it).

Requires macOS 26+ or iOS 26+, with the Swift toolchain in Xcode 27.1.
The macOS Accessibility and Input Monitoring flows require an unsandboxed host.
GrantKit does not grant permissions itself; the user and operating system decide.

Also builds for iOS 26+, where the same `SystemPermission` /
`PermissionGuide` / `PermissionMonitor` API covers the microphone: a
`.notDetermined` request shows the system prompt, a `.denied` one opens the
app's Settings page (iOS terminates the app when the toggle flips, so derive
onboarding from persistent state and resume on relaunch). iOS additionally
ships onboarding UI: `PermissionStep`, a drop-in SwiftUI step card that shows
the right action for the permission's current state, plays a success haptic,
and auto-advances on grant — built on a public `StepScaffold` +
`HeroSymbol` so an app's own custom steps share the same layout. The UI stays
host-themed: `PermissionStep` inherits the surrounding SwiftUI button style
and tint, and its control spacing and primary-action padding are configurable.

## Installation

Add `https://github.com/emileberhard/GrantKit.git` as a Swift package dependency
and link the `GrantKit` product. Pin the initial release with
`.package(url: "https://github.com/emileberhard/GrantKit.git", exact: "0.1.0")`.
There are no external package or bundled binary dependencies.

## Usage

```swift
import GrantKit

// Check
if SystemPermission.accessibility.isGranted { ... }

// Guided request — resolves when granted, dismissed, or timed out
let granted = await PermissionGuide.request(.inputMonitoring)

// Observe for a settings screen
for await granted in PermissionMonitor.updates(for: .accessibility) {
    ...
}
```

`request` checks the calling app only. For another permission owner, use
`PermissionGuide.guide(to:app:timeout:check:)`. Supply its `AppIdentity` and
an async, throwing check executed by that owner. `.system(.screenRecording)`
and `.fullDiskAccess` are settings destinations; they do not imply that the
presenting app can query another app's authorization. Owner checks must bound
their own work and cooperate with cancellation. The initial check runs before
the polling timeout starts; polling checks its deadline between completed
checks. Check errors propagate, including cancellation errors when guidance is
dismissed. Full Disk Access needs a concrete, bounded protected-file probe owned
by the application, not a guessed global API.

Microphone requests require `NSMicrophoneUsageDescription` in the host app's
Info.plist.

## What it does under the hood

- Opens the exact privacy pane via `x-apple.systempreferences:` deep links.
- Shows a borderless, non-activating panel that flies in with a damped-spring
  Bézier arc and follows the System Settings window (window metadata via
  `CGWindowListCopyWindowInfo` — no Screen Recording permission needed).
- The drag chip is an `NSDraggingSource` providing the app bundle's file URL,
  which System Settings' permission lists accept as a drop.
- Grant detection polls every 0.5 s. The undocumented
  `com.apple.accessibility.api` distributed notification was deliberately
  skipped: it fires unreliably per pane and the apps that use it keep a
  polling backstop anyway.
- Existing grants are never reset during onboarding. A negative or cached
  preflight does not prove a stale identity. Certificate repair is a separate,
  deliberate administrative operation, not a side effect of requesting access.
- Screen Recording's preflight is frozen per-process: a fresh grant reads as
  granted only after relaunch. macOS shows its own "Quit & Reopen" dialog in
  that flow.

## Demo

```bash
swift run GrantKitDemo
```

Prior art studied: [zats/permiso](https://github.com/zats/permiso),
[jaywcjlove/PermissionFlow](https://github.com/jaywcjlove/PermissionFlow),
[riko2chen/AskForPermission](https://github.com/riko2chen/AskForPermission),
plus the permission handling in alt-tab-macos, Loop, Ice, and DockDoor.

## Development

Select Xcode matching `.xcode-version`, then run `just test` and `just build-ios`.
The demo is macOS-only and microphone status-only because a bare executable
has no usage-description Info.plist. Tests do not request real permissions.

See [PRIVACY.md](PRIVACY.md) for the package’s local data handling and the
responsibilities of host apps.

## License and support

MIT; see [LICENSE](LICENSE). Questions and reproducible bugs belong in
[GitHub issues](https://github.com/emileberhard/GrantKit/issues).
Report vulnerabilities through
[private vulnerability reporting](https://github.com/emileberhard/GrantKit/security/advisories/new)
or contact eberhard.emil@gmail.com.
