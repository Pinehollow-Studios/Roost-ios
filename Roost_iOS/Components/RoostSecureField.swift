import SwiftUI

struct RoostSecureField: View {
    let title: String
    @Binding var text: String
    var leadingSystemImage: String? = nil
    @State private var revealsText = false

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.row) {
            if let leadingSystemImage {
                Image(systemName: leadingSystemImage)
                    .font(.system(size: DesignSystem.Size.icon, weight: .regular))
                    .foregroundStyle(Color.roostMutedForeground)
                    .frame(width: 18, alignment: .center)
            }

            Group {
                if revealsText {
                    TextField(title, text: $text)
                } else {
                    SecureField(title, text: $text)
                }
            }
            .font(.roostBody)
            .foregroundStyle(Color.roostForeground)
            .focused($isFocused)
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                revealsText.toggle()
            } label: {
                Image(systemName: revealsText ? "eye.slash" : "eye")
                    .font(.system(size: DesignSystem.Size.icon, weight: .regular))
                    .foregroundStyle(Color.roostMutedForeground)
                    .frame(width: 18, alignment: .center)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DesignSystem.Spacing.card)
        .frame(minHeight: 48)
        .background(
            RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                .fill(Color.roostInput)
        )
        .overlay(
            RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                .stroke(borderColor, lineWidth: isFocused ? 1.5 : 1)
        )
        .animation(.roostEaseOut, value: isFocused)
    }

    private var borderColor: Color {
        isFocused ? Color.roostPrimary.opacity(RoostTheme.focusRingOpacity) : Color.roostHairline
    }
}
