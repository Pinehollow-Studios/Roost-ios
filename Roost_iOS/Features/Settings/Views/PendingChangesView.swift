import SwiftUI

/// Review screen for mutations that permanently failed during offline replay
/// (validation, permission, or "no handler" errors). Mirrors Splitwise's
/// "Unsynced changes" screen and Todoist's "Sync errors" list.
///
/// Surfaced from Settings → Account. Hidden in the parent Settings list when
/// the queue is empty so we don't introduce UI clutter for happy-path users.
struct PendingChangesView: View {
    @State private var failed: [PendingMutation] = []
    @State private var errorMessage: String?
    @State private var isRetrying = false

    var body: some View {
        RoostPageContainer(title: "Pending changes", subtitle: subtitle) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                if failed.isEmpty {
                    emptyState
                } else {
                    ForEach(failed, id: \.id) { mutation in
                        row(for: mutation)
                    }

                    if failed.count > 1 {
                        retryAllButton
                    }
                }
            }
        }
        .navigationTitle("Pending changes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: reload)
    }

    private var subtitle: String? {
        failed.isEmpty
            ? nil
            : "These edits couldn't sync. Retry when you're ready or discard them."
    }

    // MARK: Rows

    private func row(for mutation: PendingMutation) -> some View {
        RoostSectionSurface(emphasis: .subtle) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title(for: mutation))
                        .font(.roostLabel)
                        .foregroundStyle(Color.roostForeground)

                    Spacer()

                    Text(mutation.createdAt, style: .relative)
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                }

                if let message = mutation.lastError, !message.isEmpty {
                    Text(message)
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostDestructive)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: Spacing.sm) {
                    Button {
                        retry(mutation)
                    } label: {
                        Text("Retry")
                            .font(.roostLabel)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.roostPrimary, in: RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous))
                            .foregroundStyle(Color.roostCard)
                    }
                    .buttonStyle(.plain)
                    .disabled(isRetrying)

                    Button(role: .destructive) {
                        discard(mutation)
                    } label: {
                        Text("Discard")
                            .font(.roostLabel)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.roostDestructive.opacity(0.12), in: RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous))
                            .foregroundStyle(Color.roostDestructive)
                    }
                    .buttonStyle(.plain)
                    .disabled(isRetrying)
                }
            }
        }
    }

    private var emptyState: some View {
        RoostSectionSurface(emphasis: .subtle) {
            VStack(spacing: Spacing.sm) {
                Image(systemName: "checkmark.seal")
                    .font(.title2)
                    .foregroundStyle(Color.roostSuccess)
                Text("Everything is in sync")
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostForeground)
                Text("Offline edits sync automatically. Anything that needs your attention will show up here.")
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostMutedForeground)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
        }
    }

    private var retryAllButton: some View {
        Button {
            retryAll()
        } label: {
            Text(isRetrying ? "Retrying…" : "Retry all")
                .font(.roostLabel)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(Color.roostPrimary.opacity(0.12), in: RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous))
                .foregroundStyle(Color.roostPrimary)
        }
        .buttonStyle(.plain)
        .disabled(isRetrying)
    }

    // MARK: Actions

    private func reload() {
        let queue = MutationQueue()
        do {
            failed = try queue.allFailed()
            errorMessage = nil
        } catch {
            failed = []
            errorMessage = error.localizedDescription
        }
    }

    private func retry(_ mutation: PendingMutation) {
        let queue = MutationQueue()
        do {
            try queue.retry(mutation.id)
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        Task {
            isRetrying = true
            await SyncCoordinator.shared.drainIfOnline()
            isRetrying = false
            reload()
        }
    }

    private func retryAll() {
        let queue = MutationQueue()
        for mutation in failed {
            try? queue.retry(mutation.id)
        }
        Task {
            isRetrying = true
            await SyncCoordinator.shared.drainIfOnline()
            isRetrying = false
            reload()
        }
    }

    private func discard(_ mutation: PendingMutation) {
        let queue = MutationQueue()
        do {
            try queue.discard(mutation.id)
            SyncCoordinator.shared.refreshStatusCounts()
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Formatting

    private func title(for mutation: PendingMutation) -> String {
        let entity = mutation.entityType
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
        let operation: String
        switch mutation.operation {
        case "create": operation = "Create"
        case "update": operation = "Update"
        case "delete": operation = "Delete"
        default:
            if mutation.operation.hasPrefix("custom:") {
                operation = String(mutation.operation.dropFirst("custom:".count)).capitalized
            } else {
                operation = mutation.operation.capitalized
            }
        }
        return "\(operation) \(entity)"
    }
}
