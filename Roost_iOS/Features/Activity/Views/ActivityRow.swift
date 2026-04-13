import SwiftUI

struct ActivityRow: View {
    let item: ActivityFeedItem
    let member: HomeMember?
    let memberName: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.lg) {
            MemberAvatar(member: member, fallbackLabel: memberName, size: .sm)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(alignment: .top, spacing: Spacing.sm) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(memberName)
                            .font(.roostMeta)
                            .foregroundStyle(Color.roostForeground)

                        Text(item.action)
                            .font(.roostBody)
                            .foregroundStyle(Color.roostForeground)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Text(item.createdAt, format: .relative(presentation: .named))
                        .font(.roostMeta)
                        .foregroundStyle(Color.roostMutedForeground)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 6)
                        .background(Color.roostPrimary.opacity(0.10))
                        .clipShape(Capsule())
                }

                if let entityType = item.entityType, !entityType.isEmpty {
                    Text(entityType.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.roostMeta)
                        .foregroundStyle(Color.roostMutedForeground)
                }
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.roostCard, in: RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous)
                .stroke(Color.roostForeground.opacity(0.08), lineWidth: 1)
        )
    }
}
