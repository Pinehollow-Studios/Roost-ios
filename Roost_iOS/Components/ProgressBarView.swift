import SwiftUI

struct ProgressBarView: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.roostMuted.opacity(0.75))
                Capsule()
                    .fill(fillColor)
                    .frame(width: geometry.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 10)
        .animation(.roostEaseOut, value: progress)
    }

    private var fillColor: Color {
        if progress < 0.6 { return .roostSuccess }
        if progress < 0.8 { return Color.roostWarning.opacity(0.7) }
        if progress < 1 { return .roostWarning }
        return .roostDestructive
    }
}
