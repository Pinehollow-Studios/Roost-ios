import SwiftUI

struct FigmaFloatingActionButton: View {
    let systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.roostWarmWhite)
                .frame(width: 56, height: 56)
                .background(Color.roostPrimary, in: Circle())
                .shadow(
                    color: DesignSystem.Shadow.fabColor,
                    radius: DesignSystem.Shadow.fabRadius,
                    x: 0,
                    y: DesignSystem.Shadow.fabYOffset
                )
        }
        .buttonStyle(.plain)
    }
}
