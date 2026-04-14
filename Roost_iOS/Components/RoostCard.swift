import SwiftUI

struct RoostCard<Content: View>: View {
    enum Prominence {
        case standard
        case elevated
        case quiet
    }

    private let padding: CGFloat
    private let prominence: Prominence
    private let content: Content

    init(
        padding: CGFloat = DesignSystem.Spacing.card,
        prominence: Prominence = .standard,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.prominence = prominence
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(
                color: shadowColor,
                radius: prominence == .elevated ? 20 : 6,
                x: 0,
                y: prominence == .elevated ? 10 : 2
            )
    }

    private var shadowColor: Color {
        switch prominence {
        case .quiet:
            return .clear
        case .standard:
            return Color.black.opacity(0.035)
        case .elevated:
            return Color.roostShadow
        }
    }

    private var borderColor: Color {
        switch prominence {
        case .quiet:
            return .clear
        case .standard:
            return DesignSystem.Palette.border
        case .elevated:
            return Color.roostPrimary.opacity(0.12)
        }
    }

    private var background: some View {
        ZStack {
            RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous)
                .fill(DesignSystem.Palette.card)
            if prominence == .elevated {
                RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous)
                    .fill(Color.roostPrimary.opacity(0.04))
            }
        }
    }
}
