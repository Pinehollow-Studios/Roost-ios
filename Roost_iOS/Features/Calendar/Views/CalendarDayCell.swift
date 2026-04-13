import SwiftUI

struct CalendarDayCell: View {
    let date: Date?
    let isSelected: Bool
    let hasEvents: Bool

    var body: some View {
        VStack(spacing: 6) {
            if let date {
                Text(date, format: .dateTime.day())
                    .font(.roostLabel)
                    .foregroundStyle(isSelected ? Color.roostCard : Color.roostForeground)

                Circle()
                    .fill(hasEvents ? (isSelected ? Color.roostCard : Color.roostPrimary) : Color.clear)
                    .frame(width: 6, height: 6)
            } else {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, minHeight: 52)
        .padding(.vertical, Spacing.xs)
        .background(isSelected ? Color.roostPrimary : Color.roostMuted.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                .stroke(isSelected ? Color.clear : Color.roostBorderLight, lineWidth: 1)
        )
    }
}
