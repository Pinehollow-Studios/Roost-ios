import SwiftUI

/// Inline notice for screens whose cached data is older than a freshness
/// threshold (default 24 hours). Shown only while offline — once the user is
/// back online, the repository's `refresh()` will fill in fresh data and this
/// should be hidden.
///
/// Mirrors Notion's "Last synced N ago" pattern. Keep the copy warm.
struct StaleDataNotice: View {
    let lastSyncedAt: Date?
    let isOffline: Bool

    /// Threshold in seconds past which we'll warn. Default 24h.
    let staleAfter: TimeInterval

    init(lastSyncedAt: Date?, isOffline: Bool, staleAfter: TimeInterval = 24 * 60 * 60) {
        self.lastSyncedAt = lastSyncedAt
        self.isOffline = isOffline
        self.staleAfter = staleAfter
    }

    var body: some View {
        if shouldShow {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(Color.roostMutedForeground)
                Text(message)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.roostCaption)
            .foregroundStyle(Color.roostMutedForeground)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.roostMuted.opacity(0.4), in: RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous))
        }
    }

    private var shouldShow: Bool {
        guard isOffline else { return false }
        guard let lastSyncedAt else { return true }
        return Date().timeIntervalSince(lastSyncedAt) >= staleAfter
    }

    private var message: String {
        guard let lastSyncedAt else {
            return "Showing offline data — reconnect to refresh."
        }
        let relative = Self.formatter.localizedString(for: lastSyncedAt, relativeTo: Date())
        return "Showing data from \(relative). Reconnect to refresh."
    }

    private static let formatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        return f
    }()
}
