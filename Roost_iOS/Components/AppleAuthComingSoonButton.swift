import SwiftUI

struct AppleAuthComingSoonButton: View {
    var title: String = "Continue with Apple"

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.row) {
            Image(systemName: "apple.logo")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.roostMutedForeground)
                .frame(width: 18, height: 18)

            Text(title)
                .font(.roostLabel)
                .foregroundStyle(Color.roostMutedForeground)

            Spacer(minLength: 0)

            Text("Coming soon")
                .font(.roostMeta)
                .foregroundStyle(Color.roostMutedForeground)
                .padding(.horizontal, 10)
                .frame(height: 24)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.roostMuted.opacity(0.8))
                )
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: DesignSystem.Size.buttonHeight)
        .padding(.horizontal, DesignSystem.Spacing.card)
        .background(
            RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                .fill(Color.roostCard.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                .stroke(Color.roostHairline.opacity(0.8), lineWidth: 1)
        )
        .opacity(0.72)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Continue with Apple, coming soon")
    }
}
