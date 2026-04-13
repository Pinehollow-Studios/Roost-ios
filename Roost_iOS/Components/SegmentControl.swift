import SwiftUI

struct SegmentControl: View {
    let options: [String]
    @Binding var selection: String

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(options, id: \.self) { option in
                Button(option) {
                    selection = option
                }
                .buttonStyle(.plain)
                .font(.roostLabel)
                .foregroundStyle(selection == option ? Color.roostForeground : Color.roostMutedForeground)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .background(selection == option ? Color.roostSurfaceRaised : Color.clear, in: Capsule())
                .contentShape(Capsule())
            }
        }
        .padding(4)
        .background(Color.roostMuted.opacity(0.65), in: Capsule())
    }
}
