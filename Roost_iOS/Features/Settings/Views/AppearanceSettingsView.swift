import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(AppearanceSettings.self) private var appearanceSettings

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
                FigmaBackHeader(title: "Appearance", accent: .roostPrimary)
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
                            .padding(.leading, 52)
                    }
                }
            }
        }
    }

    private func optionRow(_ option: AppAppearance) -> some View {
        Button {
            guard appearanceSettings.selection != option else { return }
            withAnimation(.roostSnappy) {
                appearanceSettings.selection = option
            }
        } label: {
            HStack(spacing: DesignSystem.Spacing.row) {
                ZStack {
                    Circle()
                        .fill(optionIconBackground(for: option))
                        .frame(width: 36, height: 36)
                    Image(systemName: option.symbolName)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(optionIconForeground(for: option))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(option.title)
                        .font(.roostBody.weight(.medium))
                        .foregroundStyle(Color.roostForeground)
                    Text(option.subtitle)
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                ZStack {
                    Circle()
                        .fill(appearanceSettings.selection == option ? Color.roostPrimary : Color.clear)
                        .frame(width: 22, height: 22)
                    Circle()
                        .strokeBorder(
                            appearanceSettings.selection == option ? Color.clear : Color.roostHairline,
                            lineWidth: 1.5
                        )
                        .frame(width: 22, height: 22)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .opacity(appearanceSettings.selection == option ? 1 : 0)
                        .scaleEffect(appearanceSettings.selection == option ? 1 : 0.5)
                }
                .animation(.roostSnappy, value: appearanceSettings.selection)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, DesignSystem.Spacing.row)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func optionIconBackground(for option: AppAppearance) -> Color {
        switch option {
        case .system: return Color.roostAccent
        case .light:  return Color.roostPrimary.opacity(0.12)
        case .dark:   return Color.roostSecondary.opacity(0.16)
        }
    }

    private func optionIconForeground(for option: AppAppearance) -> Color {
        switch option {
        case .system: return .roostForeground
        case .light:  return .roostPrimary
        case .dark:   return .roostSecondary
        }
    }
}
