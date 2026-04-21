import SwiftUI

/// Legacy simple banner — kept for backwards compatibility with existing call
/// sites that pass a plain `isVisible` bool. New code should prefer
/// `OfflineStatusBanner` which is driven by `SyncStatusStore`.
struct OfflineBanner: View {
    let isVisible: Bool

    var body: some View {
        if isVisible {
            BannerChip(
                icon: "wifi.slash",
                tint: Color.roostWarning,
                text: "You're offline. Changes will sync when connection returns."
            )
        }
    }
}

/// Sync-aware banner driven by `SyncStatusStore`. Renders one of four states:
///   - `.idle`    → hidden
///   - `.offline` → warning tone, "saved and will sync"
///   - `.syncing` → subtle progress chip
///   - `.error`   → destructive tone with review prompt
struct OfflineStatusBanner: View {
    @Environment(SyncStatusStore.self) private var status

    var body: some View {
        switch status.state {
        case .idle:
            EmptyView()
        case .offline:
            BannerChip(
                icon: "wifi.slash",
                tint: Color.roostWarning,
                text: "You're offline. Changes are saved and will sync when you reconnect."
            )
        case .syncing(let pending):
            HStack(spacing: Spacing.sm) {
                ProgressView()
                    .controlSize(.small)
                Text(pending == 1 ? "Syncing 1 change…" : "Syncing \(pending) changes…")
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.roostCaption)
            .foregroundStyle(Color.roostForeground)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .frame(maxWidth: .infinity)
            .background(Color.roostSecondary.opacity(0.12), in: RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                    .stroke(Color.roostSecondary.opacity(0.20), lineWidth: 1)
            )
        case .error(let failed):
            BannerChip(
                icon: "exclamationmark.triangle",
                tint: Color.roostDestructive,
                text: failed == 1
                    ? "1 change couldn't sync — tap to review."
                    : "\(failed) changes couldn't sync — tap to review."
            )
        }
    }
}

private struct BannerChip: View {
    let icon: String
    let tint: Color
    let text: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.roostCaption)
        .foregroundStyle(Color.roostForeground)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity)
        .background(tint.opacity(0.18), in: RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                .stroke(tint.opacity(0.20), lineWidth: 1)
        )
    }
}
