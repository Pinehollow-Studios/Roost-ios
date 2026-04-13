import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var eyebrow: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        RoostSectionSurface(emphasis: .subtle, padding: Spacing.xl) {
            VStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.roostAccent.opacity(0.85))
                    Image(systemName: icon)
                        .font(.roostHeading)
                        .foregroundStyle(Color.roostPrimary)
                }
                .frame(width: 60, height: 60)

                if let eyebrow {
                    Text(eyebrow)
                        .font(.roostMeta)
                        .foregroundStyle(Color.roostMutedForeground)
                }

                Text(title)
                    .font(.roostHeading)
                    .foregroundStyle(Color.roostForeground)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.roostBody)
                    .foregroundStyle(Color.roostMutedForeground)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if let actionTitle, let action {
                    RoostButton(title: actionTitle, variant: .secondary, action: action)
                        .padding(.top, Spacing.xs)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
