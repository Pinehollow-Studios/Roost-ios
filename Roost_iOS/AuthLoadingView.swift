//
//  AuthLoadingView.swift
//  Roost
//
//  One-shot auth/login loading moment. Plays ~4s, then holds final state.
//  See handoff/LoadingScreens.md for full spec.
//

import SwiftUI
import Combine

struct AuthLoadingView: View {
    var onComplete: (() -> Void)? = nil
    var speedMultiplier: Double = 1.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Animation state
    @State private var sunIn = false
    @State private var horizon1: CGFloat = 0
    @State private var horizon2: CGFloat = 0
    @State private var iconIn = false
    @State private var shimmerX: CGFloat = 1.2
    @State private var shimmerOpacity: Double = 0
    @State private var breezeX: CGFloat = -0.4
    @State private var breezeOpacity: Double = 0
    @State private var letters: [Bool] = Array(repeating: false, count: 5)
    @State private var taglineIn = false
    @State private var statusIn = false
    @State private var statusIdx = 0
    @State private var progressX: CGFloat = -0.4

    private let statuses = ["Unlocking your home", "Gathering the nest", "Almost there"]
    private let statusTimer = Timer.publish(every: 1.8, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // 1 — shared midnight-to-dawn gradient (identical view type in
            // LoadingView / LockScreenView / AuthLoadingView so transitions
            // between them read as one continuous background).
            DawnBackground()

            // 2 — sun glow
            GeometryReader { geo in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: 0xFFD7AA).opacity(0.92),
                                Color(hex: 0xFFB482).opacity(0.45),
                                .clear
                            ],
                            center: .center, startRadius: 0, endRadius: 210
                        )
                    )
                    .frame(width: 420, height: 420)
                    .blur(radius: 6)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.72 + 210)
                    .scaleEffect(sunIn ? 1.0 : 0.6)
                    .opacity(sunIn ? 1.0 : 0)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // 3 — horizon arcs
            GeometryReader { geo in
                let y = geo.size.height * 0.61
                HorizonArc()
                    .trim(from: 0, to: horizon1)
                    .stroke(Color(hex: 0xE07A5F),
                            style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    .frame(width: geo.size.width + 40, height: 80)
                    .position(x: geo.size.width / 2, y: y)

                HorizonArc()
                    .trim(from: 0, to: horizon2)
                    .stroke(Color(hex: 0xE07A5F).opacity(0.5),
                            style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
                    .frame(width: geo.size.width + 40, height: 80)
                    .position(x: geo.size.width / 2, y: y + 12)
            }
            .allowsHitTesting(false)

            // 4 — sage breeze (single pass)
            GeometryReader { geo in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, DesignSystem.Palette.secondaryInteractive, .clear],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * 1.8, height: 2)
                    .rotationEffect(.degrees(-6))
                    .offset(x: geo.size.width * breezeX, y: geo.size.height * 0.38)
                    .opacity(breezeOpacity * 0.6)
            }
            .allowsHitTesting(false)

            // 5 — icon + wordmark + tagline stack
            VStack(spacing: 0) {
                Spacer()

                // icon
                ZStack {
                    Image("RoostIcon")
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .shadow(color: Color(hex: 0x8B3A1E).opacity(0.50), radius: 24, y: 18)
                        .shadow(color: Color(hex: 0x8B3A1E).opacity(0.32), radius: 8, y: 4)

                    // one-time shimmer sweep
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0.4),
                                    .init(color: Color(hex: 0xFFF8F0).opacity(0.7), location: 0.5),
                                    .init(color: .clear, location: 0.6),
                                ],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: 96, height: 96)
                        .offset(x: shimmerX * 120)
                        .opacity(shimmerOpacity)
                        .blendMode(.overlay)
                        .mask(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .frame(width: 96, height: 96)
                        )
                }
                .opacity(iconIn ? 1.0 : 0)
                .scaleEffect(iconIn ? 1.0 : 0.82)
                .offset(y: iconIn ? 0 : 24)
                .blur(radius: iconIn ? 0 : 6)
                .padding(.bottom, 22)

                // wordmark
                HStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { i in
                        Text(String(["R", "o", "o", "s", "t"][i]))
                            .font(.custom("DMSans-Bold", size: 32))
                            .tracking(-0.6)
                            .foregroundStyle(DesignSystem.Palette.foreground)
                            .opacity(letters[i] ? 1 : 0)
                            .offset(y: letters[i] ? 0 : -18)
                    }
                }
                .padding(.bottom, 10)

                // tagline
                Text("your home, together")
                    .font(.custom("DMSans-Regular", size: 13))
                    .tracking(0.3)
                    .foregroundStyle(DesignSystem.Palette.foreground.opacity(0.62))
                    .opacity(taglineIn ? 1 : 0)
                    .offset(y: taglineIn ? 0 : 6)

                Spacer()
                Spacer()   // push the stack above horizon
            }

            // 6 — status + progress at bottom
            VStack(spacing: 14) {
                ZStack {
                    ForEach(Array(statuses.enumerated()), id: \.offset) { idx, s in
                        Text(s)
                            .font(.custom("DMSans-Medium", size: 12))
                            .tracking(0.6)
                            .textCase(.uppercase)
                            .foregroundStyle(DesignSystem.Palette.foreground.opacity(0.55))
                            .opacity(idx == statusIdx ? 1 : 0)
                            .animation(.easeOut(duration: 0.45), value: statusIdx)
                    }
                }
                .frame(minHeight: 16)

                // progress track
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(hex: 0xE07A5F).opacity(0.28))
                        .frame(width: 120, height: 2)
                    Capsule().fill(Color(hex: 0xE07A5F))
                        .frame(width: 48, height: 2)
                        .offset(x: progressX * 120)
                }
                .frame(width: 120)
                .clipShape(Capsule())
            }
            .opacity(statusIn ? 1 : 0)
            .offset(y: statusIn ? 0 : 8)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 72)
        }
        .onAppear { startSequence() }
        .onReceive(statusTimer) { _ in
            statusIdx = (statusIdx + 1) % statuses.count
        }
    }

    private func startSequence() {
        guard !reduceMotion else {
            // accessibility: cross-fade final state in 0.4s
            withAnimation(.easeOut(duration: 0.4)) {
                sunIn = true; iconIn = true; taglineIn = true; statusIn = true
                letters = Array(repeating: true, count: 5)
                horizon1 = 1; horizon2 = 1
            }
            return
        }

        let s = speedMultiplier

        // sun glow in — 2.6s, 0.1s delay
        withAnimation(.easeOut(duration: 2.6 / s).delay(0.1 / s)) { sunIn = true }

        // horizon draws
        withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 1.2 / s).delay(0.1 / s)) { horizon1 = 1 }
        withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 1.3 / s).delay(0.2 / s)) { horizon2 = 1 }

        // icon rise (0.8s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8 / s) {
            withAnimation(.interpolatingSpring(mass: 0.8, stiffness: 120, damping: 14)) {
                iconIn = true
            }
        }

        // sage breeze (1.1s delay, 2.0s ease)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1 / s) {
            breezeOpacity = 1
            withAnimation(.easeInOut(duration: 2.0 / s)) {
                breezeX = 0.4
                breezeOpacity = 0
            }
        }

        // shimmer (1.5s delay, 0.9s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5 / s) {
            shimmerOpacity = 1
            withAnimation(.easeOut(duration: 0.9 / s)) {
                shimmerX = -1.2
                shimmerOpacity = 0
            }
        }

        // wordmark letters
        for i in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + (1.6 + Double(i) * 0.05) / s) {
                withAnimation(.interpolatingSpring(mass: 0.5, stiffness: 160, damping: 14)) {
                    letters[i] = true
                }
            }
        }

        // tagline
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9 / s) {
            withAnimation(.easeOut(duration: 0.5 / s)) { taglineIn = true }
        }

        // status + progress
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1 / s) {
            withAnimation(.easeOut(duration: 0.4 / s)) { statusIn = true }
            withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 1.8 / s).repeatForever(autoreverses: false)) {
                progressX = 1.0
            }
        }

        // fire completion callback after the sequence finishes (~2.7s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.7 / s) {
            onComplete?()
        }
    }
}

// Shallow smile arc across the width
private struct HorizonArc: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.midY))
        p.addQuadCurve(
            to: CGPoint(x: rect.width, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.midY - 30)
        )
        return p
    }
}

#Preview {
    AuthLoadingView()
}
