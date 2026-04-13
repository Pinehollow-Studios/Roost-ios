import SwiftUI

struct SettingsToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.row) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                Text(title)
                    .font(.roostBody.weight(.medium))
                    .foregroundStyle(Color.roostForeground)
                    .fixedSize(horizontal: false, vertical: true)

                Text(description)
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostMutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(FigmaSwitchToggleStyle())
        }
        .padding(.vertical, 12)
    }
}

struct FigmaSwitchToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                Capsule()
                    .fill(configuration.isOn ? Color.roostPrimary : Color.roostMuted)
                    .frame(width: 48, height: 24)

                Circle()
                    .fill(Color.roostCard)
                    .frame(width: 20, height: 20)
                    .padding(2)
            }
            .frame(width: 48, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.roostEaseOut, value: configuration.isOn)
    }
}
