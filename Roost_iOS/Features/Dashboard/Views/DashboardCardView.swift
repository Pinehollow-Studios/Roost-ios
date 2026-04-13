import SwiftUI

struct DashboardCardView<Content: View>: View {
    let title: String
    let systemImage: String
    var tint: Color = .roostPrimary
    var actionLabel: String = "Open"
    let action: () -> Void
    @ViewBuilder let content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            RoostSectionSurface(emphasis: .subtle) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack(alignment: .center, spacing: Spacing.md) {
                        Image(systemName: systemImage)
                            .font(.roostLabel)
                            .foregroundStyle(tint)
                            .frame(width: 32, height: 32)
                            .background(tint.opacity(0.14), in: Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(.roostCardTitle)
                                .foregroundStyle(Color.roostForeground)

                            Text(actionLabel)
                                .font(.roostMeta)
                                .foregroundStyle(Color.roostMutedForeground)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.roostCaption)
                            .foregroundStyle(Color.roostMutedForeground)
                    }

                    content
                }
            }
        }
        .buttonStyle(
            DashboardCardButtonStyle(
                reduceMotion: reduceMotion
            )
        )
    }
}

private struct DashboardCardButtonStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .animation(reduceMotion ? nil : .roostEaseOut, value: configuration.isPressed)
    }
}
