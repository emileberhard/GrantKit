#if os(iOS)
import SwiftUI

/// Common setup-step layout: a hero graphic, a title, one short explanation,
/// and the step's own controls, centered so each step reads as one focused
/// card. Public so a host app's own onboarding steps share the exact layout
/// GrantKit's ``PermissionStep`` uses.
public struct StepScaffold<Hero: View, Controls: View>: View {
    private let title: String
    private let subtitle: String
    private let hero: Hero
    private let controls: Controls

    public init(
        title: String,
        subtitle: String,
        @ViewBuilder hero: () -> Hero,
        @ViewBuilder controls: () -> Controls
    ) {
        self.title = title
        self.subtitle = subtitle
        self.hero = hero()
        self.controls = controls()
    }

    public var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            hero
                .frame(height: 104)

            VStack(spacing: 10) {
                Text(title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 20)

            controls
                .padding(.top, 26)

            Spacer(minLength: 0)
        }
    }
}

public struct HeroSymbol: View {
    private let systemImage: String
    private let tint: Color

    public init(systemImage: String, tint: Color = .accentColor) {
        self.systemImage = systemImage
        self.tint = tint
    }

    public var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 54, weight: .medium))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(tint)
            .contentTransition(.symbolEffect(.replace))
    }
}

#endif
