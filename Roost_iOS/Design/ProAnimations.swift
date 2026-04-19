import SwiftUI

// MARK: - Pro Badge

/// Inline gradient capsule badge used wherever a feature is Pro-gated.
/// Replaces all "Roost Pro only" / crown label patterns.
struct ProBadge: View {
    @State private var shimmerPhase: CGFloat = -1.0

    var body: some View {
        ZStack {
            // Gradient fill
            DesignSystem.ProPalette.gradientH

            // Shimmer sweep
            LinearGradient(
                stops: [
                    .init(color: .clear, location: shimmerPhase - 0.3),
                    .init(color: Color.proWarmWhite.opacity(0.30), location: shimmerPhase),
                    .init(color: .clear, location: shimmerPhase + 0.3)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

            Text("Pro")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.proWarmWhite)
                .tracking(0.3)
        }
        .frame(height: 20)
        .padding(.horizontal, 8)
        .clipShape(Capsule())
        .onAppear {
            withAnimation(.linear(duration: 2.8).repeatForever(autoreverses: false).delay(Double.random(in: 0...1.5))) {
                shimmerPhase = 2.0
            }
        }
    }
}

// MARK: - Pro Shimmer Modifier

/// Shimmer sweep effect — applied to any gradient surface (CTA button, hero).
struct ProShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1.0

    func body(content: Content) -> some View {
        content.overlay(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: phase - 0.3),
                    .init(color: Color.proWarmWhite.opacity(0.35), location: phase),
                    .init(color: .clear, location: phase + 0.3)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .onAppear {
                withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false).delay(0.5)) {
                    phase = 2.0
                }
            }
        )
    }
}

extension View {
    func proShimmer() -> some View {
        modifier(ProShimmerModifier())
    }
}

// MARK: - Pro Glow Modifier

/// Glow Breathe — ambient radial aura that expands and fades behind the sparkles icon.
struct ProGlowModifier: ViewModifier {
    @State private var pulsing = false

    func body(content: Content) -> some View {
        content.background(
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.proAmber.opacity(pulsing ? 0.04 : 0.22), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 55
                    )
                )
                .scaleEffect(pulsing ? 1.45 : 0.85)
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                        pulsing = true
                    }
                }
        )
    }
}

extension View {
    func proGlow() -> some View {
        modifier(ProGlowModifier())
    }
}

// MARK: - Pro Aurora Background

/// Aurora Drift — three colour blobs that drift independently, creating warm ambient light.
/// Used as a `.background` on Pro hero sections.
struct ProAuroraBackground: View {
    @State private var phaseA = false
    @State private var phaseB = false
    @State private var phaseC = false

    var body: some View {
        ZStack {
            Color.proBg

            // Blob A — deep burn, slow drift left-right
            Circle()
                .fill(Color.proDeepBurn.opacity(0.30))
                .frame(width: 200, height: 200)
                .blur(radius: 80)
                .offset(x: phaseA ? 60 : -60, y: -40)
                .onAppear {
                    withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                        phaseA = true
                    }
                }

            // Blob B — amber, slow drift top-bottom
            Circle()
                .fill(Color.proAmber.opacity(0.22))
                .frame(width: 280, height: 160)
                .blur(radius: 100)
                .offset(x: 20, y: phaseB ? 40 : -40)
                .onAppear {
                    withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true).delay(1.5)) {
                        phaseB = true
                    }
                }

            // Blob C — champagne, diagonal drift
            Circle()
                .fill(Color.proChampagne.opacity(0.14))
                .frame(width: 180, height: 180)
                .blur(radius: 60)
                .offset(x: phaseC ? -40 : 40, y: phaseC ? -10 : -50)
                .onAppear {
                    withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true).delay(0.8)) {
                        phaseC = true
                    }
                }
        }
        .clipped()
    }
}

// MARK: - Pro Particle Burst

/// Upgrade success particle burst — 16 amber/champagne particles radiate from centre.
/// Plays once on appear; use triggered with a flag.
struct ProParticleBurst: View {
    let trigger: Bool

    private struct Particle: Identifiable {
        let id = UUID()
        let angle: Double
        let distance: CGFloat
        let size: CGFloat
        let color: Color
        let duration: Double
    }

    private let particles: [Particle] = (0..<16).map { i in
        Particle(
            angle: Double(i) * (360.0 / 16.0) + Double.random(in: -12...12),
            distance: CGFloat.random(in: 40...90),
            size: CGFloat.random(in: 3...5),
            color: Bool.random() ? .proAmber : .proChampagne,
            duration: Double.random(in: 0.7...1.1)
        )
    }

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                Circle()
                    .fill(p.color)
                    .frame(width: p.size, height: p.size)
                    .offset(
                        x: trigger ? p.distance * CGFloat(cos(p.angle * .pi / 180)) : 0,
                        y: trigger ? p.distance * CGFloat(sin(p.angle * .pi / 180)) : 0
                    )
                    .opacity(trigger ? 0 : 1)
                    .scaleEffect(trigger ? 0 : 1)
                    .animation(
                        trigger ? .easeOut(duration: p.duration) : .none,
                        value: trigger
                    )
            }
        }
    }
}

// MARK: - Pro Lock Pill

/// Capsule pill used on locked data (e.g. "3 months locked" on spending trend).
struct ProLockPill: View {
    let label: String
    @State private var shimmerPhase: CGFloat = -1.0

    var body: some View {
        ZStack {
            DesignSystem.ProPalette.gradientH

            LinearGradient(
                stops: [
                    .init(color: .clear, location: shimmerPhase - 0.3),
                    .init(color: Color.proWarmWhite.opacity(0.28), location: shimmerPhase),
                    .init(color: .clear, location: shimmerPhase + 0.3)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 9, weight: .semibold))
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(Color.proWarmWhite)
        }
        .frame(height: 22)
        .padding(.horizontal, 10)
        .clipShape(Capsule())
        .onAppear {
            withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false).delay(0.4)) {
                shimmerPhase = 2.0
            }
        }
    }
}

// MARK: - Pro Gradient Text

/// Applies the Pro gradient as a foreground style to a text view.
extension View {
    func proGradientForeground() -> some View {
        self.overlay(DesignSystem.ProPalette.gradientH)
            .mask(self)
    }
}
