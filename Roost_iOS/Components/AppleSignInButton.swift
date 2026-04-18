import SwiftUI

struct AppleSignInButton: View {
    let title: String
    var isLoading = false
    var action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: DesignSystem.Spacing.row) {
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(Color.roostForeground)
                            .controlSize(.small)
                    } else {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 18, weight: .medium))
                    }
                }
                .frame(width: 18, height: 18)

                Text(title)
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostForeground)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: DesignSystem.Size.buttonHeight)
            .padding(.horizontal, DesignSystem.Spacing.card)
        }
        .buttonStyle(
            RoostPressableButtonStyle(
                reduceMotion: reduceMotion,
                backgroundColor: .roostCard,
                foregroundColor: .roostForeground,
                borderColor: .roostHairline,
                borderWidth: 1
            )
        )
        .disabled(isLoading)
        .animation(.roostEaseOut, value: isLoading)
    }
}
