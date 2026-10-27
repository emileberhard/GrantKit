# GrantKit

Public MIT Swift package for permission guidance on macOS 26+ and iOS 26+.
Keep secrets, personal data, private infrastructure and real user fixtures out
of every committed file and message.

## Ownership and invariants

- `SystemPermission*.swift` owns own-process authorization checks;
  `PermissionGuide*.swift` owns requests and Settings navigation.
- `PermissionMonitor.swift` owns cancellable polling. Owner checks must bound
  their work and cooperate with cancellation. Their errors propagate, including
  cancellation errors; polling checks its deadline between completed checks.
- macOS panel, drag chip and window locator files own presentation only.
  Never reset existing permission grants as an onboarding side effect.
- `PermissionPane` describes a destination, not authorization for another app.
  `guide(to:app:timeout:check:)` requires a check executed by the real owner.
- iOS onboarding views stay theme-neutral; the host owns sequencing and style.
- No microphone capture, networking, analytics or persistent permission store
  belongs in this package. The host declares usage descriptions and entitlements.
- `Demo/` is macOS-only; `Tests/` uses synthetic identities and no permission
  prompts. Preserve existing comments when making unrelated changes.

## Validation and release

Use Xcode from `.xcode-version`. `just test` compiles the macOS library and demo
and runs tests; `just build-ios` checks the iOS library without signing.
`just demo` opens interactive macOS UI only when requested.

Hosted CI checks both platforms and supports manual runs on the default branch
for the first publication after Actions is enabled. An annotated plain `MAJOR.MINOR.PATCH` tag
on the default branch, newer than every version tag, waits for successful CI
on its commit and publishes its tag message as GitHub release notes. SwiftPM
consumers resolve that immutable source tag; the first public version is 0.1.0.
No release credentials or self-hosted runners are needed.
