import SwiftUI

struct PlaceholderScreen: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text(title)
                    .font(.roostHeading)
                    .foregroundStyle(Color.roostForeground)

                RoostCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Label(title, systemImage: systemImage)
                            .font(.roostSection)
                            .foregroundStyle(Color.roostForeground)
                        Text(subtitle)
                            .font(.roostBody)
                            .foregroundStyle(Color.roostMutedForeground)
                    }
                }

                EmptyStateView(
                    icon: systemImage,
                    title: "Scaffold ready",
                    message: "This screen is wired into the app shell and ready for feature implementation."
                )
            }
            .padding(Spacing.lg)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

@Observable
final class PlaceholderViewModel {
    var title: String

    init(title: String) {
        self.title = title
    }
}
