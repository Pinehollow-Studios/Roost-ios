import SwiftUI

/// Subtle indicator for list rows that have an un-synced offline mutation.
/// Rendered next to the row title (or wherever the view model lays it out)
/// whenever the backing cached model has `isDirty == true`.
///
/// Intentionally small and unobtrusive — modelled on Splitwise's pending chip
/// and Apple Reminders' sync dot. Use `accessibilityLabel` to describe the
/// state to VoiceOver users.
struct PendingChangeBadge: View {
    /// Optional tooltip text. Defaults to a friendly "Waiting to sync" string.
    let label: String

    init(label: String = "Waiting to sync") {
        self.label = label
    }

    var body: some View {
        Image(systemName: "arrow.triangle.2.circlepath")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Color.roostSecondary)
            .padding(4)
            .background(Color.roostSecondary.opacity(0.14), in: Circle())
            .overlay(Circle().stroke(Color.roostSecondary.opacity(0.22), lineWidth: 0.5))
            .accessibilityLabel(label)
    }
}

#Preview {
    HStack(spacing: 12) {
        Text("Waitrose shop")
        PendingChangeBadge()
    }
    .padding()
}
