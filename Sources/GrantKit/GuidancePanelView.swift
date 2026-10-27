#if os(macOS)
import Observation
import SwiftUI

/// Where the guidance panel sits relative to the permission list, which
/// decides where the drag arrow points and on which side of the chip it sits.
enum GuidanceArrowDirection {
    case left
    case right
    case up

    var systemImage: String {
        switch self {
        case .left: "arrow.left"
        case .right: "arrow.right"
        case .up: "arrow.up"
        }
    }
}

/// Live view state owned by the panel controller: the dock position (and so
/// the arrow) can change while the panel follows the Settings window.
@MainActor
@Observable
final class GuidancePanelState {
    var arrowDirection: GuidanceArrowDirection = .right
}

/// Content of the floating guidance panel: the instruction, the draggable
/// app chip with a directional arrow toward the permission list, and a
/// close button.
struct GuidancePanelView: View {
    let permission: PermissionPane
    let app: AppIdentity
    let state: GuidancePanelState
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Drag \(app.displayName) into the list, then turn it on to allow \(permission.title).")
                    .font(.system(size: 13, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
            HStack(spacing: 12) {
                if state.arrowDirection == .left {
                    arrow
                }
                AppDragChip(app: app)
                    .frame(height: 44)
                if state.arrowDirection != .left {
                    arrow
                }
            }
        }
        .padding(14)
        // Narrow enough to fit beside a mid-screen System Settings window
        // (and to hug a corner when resting inside it); the instruction
        // wraps to two lines instead of stretching the panel wide.
        .frame(width: 360)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.separator, lineWidth: 1)
        )
    }

    private var arrow: some View {
        Image(systemName: state.arrowDirection.systemImage)
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(.tint)
            .frame(width: 24)
    }
}
#endif
