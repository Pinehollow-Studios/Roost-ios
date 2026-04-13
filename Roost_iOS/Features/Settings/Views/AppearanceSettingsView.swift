import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(AppearanceSettings.self) private var appearanceSettings

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
                FigmaBackHeader(title: "Appearance")
                selectionCard
            }
            .padding(.horizontal, DesignSystem.Spacing.page)
            .padding(.bottom, 108)
            .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .swipeBackEnabled()
    }

    private var selectionCard: some View {
        RoostCard {
            VStack(spacing: 0) {
                ForEach(Array(AppAppearance.allCases.enumerated()), id: \.element.id) { index, option in
                    optionRow(option)

                    if index < AppAppearance.allCases.count - 1 {
                        Divider()
                            .overlay(Color.roostHairline)
                            .padding(.leading, 48)
                    }
                }
            }
        }
    }

    private func optionRow(_ option: AppAppearance) -> some View {
        Button {
            guard appearanceSettings.selection != option else { return }
            withAnimation(.easeInOut(duration: 0.18)) {
                appearanceSettings.selection = option
            }
        } label: {
            HStack(spacing: DesignSystem.Spacing.row) {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.xs, style: .continuous)
                    .fill(optionIconBackground(for: option))
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: option.symbolName)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(optionIconForeground(for: option))
                    }

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                    Text(option.title)
                        .font(.roostBody.weight(.medium))
                        .foregroundStyle(Color.roostForeground)
                }

                Spacer(minLength: 0)

                if appearanceSettings.selection == option {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.roostPrimary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, DesignSystem.Spacing.row)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func optionIconBackground(for option: AppAppearance) -> Color {
        switch option {
        case .system:
            return Color.roostAccent
        case .light:
            return Color.roostPrimary.opacity(0.12)
        case .dark:
            return Color.roostSecondary.opacity(0.16)
        }
    }

    private func optionIconForeground(for option: AppAppearance) -> Color {
        switch option {
        case .system:
            return .roostForeground
        case .light:
            return .roostPrimary
        case .dark:
            return .roostSecondary
        }
    }
}
