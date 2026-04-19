import SwiftUI

struct RoostButton: View {
    enum Variant {
        case primary
        case secondary
        case outline
        case ghost
        case destructive
    }

    /// Button size variants per design-system spec (`components-buttons.html`).
    enum Size {
        /// 44pt tall, `r-md` (14), 13pt Medium label — standard CTA size.
        case regular
        /// 34pt tall, `r-sm` (10), 12pt Medium label — inline / dense layouts.
        case small
        /// 40pt tall, `r-full` pill, 20pt horizontal padding, 13pt Medium label — chip-like CTA.
        case pill
    }

    let title: String
    var variant: Variant = .primary
    var size: Size = .regular
    var systemImage: String? = nil
    var isLoading = false
    var fullWidth = true
    var action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            triggerLightImpact()
            action()
        } label: {
            HStack(spacing: Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                        .controlSize(.small)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(iconFont)
                }

                Text(title)
                    .font(labelFont)
                    .lineLimit(1)
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(minHeight: heightValue)
            .padding(.horizontal, horizontalPadding)
        }
        .buttonStyle(
            RoostPressableButtonStyle(
                reduceMotion: reduceMotion,
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                borderColor: borderColor,
                borderWidth: borderWidth,
                cornerRadius: cornerRadiusValue,
                showHighlight: showsInnerHighlight
            )
        )
        .disabled(isLoading)
        .animation(.roostEaseOut, value: isLoading)
    }

    // MARK: - Size-derived values

    private var heightValue: CGFloat {
        switch size {
        case .regular: return DesignSystem.Size.buttonHeight
        case .small:   return 34
        case .pill:    return 40
        }
    }

    private var cornerRadiusValue: CGFloat {
        switch size {
        case .regular: return RoostTheme.controlCornerRadius
        case .small:   return DesignSystem.Radius.sm
        case .pill:    return DesignSystem.Radius.full
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .regular: return DesignSystem.Spacing.card
        case .small:   return 12
        case .pill:    return 20
        }
    }

    private var labelFont: Font {
        switch size {
        case .regular, .pill: return .roostLabel
        case .small:          return .roostCaption
        }
    }

    private var iconFont: Font {
        switch size {
        case .regular, .pill: return .roostLabel
        case .small:          return .roostCaption
        }
    }

    // MARK: - Variant-derived values

    private var foregroundColor: Color {
        switch variant {
        case .primary, .destructive: .roostWarmWhite
        case .secondary, .outline: .roostForeground
        case .ghost: .roostPrimary
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary:
            return .roostPrimary
        case .secondary:
            return .roostSecondaryInteractive
        case .outline:
            return Color.roostCard
        case .ghost:
            return .clear
        case .destructive:
            return .roostDestructive
        }
    }

    private var borderColor: Color {
        switch variant {
        case .primary, .destructive:
            return .clear
        case .secondary:
            return .clear
        case .outline:
            return Color.roostHairline
        case .ghost:
            return Color.roostHairline
        }
    }

    private var borderWidth: CGFloat {
        switch variant {
        case .outline, .secondary, .ghost:
            return 1
        default:
            return 0
        }
    }

    /// Filled variants get the warm-white top-edge highlight for material lift.
    /// Ghost/outline stay flat so the hairline reads cleanly.
    private var showsInnerHighlight: Bool {
        switch variant {
        case .primary, .secondary, .destructive: return true
        case .outline, .ghost: return false
        }
    }

    private func triggerLightImpact() {
#if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
#endif
    }
}

struct RoostPressableButtonStyle: ButtonStyle {
    let reduceMotion: Bool
    let backgroundColor: Color
    let foregroundColor: Color
    let borderColor: Color
    let borderWidth: CGFloat
    var cornerRadius: CGFloat = RoostTheme.controlCornerRadius
    var showHighlight: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foregroundColor)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor)
                    .brightness(configuration.isPressed ? -0.03 : 0)
            )
            .overlay(highlightOverlay)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(reduceMotion ? nil : .roostSpring, value: configuration.isPressed)
    }

    @ViewBuilder
    private var highlightOverlay: some View {
        if showHighlight {
            VStack(spacing: 0) {
                DesignSystem.Highlight.topColorStrong
                    .frame(height: 1)
                    .padding(.horizontal, cornerRadius * 0.5)
                Spacer(minLength: 0)
            }
            .allowsHitTesting(false)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .blendMode(.plusLighter)
        }
    }
}
