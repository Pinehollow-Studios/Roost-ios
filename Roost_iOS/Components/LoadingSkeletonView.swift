import SwiftUI

struct LoadingSkeletonView: View {
    @State private var phase: CGFloat = -1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        RoundedRectangle(cornerRadius: DesignSystem.Radius.sm)
            .fill(Color.roostMuted)
            .frame(height: 100)
            .overlay {
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.roostBackground.opacity(0.25),
                            Color.clear,
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .rotationEffect(.degrees(18))
                    .offset(x: geometry.size.width * phase)
                }
                .clipShape(RoundedRectangle(cornerRadius: RoostTheme.cornerRadius, style: .continuous))
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    phase = 1.35
                }
            }
    }
}
