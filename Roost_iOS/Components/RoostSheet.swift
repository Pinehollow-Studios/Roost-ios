import SwiftUI

struct RoostSheet<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Capsule()
                .fill(Color.roostMutedForeground.opacity(0.25))
                .frame(width: 40, height: 5)
                .padding(.top, Spacing.sm)

            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.xl)
        .presentationBackground(Color.roostCard)
    }
}
