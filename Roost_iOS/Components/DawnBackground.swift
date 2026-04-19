import SwiftUI

/// Shared midnight-to-dawn gradient used across the entire auth + loading flow:
/// first loading → lock screen → auth loading. Keeping the exact same view type,
/// stops, and orientation in every screen means a re-mount between them reads as
/// a single continuous background rather than a cross-fade of two similar ones.
///
/// Stops match `colors_and_type.css` / `LockScreenView` verbatim:
///   0.00  #0F0D0B  deep midnight
///   0.40  #1A1410  dark brown
///   0.75  #2A1A12  medium brown
///   1.00  #D4795E  terracotta sunset
struct DawnBackground: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color(hex: 0x0F0D0B), location: 0.0),
                .init(color: Color(hex: 0x1A1410), location: 0.4),
                .init(color: Color(hex: 0x2A1A12), location: 0.75),
                .init(color: Color(hex: 0xD4795E), location: 1.0),
            ],
            startPoint: UnitPoint(x: 0.5, y: -0.08),
            endPoint: UnitPoint(x: 0.5, y: 1.0)
        )
        .ignoresSafeArea()
    }
}

#Preview {
    DawnBackground()
}
