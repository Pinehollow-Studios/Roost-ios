import SwiftUI

struct RoostLogoMark: View {
    var size: CGFloat = DesignSystem.Size.authLogoMark
    var cornerRadius: CGFloat = DesignSystem.Radius.md

    var body: some View {
        Image("RoostIcon")
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fill)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
