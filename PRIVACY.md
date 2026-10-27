# Privacy

GrantKit runs inside its host app. It has no network transport, telemetry,
account system, persistent data store, or external package dependencies.

On macOS it reads the calling process’s permission status, the host app’s name,
bundle URL and icon, and mouse position. It enumerates on-screen window metadata
to locate System Settings and place its guidance panel. It does not capture the screen or microphone audio.
Dragging the app chip places the app bundle’s file URL on the drag pasteboard
so the user can drop it into System Settings.

On iOS it reads microphone authorization status and can display the system
permission prompt or open the host app’s Settings page. The host must provide
its own microphone usage description. Reusable onboarding views display local
permission state and play success haptics.

A host can supply a permission check for another owner. That operation’s data
handling belongs to the host. Host apps also own onboarding state, usage
descriptions, entitlements, and any recording, networking or storage they add.
GrantKit never resets an existing permission grant.
