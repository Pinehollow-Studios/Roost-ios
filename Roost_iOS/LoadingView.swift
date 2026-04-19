//
//  LoadingView.swift
//  Roost
//
//  General-purpose loading screen. Loops indefinitely.
//  See handoff/LoadingScreens.md for full spec.
//

import SwiftUI
import Combine

struct LoadingView: View {
    var statusText: String = "Settling in"
    var speedMultiplier: Double = 1.0
    /// When true, renders the shared dawn gradient (same as AuthLoadingView / LockScreenView)
    /// so the full auth flow shares one consistent background. DawnBackground is itself
    /// adaptive — light mode renders a warm-sand sky, dark mode renders pre-dawn night.
    var isDawn: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var dotCount = 1
    @State private var breathe = false
    @State private var halo = false
    @State private var lightOffset: CGFloat = -1.0    // -1 (above) → 1 (below)
    @State private var wispOffset: CGFloat = -0.4     // -0.4 → 0.3
    @State private var wispOpacity: Double = 0

    /// True when the current system scheme is dark. Used to tint internal effects
    /// (window-light shaft, icon shadow). The dawn background itself is adaptive
    /// via `DawnBackground`, so we no longer force-dark on `isDawn`.
    private var isEffectivelyDark: Bool { colorScheme == .dark }

    private let dotTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // 1 — background as the FIRST child of the ZStack, not a `.background`
            // modifier. That way animated @State in the foreground layers below
            // never causes the gradient view to be rebuilt / re-transitioned.
            if isDawn {
                DawnBackground()
            } else {
                RadialGradient(
                    colors: isEffectivelyDark
                        ? [Color(hex: 0x1A1816), Color(hex: 0x0F0D0B), Color(hex: 0x0A0908)]
                        : [Color(hex: 0xF4ECDD), Color(hex: 0xEBE3D5), Color(hex: 0xE0D6C4)],
                    center: UnitPoint(x: 0.5, y: 0.38),
                    startRadius: 0, endRadius: 520
                )
                .ignoresSafeArea()
            }

            // 2 — grain (keep simple; swap for a tiled noise image if you have one)
            // NoiseOverlay().opacity(0.05).blendMode(.overlay)

            // 3 — window-light shaft
            if !reduceMotion {
                GeometryReader { geo in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: isEffectivelyDark
                                    ? [
                                        .clear,
                                        Color(hex: 0xC86A50).opacity(0.10),
                                        Color(hex: 0xD4795E).opacity(0.16),
                                        Color(hex: 0xC86A50).opacity(0.10),
                                        .clear
                                    ]
                                    : [
                                        .clear,
                                        Color(hex: 0xFFEDD2).opacity(0.65),
                                        Color(hex: 0xFFF5E1).opacity(0.85),
                                        Color(hex: 0xFFEDD2).opacity(0.65),
                                        .clear
                                    ],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * 1.8, height: 160)
                        .blur(radius: 18)
                        .rotationEffect(.degrees(-18))
                        .offset(y: geo.size.height * lightOffset)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 4.0 / speedMultiplier).repeatForever(autoreverses: false)) {
                                lightOffset = 1.2
                            }
                        }
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            // 4 — sage wisp (behind icon)
            if !reduceMotion {
                GeometryReader { geo in
                    SageWispPath()
                        .stroke(DesignSystem.Palette.secondaryInteractive.opacity(0.32),
                                style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
                        .frame(width: geo.size.width * 1.6, height: 240)
                        .offset(x: geo.size.width * wispOffset, y: geo.size.height * 0.3)
                        .opacity(wispOpacity)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 6.0 / speedMultiplier).repeatForever(autoreverses: false)) {
                                wispOffset = 0.3
                                wispOpacity = 0.32
                            }
                        }
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            // 5 — halo + 6 — icon
            VStack(spacing: 40) {
                ZStack {
                    // halo
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [DesignSystem.Palette.primary.opacity(0.14), .clear],
                                center: .center, startRadius: 0, endRadius: 140
                            )
                        )
                        .frame(width: 280, height: 280)
                        .blur(radius: 8)
                        .scaleEffect(halo ? 1.04 : 0.96)

                    // actual app icon — never redraw
                    Image("RoostIcon")
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 108, height: 108)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: Color(hex: 0x8B3A1E).opacity(isEffectivelyDark ? 0.36 : 0.16), radius: 20, y: 18)
                        .shadow(color: Color(hex: 0x8B3A1E).opacity(isEffectivelyDark ? 0.20 : 0.08), radius: 6, y: 2)
                        .scaleEffect(breathe ? 1.025 : 1.0)
                }

                // 7 — status line
                HStack(spacing: 1) {
                    Text(statusText)
                    Text(String(repeating: ".", count: dotCount))
                        .frame(width: 18, alignment: .leading)
                }
                .font(.custom("DMSans-Regular", size: 14))
                .tracking(0.2)
                .foregroundStyle(DesignSystem.Palette.mutedForeground)
                .opacity(breathe ? 1.0 : 0.62)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.5 / speedMultiplier).repeatForever(autoreverses: true)) {
                breathe = true
                halo = true
            }
        }
        .onReceive(dotTimer) { _ in
            dotCount = (dotCount % 3) + 1
        }
    }
}

// Wisp path — two quadratic curves, close to the CSS version
private struct SageWispPath: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let y = rect.midY
        p.move(to: CGPoint(x: 0, y: y))
        p.addQuadCurve(to: CGPoint(x: rect.width * 0.375, y: y),
                       control: CGPoint(x: rect.width * 0.1875, y: y - 80))
        p.addQuadCurve(to: CGPoint(x: rect.width * 0.75, y: y),
                       control: CGPoint(x: rect.width * 0.5625, y: y + 80))
        p.addQuadCurve(to: CGPoint(x: rect.width, y: y),
                       control: CGPoint(x: rect.width * 0.875, y: y - 80))
        return p
    }
}

#Preview {
    LoadingView()
}

#Preview("Dawn style") {
    LoadingView(statusText: "Restoring session", isDawn: true)
}
