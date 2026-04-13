import Foundation
import Observation
import Realtime

@MainActor
@Observable
final class PinboardViewModel {
    enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case active = "Active"
        case expiring = "Expiring"
        case permanent = "Permanent"

        var id: String { rawValue }
    }

    var notes: [PinboardNote] = []
    var isLoading = false
    var errorMessage: String?

    var selectedFilter: Filter = .all
    var expandedNoteIDs: Set<UUID> = []

    @ObservationIgnored
    private let pinboardService = PinboardService()

    @ObservationIgnored
    private var noteSubscriptionId: UUID?

    @ObservationIgnored
    private var acknowledgementSubscriptionId: UUID?

    @ObservationIgnored
    private var subscribedHomeId: UUID?

    @ObservationIgnored
    private var currentUserId: UUID?

    var activeNotes: [PinboardNote] {
        notes.filter(\.isActive)
    }

    var liveCount: Int {
        activeNotes.count
    }

    var unseenCount: Int {
        activeNotes.filter { !$0.isAcknowledged(by: currentUserId) && isVisibleToCurrentUser($0) }.count
    }

    var filteredNotes: [PinboardNote] {
        activeNotes.filter { note in
            switch selectedFilter {
            case .all:
                return true
            case .active:
                return true
            case .expiring:
                return note.isExpiringSoon
            case .permanent:
                return note.expiresAt == nil
            }
        }
    }

    func load(homeId: UUID, userId: UUID) async {
        currentUserId = userId
        isLoading = true
        errorMessage = nil

        do {
            notes = try await pinboardService.fetchNotes(for: homeId)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func startRealtime(homeId: UUID, userId: UUID) async {
        currentUserId = userId
        if let subscribedHomeId, subscribedHomeId != homeId {
            await stopRealtime()
        }
        guard noteSubscriptionId == nil, acknowledgementSubscriptionId == nil else { return }
        subscribedHomeId = homeId

        noteSubscriptionId = await RealtimeManager.shared.subscribe(
            table: "pinboard_notes",
            filter: .eq("home_id", value: homeId.uuidString)
        ) { [weak self] in
            guard let self, let homeId = self.subscribedHomeId, let userId = self.currentUserId else { return }
            await self.load(homeId: homeId, userId: userId)
        }

        acknowledgementSubscriptionId = await RealtimeManager.shared.subscribe(
            table: "pinboard_note_acknowledgements",
            filter: .eq("user_id", value: userId.uuidString)
        ) { [weak self] in
            guard let self, let homeId = self.subscribedHomeId, let userId = self.currentUserId else { return }
            await self.load(homeId: homeId, userId: userId)
        }
    }

    func stopRealtime() async {
        if let noteSubscriptionId {
            await RealtimeManager.shared.unsubscribe(table: "pinboard_notes", callbackId: noteSubscriptionId)
            self.noteSubscriptionId = nil
        }
        if let acknowledgementSubscriptionId {
            await RealtimeManager.shared.unsubscribe(table: "pinboard_note_acknowledgements", callbackId: acknowledgementSubscriptionId)
            self.acknowledgementSubscriptionId = nil
        }
        subscribedHomeId = nil
    }

    func addNote(
        content: String,
        homeId: UUID,
        userId: UUID,
        targetScope: PinboardTargetScope,
        targetUserID: UUID?,
        notifyOnCreate: Bool,
        expiresAt: Date?,
        linkType: PinboardLinkType? = nil,
        linkLabel: String? = nil,
        linkedEntityID: UUID? = nil
    ) async {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            let created = try await pinboardService.createNote(
                CreatePinboardNote(
                    homeID: homeId,
                    authorID: userId,
                    content: trimmed,
                    linkType: linkType,
                    linkLabel: linkLabel,
                    linkedEntityID: linkedEntityID,
                    targetScope: targetScope,
                    targetUserID: targetUserID,
                    notifyOnCreate: notifyOnCreate,
                    expiresAt: expiresAt
                )
            )
            notes.insert(created, at: 0)
            ActivityService.logActivity(
                homeId: homeId.uuidString,
                userId: userId.uuidString,
                action: "pinned a note",
                entityType: "pinboard_note",
                entityId: created.id.uuidString
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteNote(_ note: PinboardNote, homeId: UUID, userId: UUID) async {
        do {
            try await pinboardService.deleteNote(id: note.id)
            notes.removeAll { $0.id == note.id }
            ActivityService.logActivity(
                homeId: homeId.uuidString,
                userId: userId.uuidString,
                action: "took down a pinboard note",
                entityType: "pinboard_note",
                entityId: note.id.uuidString
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func acknowledge(noteID: UUID, userId: UUID) async {
        guard let index = notes.firstIndex(where: { $0.id == noteID }) else { return }
        if notes[index].isAcknowledged(by: userId) { return }

        let acknowledgement = PinboardAcknowledgement(noteID: noteID, userID: userId, seenAt: .now)
        notes[index].acknowledgements.append(acknowledgement)

        do {
            try await pinboardService.acknowledge(noteID: noteID, userID: userId)
        } catch {
            notes[index].acknowledgements.removeAll { $0.noteID == noteID && $0.userID == userId }
            errorMessage = error.localizedDescription
        }
    }

    func toggleExpanded(noteID: UUID) {
        if expandedNoteIDs.contains(noteID) {
            expandedNoteIDs.remove(noteID)
        } else {
            expandedNoteIDs.insert(noteID)
        }
    }

    private func isVisibleToCurrentUser(_ note: PinboardNote) -> Bool {
        guard let currentUserId else { return true }
        switch note.targetScope {
        case .everyone:
            return true
        case .self, .partner:
            return note.targetUserID == nil || note.targetUserID == currentUserId
        }
    }
}
