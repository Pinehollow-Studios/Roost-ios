import SwiftUI

struct FigmaSelectablePill: View {
    let title: String
    var isSelected = false
    var showsChevron = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.roostLabel)

                if showsChevron {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                }
            }
            .foregroundStyle(isSelected ? Color.roostCard : Color.roostMutedForeground)
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(isSelected ? Color.roostPrimary : Color.roostMuted, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
