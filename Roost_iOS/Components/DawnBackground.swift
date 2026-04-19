import SwiftUI

/// Shared dawn-sky gradient used across the auth + loading flow (first loading →
/// lock screen → auth loading → welcome/signup/join/setup). Keeping the exact
/// same view type in every screen means a re-mount between them reads as a
/// single continuous background rather than a cross-fade of two similar ones.
///
/// Both schemes share the terracotta horizon (`#D4795E` at 1.0) so the warm
/// sunrise band is consistent. The top of the gradient matches each scheme's
/// `roostBackground` tone, which keeps cards, buttons and other surfaces
/// visually grounded in the app's theme — light mode feels like dawn sky at
/// ground level, dark mode feels like pre-dawn night.
///
/// Light stops
///   0.00  #EBE3D5  warm cream (matches `roostBackground`, light)
///   0.40  #EBD9C2  soft sand
///   0.75  #ECC39F  peach haze
///   1.00  #D4795E  terracotta sunrise
///
/// Dark stops
///   0.00  #0F0D0B  deep midnight (matches `roostBackground`, dark)
///   0.40  #1A1410  dark brown
///   0.75  #2A1A12  medium brown
///   1.00  #D4795E  terracotta sunrise
struct DawnBackground: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color(light: 0xEBE3D5, dark: 0x0F0D0B), location: 0.0),
                .init(color: Color(light: 0xEBD9C2, dark: 0x1A1410), location: 0.4),
                .init(color: Color(light: 0xECC39F, dark: 0x2A1A12), location: 0.75),
                .init(color: Color(light: 0xD4795E, dark: 0xD4795E), location: 1.0),
            ],
            startPoint: UnitPoint(x: 0.5, y: -0.08),
            endPoint: UnitPoint(x: 0.5, y: 1.0)
        )
        .ignoresSafeArea()
    }
}

#Preview("Dawn — system") {
    DawnBackground()
}

#Preview("Dawn — light") {
    DawnBackground()
        .preferredColorScheme(.light)
}

#Preview("Dawn — dark") {
    DawnBackground()
        .preferredColorScheme(.dark)
}
