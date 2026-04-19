import SwiftUI

struct RoostCard<Content: View>: View {
    enum Prominence {
        /// Default card — card fill, 1pt hairline, warm `shadow-card`, highlight-top inset.
        case standard
        /// Lifted card — primary-tinted fill, bigger warm `shadow-elevated`.
        case elevated
        /// Quiet — no border, no shadow. Used for nested card-in-card.
        case quiet
        /// Hero card — `r-xl (22)`, 20pt padding, 3pt feature-tint gradient bar along the top
        /// edge, 11% feature-tint blob in the top-trailing corner. Signature pattern per
        /// design-ethos §164-165. Accent is the feature tint (Money/Shopping/Chores/…).
        case hero(accent: Color)
    }

    private let padding: CGFloat?
    private let prominence: Prominence
    private let content: Content

    init(
        padding: CGFloat? = nil,
        prominence: Prominence = .standard,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.prominence = prominence
        self.content = content()
    }

    var body: some View {
        content
            .padding(effectivePadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .overlay(accentBlob)                      // hero only
            .overlay(alignment: .top) { topAccentBar } // hero only
            .clipShape(clipShape)
            .overlay(borderOverlay)
            .overlay(highlightOverlay)                // inner highlight top
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0,
                y: shadowYOffset
            )
    }

    // MARK: - Computed style

    private var effectivePadding: CGFloat {
        if let padding { return padding }
        switch prominence {
        case .hero: return DesignSystem.Spacing.cardLarge
        default:    return DesignSystem.Spacing.card
        }
    }

    private var cornerRadius: CGFloat {
        switch prominence {
        case .hero: return DesignSystem.Radius.xl
        default:    return RoostTheme.cornerRadius
        }
    }

    private var clipShape: some Shape {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    private var shadowColor: Color {
        switch prominence {
        case .quiet:    return .clear
        case .standard: return DesignSystem.Shadow.cardColor
        case .elevated: return DesignSystem.Shadow.elevatedColor
        case .hero:     return DesignSystem.Shadow.cardColor
        }
    }

    private var shadowRadius: CGFloat {
        switch prominence {
        case .elevated: return DesignSystem.Shadow.elevatedRadius
        default:        return DesignSystem.Shadow.cardRadius
        }
    }

    private var shadowYOffset: CGFloat {
        switch prominence {
        case .elevated: return DesignSystem.Shadow.elevatedYOffset
        default:        return DesignSystem.Shadow.cardYOffset
        }
    }

    private var borderColor: Color {
        switch prominence {
        case .quiet:
            return .clear
        case .standard, .hero:
            return DesignSystem.Palette.border
        case .elevated:
            return Color.roostPrimary.opacity(0.12)
        }
    }

    private var background: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(DesignSystem.Palette.card)
            if case .elevated = prominence {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.roostPrimary.opacity(0.04))
            }
        }
    }

    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(borderColor, lineWidth: 1)
    }

    /// 1pt inner highlight along the top edge — creates material lift per `--highlight-top`.
    /// Suppressed on `.quiet` since it's meant to look flat-nested.
    @ViewBuilder
    private var highlightOverlay: some View {
        switch prominence {
        case .quiet:
            EmptyView()
        default:
            VStack(spacing: 0) {
                DesignSystem.Highlight.topColor
                    .frame(height: 1)
                    .padding(.horizontal, cornerRadius * 0.5)
                Spacer(minLength: 0)
            }
            .allowsHitTesting(false)
            .clipShape(clipShape)
            .blendMode(.plusLighter)
        }
    }

    // MARK: - Hero-only decorations

    @ViewBuilder
    private var topAccentBar: some View {
        if case let .hero(accent) = prominence {
            LinearGradient(
                colors: [accent.opacity(0.85), accent],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 3)
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var accentBlob: some View {
        if case let .hero(accent) = prominence {
            GeometryReader { geo in
                Circle()
                    .fill(accent.opacity(0.11))
                    .frame(width: geo.size.width * 0.55, height: geo.size.width * 0.55)
                    .blur(radius: 32)
                    .offset(x: geo.size.width * 0.30, y: -geo.size.width * 0.18)
                    .allowsHitTesting(false)
            }
            .clipShape(clipShape)
        }
    }
}
