import SwiftUI

struct FigmaFloatingActionButton: View {
    let systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.roostCard)
                .frame(width: 56, height: 56)
                .background(Color.roostPrimary, in: Circle())
                .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}
