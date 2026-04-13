import SwiftUI

struct GoogleMark: View {
    var size: CGFloat = DesignSystem.Size.icon
    private let lineWidthRatio: CGFloat = 0.22

    var body: some View {
        ZStack {
            googleSegment(color: Color(hex: 0xEA4335), start: 0.38, end: 0.64)
            googleSegment(color: Color(hex: 0xFBBC05), start: 0.64, end: 0.84)
            googleSegment(color: Color(hex: 0x34A853), start: 0.84, end: 1.0)
            googleSegment(color: Color(hex: 0x4285F4), start: 0.0, end: 0.38)

            Rectangle()
                .fill(Color.white)
                .frame(width: size * 0.3, height: size * 0.4)
                .offset(x: size * 0.2)

            Rectangle()
                .fill(Color(hex: 0x4285F4))
                .frame(width: size * 0.38, height: size * lineWidthRatio)
                .offset(x: size * 0.17)
        }
        .frame(width: size, height: size)
    }

    private func googleSegment(color: Color, start: CGFloat, end: CGFloat) -> some View {
        Circle()
            .trim(from: start, to: end)
            .stroke(color, style: StrokeStyle(lineWidth: size * lineWidthRatio, lineCap: .butt))
            .rotationEffect(.degrees(-90))
    }
}
