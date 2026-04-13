import SwiftUI

struct RoostPageHeader<Accessory: View>: View {
    let eyebrow: String?
    let title: String
    let subtitle: String?
    @ViewBuilder var accessory: Accessory

    init(
        eyebrow: String? = nil,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() }
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.accessory = accessory()
    }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                if let eyebrow {
                    Text(eyebrow.uppercased())
                        .font(.roostMeta)
                        .foregroundStyle(Color.roostMutedForeground)
                        .tracking(0.6)
                }

                Text(title)
                    .font(.roostHero)
                    .foregroundStyle(Color.roostForeground)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                if let subtitle {
                    Text(subtitle)
                        .font(.roostLabel)
                        .foregroundStyle(Color.roostMutedForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)

            accessory
        }
    }
}

struct RoostSectionSurface<Content: View>: View {
    enum Emphasis {
        case grouped
        case subtle
        case raised
    }

    var emphasis: Emphasis = .grouped
    var padding: CGFloat = Spacing.md
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous)
                    .stroke(Color.roostHairline, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous))
            .shadow(
                color: emphasis == .raised ? Color.roostShadow : .clear,
                radius: emphasis == .raised ? 18 : 0,
                x: 0,
                y: emphasis == .raised ? 10 : 0
            )
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous)
            .fill(backgroundColor)
    }

    private var backgroundColor: Color {
        switch emphasis {
        case .grouped:
            return Color.roostCard.opacity(0.78)
        case .subtle:
            return Color.roostSurface
        case .raised:
            return Color.roostSurfaceRaised
        }
    }
}

struct RoostInfoChip: View {
    let title: String
    let value: String
    var tint: Color = .roostAccent

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.roostMeta)
                .foregroundStyle(Color.roostMutedForeground)
                .lineLimit(1)

            Text(value)
                .font(.roostLabel)
                .foregroundStyle(Color.roostForeground)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                .fill(tint.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                .stroke(Color.roostHairline, lineWidth: 1)
        )
    }
}

struct RoostStatusPill: View {
    let title: String
    var tint: Color = .roostMutedForeground

    var body: some View {
        Text(title)
            .font(.roostMeta)
            .foregroundStyle(tint)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

struct RoostIconBadge: View {
    let systemImage: String
    var tint: Color = .roostPrimary
    var size: CGFloat = 34

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.34, style: .continuous)
                    .fill(tint.opacity(0.14))
            )
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.34, style: .continuous)
                    .stroke(Color.roostHairline, lineWidth: 1)
            )
    }
}

struct RoostPreviewRow: View {
    let title: String
    let subtitle: String
    var metadata: String? = nil
    var systemImage: String
    var tint: Color = .roostPrimary
    var showsDivider = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: Spacing.md) {
                RoostIconBadge(systemImage: systemImage, tint: tint)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.roostCardTitle)
                        .foregroundStyle(Color.roostForeground)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtitle)
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: Spacing.sm)

                VStack(alignment: .trailing, spacing: 6) {
                    if let metadata {
                        Text(metadata)
                            .font(.roostMeta)
                            .foregroundStyle(Color.roostMutedForeground)
                            .multilineTextAlignment(.trailing)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.roostMutedForeground.opacity(0.8))
                }
            }
            .contentShape(Rectangle())

            if showsDivider {
                Divider()
                    .padding(.leading, 50)
                    .padding(.top, Spacing.md)
            }
        }
    }
}

struct RoostActionDock<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.roostHairline)
                .frame(height: 1)

            content
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.md)
                .background(Color.roostBackground.opacity(0.94))
        }
    }
}

struct RoostPageContainer<Content: View>: View {
    let title: String
    let subtitle: String?
    var accessory: AnyView? = nil
    @ViewBuilder let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        accessory: AnyView? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.accessory = accessory
        self.content = content()
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                RoostPageHeader(title: title, subtitle: subtitle) {
                    if let accessory {
                        accessory
                    }
                }

                content
            }
            .padding(.horizontal, 20)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Color.roostBackground.ignoresSafeArea())
    }
}

struct RoostHeroCard<Content: View>: View {
    var tint: Color = .roostPrimary
    var padding: CGFloat = Spacing.lg
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [
                        Color.roostSurfaceRaised,
                        tint.opacity(0.14),
                        Color.roostSurface,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: RoostTheme.largeCornerRadius, style: .continuous)
                    .stroke(tint.opacity(0.16), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: RoostTheme.largeCornerRadius, style: .continuous))
            .shadow(color: Color.roostShadow, radius: 18, x: 0, y: 10)
    }
}

struct RoostStatCard: View {
    let title: String
    let value: String
    var detail: String? = nil
    var systemImage: String? = nil
    var tint: Color = .roostAccent

    var body: some View {
        RoostSectionSurface(emphasis: .subtle) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    if let systemImage {
                        RoostIconBadge(systemImage: systemImage, tint: tint, size: 30)
                    }

                    Text(title)
                        .font(.roostMeta)
                        .foregroundStyle(Color.roostMutedForeground)
                        .lineLimit(1)
                }

                Text(value)
                    .font(.roostSection)
                    .foregroundStyle(Color.roostForeground)
                    .fixedSize(horizontal: false, vertical: true)

                if let detail {
                    Text(detail)
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct RoostInlineBadge: View {
    let title: String
    var tint: Color = .roostPrimary

    var body: some View {
        Text(title)
            .font(.roostMeta)
            .foregroundStyle(tint)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(tint.opacity(0.12), lineWidth: 1)
            )
    }
}

struct RoostRowSurface<Content: View>: View {
    var tint: Color = .roostAccent
    var isMuted = false
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: isMuted
                        ? [Color.roostMuted.opacity(0.12), Color.roostSurface]
                        : [Color.roostSurfaceRaised, tint.opacity(0.10), Color.roostSurface],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke((isMuted ? Color.roostSecondary : tint).opacity(0.14), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct FlowLayout<Content: View>: View {
    var spacing: CGFloat = 8
    @ViewBuilder let content: Content

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: spacing) { content }
            VStack(alignment: .leading, spacing: spacing) { content }
        }
    }
}
