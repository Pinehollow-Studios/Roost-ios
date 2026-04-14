import SwiftUI

struct RoostLoadingView: View {
    var message: String = "Loading…"
    var logoSize: CGFloat = DesignSystem.Size.authLogoMark

    @State private var breathe = false
    @State private var rotatePrimary = false
    @State private var rotateSecondary = false
    @State private var dotPhase = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 22) {
            logoStage

            HStack(spacing: 0) {
                Text("Loading")
                    .font(.roostBody.weight(.medium))

                loadingDots
            }
            .foregroundStyle(Color.roostMutedForeground)
            .accessibilityLabel("Loading")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.roostBackground)
        .onAppear {
            guard !reduceMotion else { return }
            breathe = true
            rotatePrimary = true
            rotateSecondary = true
            dotPhase = true
        }
    }

    private var logoStage: some View {
        ZStack {
            Circle()
                .stroke(Color.roostPrimary.opacity(0.10), lineWidth: 1)
                .frame(width: logoSize + 54, height: logoSize + 54)
                .scaleEffect(reduceMotion ? 1 : (breathe ? 1.08 : 0.92))
                .opacity(reduceMotion ? 1 : (breathe ? 0.35 : 0.75))

            Circle()
                .trim(from: 0.08, to: 0.34)
                .stroke(
                    Color.roostPrimary.opacity(0.72),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: logoSize + 38, height: logoSize + 38)
                .rotationEffect(.degrees(rotatePrimary ? 360 : 0))

            Circle()
                .trim(from: 0.58, to: 0.78)
                .stroke(
                    Color.roostSecondary.opacity(0.65),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: logoSize + 24, height: logoSize + 24)
                .rotationEffect(.degrees(rotateSecondary ? -360 : 0))

            RoostLogoMark(size: logoSize)
                .scaleEffect(reduceMotion ? 1 : (breathe ? 1.035 : 0.965))
                .shadow(color: Color.roostPrimary.opacity(0.18), radius: breathe ? 18 : 8, y: breathe ? 8 : 3)
        }
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 1.45).repeatForever(autoreverses: true),
            value: breathe
        )
        .animation(
            reduceMotion ? nil : .linear(duration: 1.35).repeatForever(autoreverses: false),
            value: rotatePrimary
        )
        .animation(
            reduceMotion ? nil : .linear(duration: 2.1).repeatForever(autoreverses: false),
            value: rotateSecondary
        )
    }

    private var loadingDots: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                Text(".")
                    .font(.roostBody.weight(.medium))
                    .opacity(reduceMotion ? 1 : (dotPhase ? 1 : 0.25))
                    .offset(y: reduceMotion ? 0 : (dotPhase ? -2 : 2))
                    .animation(
                        reduceMotion
                            ? nil
                            : .easeInOut(duration: 0.72)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.14),
                        value: dotPhase
                    )
            }
        }
        .frame(width: 18, alignment: .leading)
    }
}
