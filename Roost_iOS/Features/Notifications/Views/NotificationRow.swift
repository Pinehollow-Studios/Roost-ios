import SwiftUI

struct NotificationRow: View {
    let notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(notification.read ? Color.roostAccent : Color.roostPrimary.opacity(0.14))
                    .frame(width: 38, height: 38)

                Image(systemName: iconName)
                    .font(.roostCaption)
                    .foregroundStyle(notification.read ? Color.roostMutedForeground : Color.roostPrimary)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Text(notification.title)
                        .font(.roostBody)
                        .foregroundStyle(Color.roostForeground)
                        .fixedSize(horizontal: false, vertical: true)

                    if !notification.read {
                        Circle()
                            .fill(Color.roostPrimary)
                            .frame(width: 8, height: 8)
                            .padding(.top, 6)
                    }
                }

                HStack(spacing: Spacing.xs) {
                    Text(typeLabel)
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)

                    Text("•")
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)

                    Text(notification.createdAt, format: .relative(presentation: .named))
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.roostCaption)
                .foregroundStyle(Color.roostMutedForeground)
                .padding(.top, 4)
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var typeLabel: String {
        guard let type = notification.type, !type.isEmpty else {
            return "Update"
        }
        return type.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private var iconName: String {
        let normalizedType = notification.type?.lowercased() ?? ""

        if normalizedType.contains("shopping") {
            return "cart"
        }
        if normalizedType.contains("expense") || normalizedType.contains("settle") {
            return "sterlingsign.circle"
        }
        if normalizedType.contains("chore") {
            return "checkmark.circle"
        }
        if normalizedType.contains("calendar") {
            return "calendar"
        }
        return "bell"
    }
}
