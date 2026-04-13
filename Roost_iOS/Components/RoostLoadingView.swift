import SwiftUI

struct RoostLoadingView: View {
    var message: String = "Loading…"
    var logoSize: CGFloat = DesignSystem.Size.authLogoMark

    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 20) {
            RoostLogoMark(size: logoSize)
                .offset(y: isAnimating ? -6 : 6)
                .animation(
                    reduceMotion
                        ? nil
                        : .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                    value: isAnimating
                )

            Text(message)
                .font(.roostBody)
                .foregroundStyle(Color.roostMutedForeground)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.roostBackground)
        .onAppear {
            isAnimating = true
        }
    }
}
