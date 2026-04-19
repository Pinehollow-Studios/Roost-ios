import SwiftUI

/// Horizontal progress bar per design-system spec (`components-progress.html`).
/// - 8pt tall track / fill (was 10pt).
/// - Track = `--muted` at full opacity.
/// - Fill colour is **passed in** by the caller — always the relevant feature tint
///   (Money/Shopping/Chores/Primary). The old threshold-based traffic-light palette
///   violated the DS rule that progress colour communicates *context*, not value.
struct ProgressBarView: View {
    let progress: Double
    /// Feature-tinted fill. Defaults to primary terracotta; callers should pass the
    /// appropriate `.roostMoneyTint` / `.roostShoppingTint` / `.roostChoreTint` etc.
    var fill: Color = .roostPrimary

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.roostMuted)
                Capsule()
                    .fill(fill)
                    .frame(width: geometry.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 8)
        .animation(.roostEaseOut, value: progress)
    }
}

/// Circular progress ring per design-system spec (`components-progress.html`).
/// - 92×92 default, 8pt stroke, round line-caps.
/// - Track = `--muted`, fill = feature tint passed by caller.
/// - Starts at 12 o'clock and sweeps clockwise.
struct RoostProgressRing: View {
    let progress: Double
    var fill: Color = .roostPrimary
    var diameter: CGFloat = 92
    var lineWidth: CGFloat = 8

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.roostMuted, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    fill,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.roostEaseOut, value: progress)
        }
        .frame(width: diameter, height: diameter)
    }
}
