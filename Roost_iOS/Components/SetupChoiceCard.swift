import SwiftUI

struct SetupChoiceCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                    .fill(Color.roostAccent)
                    .frame(
                        width: DesignSystem.Size.setupChoiceIconContainer,
                        height: DesignSystem.Size.setupChoiceIconContainer
                    )
                    .overlay {
                        Image(systemName: systemImage)
                            .font(.system(size: DesignSystem.Size.setupChoiceIcon, weight: .regular))
                            .foregroundStyle(Color.roostForeground)
                    }
                    .padding(.bottom, DesignSystem.Spacing.row)

                Text(title)
                    .font(.roostBody.weight(.medium))
                    .foregroundStyle(Color.roostForeground)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostMutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.top, DesignSystem.Spacing.micro)
            }
            .frame(maxWidth: .infinity, minHeight: DesignSystem.Size.setupChoiceMinHeight, alignment: .top)
            .padding(DesignSystem.Spacing.cardLarge)
            .background(
                RoundedRectangle(cornerRadius: RoostTheme.cardCornerRadius, style: .continuous)
                    .fill(isSelected ? Color.roostPrimary.opacity(0.1) : Color.roostCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: RoostTheme.cardCornerRadius, style: .continuous)
                    .stroke(isSelected ? Color.roostPrimary : Color.roostHairline, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: RoostTheme.cardCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
