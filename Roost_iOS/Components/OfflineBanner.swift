import SwiftUI

struct OfflineBanner: View {
    let isVisible: Bool

    var body: some View {
        if isVisible {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "wifi.slash")
                    .foregroundStyle(Color.roostWarning)
                Text("You're offline. Changes will sync when connection returns.")
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.roostCaption)
            .foregroundStyle(Color.roostForeground)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .frame(maxWidth: .infinity)
            .background(Color.roostWarning.opacity(0.18), in: RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                    .stroke(Color.roostWarning.opacity(0.20), lineWidth: 1)
            )
        }
    }
}
