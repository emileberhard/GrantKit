# Permission guidance boundaries

GrantKit helps a host app explain and request existing operating-system
permissions. It does not capture microphone audio, bypass permission decisions,
repair signing, reset grants, store application state, or contact a service.

`SystemPermission` reads the calling process's authorization. macOS guidance
separates the Settings destination (`PermissionPane`) and displayed app identity
from the authoritative async check supplied by the actual permission owner.
This avoids treating a presenter's authorization as another app's permission.
An unavailable check throws instead of becoming a fabricated denial or grant.

The request owns its polling task and panel lifetime. Owner checks must bound
their work and cooperate with cancellation: the initial check runs before the
polling deadline starts, and the deadline is tested between completed checks.
Cleanup waits for the active owner check to finish; its errors, including
cancellation errors, propagate. A single direct check is sufficient for the
calling app, while external owners supply the operation they already control.
A global permission registry or background daemon would add ownership without
improving this request.

macOS presentation follows System Settings window bounds and gives its app URL
to the drag pasteboard. iOS uses the system microphone prompt and app Settings.
The host owns onboarding sequencing because an operating-system permission
change can terminate it. Reusable iOS views inherit host style and tint.

There are no external dependencies or bundled native binaries. macOS demo code
stays outside the portable library target. Supporting a new permission requires
checking its actual platform authorization contract; it must not extend a
Boolean status API to mean unknown or an unverified other-process grant.

## Distribution

The package preserves its existing Swift 6.2 manifest and macOS/iOS 26 minimums.
Publication changes licensing and delivery, with no permission API or behavior
migration. Apple system frameworks remain the only dependencies.

Hosted CI compiles and tests macOS and compiles the iOS library without signing.
An annotated version tag admits a release only after push or manually triggered
default-branch CI passed on that exact commit. The initial public snapshot can
run CI after Actions is enabled without changing its gated tree. A separate job receives write permission solely to publish the tag’s
notes. Rebuilding binaries or adding a private runner would introduce state and
credentials without serving a source-only SwiftPM release.

A fresh public history excludes all previous GitHub surfaces. Existing consumers
must move from private revision pins to the immutable public version. Preserving
the public URL and package identity keeps that migration limited to pins and
transport; retaining the old private commit at that URL would defeat the fresh
history boundary. The private archive remains the recovery source.
