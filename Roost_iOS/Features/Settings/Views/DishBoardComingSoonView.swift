import SwiftUI

struct DishBoardComingSoonView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                RoostCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Label("Coming soon", systemImage: "sparkles.rectangle.stack")
                            .font(.roostSection)
                            .foregroundStyle(Color.roostForeground)

                        Text("DishBoard will bring kitchen inventory, meal planning, and household coordination into one dedicated flow.")
                            .font(.roostBody)
                            .foregroundStyle(Color.roostMutedForeground)
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .navigationTitle("DishBoard")
        .navigationBarTitleDisplayMode(.inline)
        .swipeBackEnabled()
    }
}
