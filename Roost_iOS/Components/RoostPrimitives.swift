import SwiftUI

// MARK: - Icon container
// -------------------------------------------------------------------------------------------------
// Feature-tinted circular icon container per design-ethos §193 (`README.md §193`):
//   30pt — row leading icons (in lists, inline badges)
//   42pt — section-header icons
//   56pt — setup / onboarding / hero moments
// Fill is always feature tint at 10–13% opacity; icon is feature tint at full opacity.

struct RoostIconContainer: View {
    enum Size {
        case row
        case section
        case setup
        case custom(CGFloat, iconSize: CGFloat)

        var dimension: CGFloat {
            switch self {
            case .row:            return 30
            case .section:        return 42
            case .setup:          return 56
            case .custom(let d, _): return d
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .row:            return 14
            case .section:        return 20
            case .setup:          return 28
            case .custom(_, let i): return i
            }
        }
    }

    let systemImage: String
    var tint: Color = .roostPrimary
    var size: Size = .row
    var fillOpacity: Double = 0.12

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(fillOpacity))
            Image(systemName: systemImage)
                .font(.system(size: size.iconSize, weight: .regular))
                .foregroundStyle(tint)
        }
        .frame(width: size.dimension, height: size.dimension)
    }
}

// MARK: - Grain overlay
// -------------------------------------------------------------------------------------------------
// Subtle procedural noise applied on top of `.roost-material` surfaces per
// `colors_and_type.css §153 + §249-263`. 3–6% opacity; 8% on Pro surfaces.
// SwiftUI has no direct SVG fractal-noise equivalent — we approximate with a
// Canvas blending thousands of tiny random rectangles. Cached per size via
// `drawingGroup()` so there's no per-frame CPU hit.

struct RoostGrainOverlay: View {
    /// Grain opacity. DS spec: 0.06 standard, 0.08 on Pro dark surfaces.
    var opacity: Double = 0.06
    /// Seed controls the stable pattern; same seed → same grain.
    var seed: UInt64 = 42

    var body: some View {
        Canvas { context, size in
            var rng = SplitMix64(seed: seed)
            let dots = Int(size.width * size.height / 18)  // ≈1 dot per 18pt²
            for _ in 0..<dots {
                let x = rng.nextDouble() * size.width
                let y = rng.nextDouble() * size.height
                let alpha = rng.nextDouble() * 0.6 + 0.2
                let rect = CGRect(x: x, y: y, width: 1, height: 1)
                context.fill(
                    Path(rect),
                    with: .color(Color(white: 0.5, opacity: alpha))
                )
            }
        }
        .opacity(opacity)
        .allowsHitTesting(false)
        .blendMode(.overlay)
        .drawingGroup()
    }
}

/// Deterministic PRNG so the grain pattern is stable across frames / relayouts.
private struct SplitMix64 {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
    mutating func nextDouble() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }
}

extension View {
    /// Apply the Roost grain overlay — 6% default, matching `.roost-material`.
    func roostGrain(opacity: Double = 0.06) -> some View {
        overlay(RoostGrainOverlay(opacity: opacity))
    }
}

// MARK: - Entrance stagger
// -------------------------------------------------------------------------------------------------
// Opacity 0→1, y +18→0, optional scale 0.98→1.0, staggered 0.04s per item
// (max 6 items before collapsing to immediate). Per README §135.

struct RoostEntranceModifier: ViewModifier {
    let index: Int
    let total: Int
    let includeScale: Bool
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var delay: Double {
        guard total > 1 else { return 0 }
        // Collapse to immediate past 6 items.
        if total > 6 { return 0 }
        return Double(index) * 0.04
    }

    func body(content: Content) -> some View {
        content
            .opacity(reduceMotion || appeared ? 1 : 0)
            .offset(y: reduceMotion || appeared ? 0 : 18)
            .scaleEffect(
                includeScale && !reduceMotion && !appeared ? 0.98 : 1,
                anchor: .center
            )
            .onAppear {
                if reduceMotion {
                    appeared = true
                } else {
                    withAnimation(DesignSystem.Motion.listAppear.delay(delay)) {
                        appeared = true
                    }
                }
            }
    }
}

extension View {
    /// Staggered entrance — opacity, slide-up, optional scale. Index / total control
    /// the delay. Pass `total: 1` for a one-off entrance without stagger.
    func roostEntrance(index: Int = 0, total: Int = 1, includeScale: Bool = true) -> some View {
        modifier(RoostEntranceModifier(index: index, total: total, includeScale: includeScale))
    }
}

// MARK: - Frosted-glass auth card
// -------------------------------------------------------------------------------------------------
// Per `README.md §157`: "Frosted glass is reserved for auth-flow form cards:
// card at 88% + 1px white border @ 7%." Available as a modifier so any auth
// view can opt into the treatment.

struct RoostAuthCardModifier: ViewModifier {
    var padding: CGFloat = DesignSystem.Spacing.cardLarge

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: RoostTheme.cardCornerRadius, style: .continuous)
                    .fill(Color.roostCard.opacity(0.88))
                    .background(.ultraThinMaterial, in: RoundedRectangle(
                        cornerRadius: RoostTheme.cardCornerRadius,
                        style: .continuous
                    ))
            )
            .overlay(
                RoundedRectangle(cornerRadius: RoostTheme.cardCornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
            )
            .shadow(
                color: DesignSystem.Shadow.cardColor,
                radius: DesignSystem.Shadow.cardRadius,
                x: 0,
                y: DesignSystem.Shadow.cardYOffset
            )
    }
}

extension View {
    /// Apply the frosted-glass auth-form card treatment — card at 88% + ultraThin
    /// material + 1pt white-at-7% border. Reserved for auth flows.
    func roostAuthCard(padding: CGFloat = DesignSystem.Spacing.cardLarge) -> some View {
        modifier(RoostAuthCardModifier(padding: padding))
    }
}

// MARK: - Tabular numerals helper
// -------------------------------------------------------------------------------------------------
// DS: `.roost-tabular { font-variant-numeric: tabular-nums }` for all money/stats.
// SwiftUI ships `.monospacedDigit()` for exactly this.

extension Text {
    /// Force tabular-figures numerals so money columns align. Per
    /// `colors_and_type.css §226` + `§230`.
    func roostTabular() -> Text {
        self.monospacedDigit()
    }
}
