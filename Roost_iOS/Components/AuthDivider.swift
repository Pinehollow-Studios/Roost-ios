import SwiftUI

struct AuthDivider: View {
    let title: String
    var textFont: Font = .roostBody

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.roostHairline)
                .frame(height: 1)

            Text(title)
                .font(textFont)
                .foregroundStyle(Color.roostMutedForeground)
                .padding(.horizontal, DesignSystem.Spacing.card)

            Rectangle()
                .fill(Color.roostHairline)
                .frame(height: 1)
        }
    }
}
