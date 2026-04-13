import SwiftUI

struct RoostTextField: View {
    let title: String
    @Binding var text: String
    var leadingSystemImage: String? = nil
    var textAlignment: TextAlignment = .leading
    var font: Font = .roostBody
    var textTracking: CGFloat = 0

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.row) {
            if let leadingSystemImage {
                Image(systemName: leadingSystemImage)
                    .font(.system(size: DesignSystem.Size.icon, weight: .regular))
                    .foregroundStyle(Color.roostMutedForeground)
                    .frame(width: 18, alignment: .center)
            }

            TextField(title, text: $text)
                .font(font)
                .foregroundStyle(Color.roostForeground)
                .tracking(textTracking)
                .multilineTextAlignment(textAlignment)
                .focused($isFocused)
                .frame(maxWidth: .infinity, alignment: .leading)
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
