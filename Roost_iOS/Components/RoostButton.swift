import SwiftUI

struct RoostButton: View {
    enum Variant {
        case primary
        case secondary
        case outline
        case ghost
        case destructive
    }

    let title: String
    var variant: Variant = .primary
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
                        .font(.roostLabel)
                }

                Text(title)
                    .font(.roostLabel)
                    .lineLimit(1)
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(minHeight: DesignSystem.Size.buttonHeight)
            .padding(.horizontal, DesignSystem.Spacing.card)
        }
        .buttonStyle(
            RoostPressableButtonStyle(
                reduceMotion: reduceMotion,
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                borderColor: borderColor,
                borderWidth: borderWidth
            )
        )
        .disabled(isLoading)
        .animation(.roostEaseOut, value: isLoading)
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary, .destructive: .roostCard
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

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foregroundColor)
            .background(
                RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                    .fill(backgroundColor)
                    .brightness(configuration.isPressed ? -0.03 : 0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(reduceMotion ? nil : .roostSpring, value: configuration.isPressed)
    }
}
