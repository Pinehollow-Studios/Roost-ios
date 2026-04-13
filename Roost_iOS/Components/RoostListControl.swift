import SwiftUI

struct RoostListControl: View {
    enum State {
        case idle
        case selected
        case status
    }

    let state: State
    var tint: Color = .roostPrimary
    var symbol: String = "checkmark"
    var size: CGFloat = 44
    var pulse: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .fill(baseGradient)

            Circle()
                .strokeBorder(ringColor, lineWidth: state == .selected ? 0 : 1.2)

            Circle()
                .fill(innerWash)
                .padding(3)

            Circle()
                .strokeBorder(highlightStroke, lineWidth: 1)
                .padding(2.5)
                .blendMode(.screen)

            if state == .selected {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.28), Color.clear],
                            center: .topLeading,
                            startRadius: 2,
                            endRadius: size * 0.42
                        )
                    )
                    .padding(4)

                Image(systemName: symbol)
                    .font(.system(size: size * 0.34, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .transition(.scale(scale: 0.65).combined(with: .opacity))
            } else {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.28, weight: .semibold, design: .rounded))
                    .foregroundStyle(iconColor)
                    .opacity(state == .idle ? 0.55 : 0.88)
            }
        }
        .frame(width: size, height: size)
        .overlay {
            if pulse && state == .selected {
                Circle()
                    .stroke(tint.opacity(0.22), lineWidth: 10)
                    .scaleEffect(reduceMotion ? 1 : 1.14)
                    .opacity(reduceMotion ? 0 : 1)
                    .blur(radius: 2)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.28), value: pulse)
            }
        }
        .shadow(color: shadowColor, radius: state == .selected ? 18 : 10, x: 0, y: state == .selected ? 8 : 4)
        .scaleEffect(state == .selected ? 1 : 0.985)
        .animation(reduceMotion ? nil : .roostSpring, value: state == .selected)
        .accessibilityHidden(true)
    }

    private var baseGradient: some ShapeStyle {
        switch state {
        case .selected:
            return LinearGradient(
                colors: [tint.opacity(0.92), tint, tint.opacity(0.84)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .status:
            return LinearGradient(
                colors: [tint.opacity(0.22), tint.opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .idle:
            return LinearGradient(
                colors: [Color.roostSurfaceRaised, Color.roostSurface, Color.roostMuted.opacity(0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var innerWash: some ShapeStyle {
        LinearGradient(
            colors: [
                Color.white.opacity(state == .selected ? 0.08 : 0.34),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var highlightStroke: Color {
        state == .selected ? Color.white.opacity(0.18) : Color.white.opacity(0.5)
    }

    private var ringColor: Color {
        switch state {
        case .selected:
            return .clear
        case .status:
            return tint.opacity(0.16)
        case .idle:
            return Color.roostForeground.opacity(0.09)
        }
    }

    private var iconColor: Color {
        switch state {
        case .selected:
            return .white
        case .status:
            return tint
        case .idle:
            return Color.roostMutedForeground
        }
    }

    private var shadowColor: Color {
        switch state {
        case .selected:
            return tint.opacity(0.26)
        case .status:
            return tint.opacity(0.12)
        case .idle:
            return Color.roostShadow.opacity(0.24)
        }
    }
}
