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

/// Toggle row per design-system spec (`components-inputs.html §399-405`):
/// - Track 46×28, `r-full`, terracotta when on / muted when off.
/// - Inset 1pt dark shadow on the track for inner depth.
/// - Thumb 22pt circle, warm-white fill, warm copper shadow `rgba(139,58,30,0.25)`.
struct FigmaSwitchToggleStyle: ToggleStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                // Track
                Capsule()
                    .fill(configuration.isOn ? Color.roostPrimary : Color.roostMuted)
                    .frame(width: 46, height: 28)
                    .overlay(
                        // Inner dark border — gives the track depth per DS prototype.
                        Capsule()
                            .strokeBorder(Color(hex: 0x3D3229, alpha: 0.10), lineWidth: 1)
                    )

                // Thumb
                Circle()
                    .fill(Color.roostWarmWhite)
                    .frame(width: 22, height: 22)
                    .shadow(
                        color: Color(hex: 0x8B3A1E, alpha: 0.25),
                        radius: 3,
                        x: 0,
                        y: 1
                    )
                    .padding(3)
            }
            .frame(width: 46, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? nil : .roostEaseOut, value: configuration.isOn)
    }
}
