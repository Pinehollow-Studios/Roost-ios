import SwiftUI

struct MorePlaceholderView: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        ScrollView(showsIndicators: false) {
            EmptyStateView(
                icon: icon,
                title: title,
                message: subtitle,
                eyebrow: "More"
            )
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
