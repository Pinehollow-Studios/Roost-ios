import Observation
import Foundation

@MainActor
@Observable
final class RoomsViewModel {

    // MARK: - Data

    var rooms: [Room] = []
    var groups: [RoomGroup] = []
    var isLoading = false
    var errorMessage: String?

    // MARK: - Room inline-edit state

    /// ID of the room row currently expanded for inline editing
    var editingRoomID: UUID?

    // MARK: - Custom room creation

    var newRoomName = ""
    var newRoomIcon = RoomsData.roomIconOptions.first?.systemImage ?? "Home"
    var newRoomDuplicateError: String?
    var isCreatingRoom = false

    // MARK: - Group inline-edit state

    /// ID of the group row currently expanded for inline editing
    var editingGroupID: UUID?

    // MARK: - New group form

    var showingNewGroupForm = false
    var newGroupName = ""
    var newGroupIcon = RoomsData.groupIconOptions.first?.systemImage ?? "Layers"
    var newGroupRoomIDs: Set<UUID> = []
    var newGroupDuplicateError: String?
    var isCreatingGroup = false

    // MARK: - Private

    @ObservationIgnored
    private let roomService = RoomService()

    // MARK: - Loading

    func load(homeId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            async let fetchedRooms = roomService.fetchRooms(for: homeId)
            async let fetchedGroups = roomService.fetchRoomGroups(for: homeId)
            rooms = try await fetchedRooms
            groups = try await fetchedGroups
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Room CRUD

    func addPresetRoom(name: String, icon: String, homeId: UUID) async {
        guard !rooms.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) else { return }
        do {
            let created = try await roomService.createRoom(
                CreateRoom(homeID: homeId, name: name, icon: icon)
            )
            rooms.append(created)
            rooms.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addCustomRoom(homeId: UUID) async {
        let trimmed = newRoomName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if rooms.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            newRoomDuplicateError = "A room with this name already exists."
            return
        }

        isCreatingRoom = true
        newRoomDuplicateError = nil
        do {
            let created = try await roomService.createRoom(
                CreateRoom(homeID: homeId, name: trimmed, icon: newRoomIcon)
            )
            rooms.append(created)
            rooms.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            newRoomName = ""
            newRoomIcon = RoomsData.roomIconOptions.first?.systemImage ?? "Home"
        } catch {
            errorMessage = error.localizedDescription
        }
        isCreatingRoom = false
    }

    /// Called from the inline edit panel — auto-saves name + icon.
    func saveRoom(id: UUID, name: String, icon: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Optimistic update
        if let index = rooms.firstIndex(where: { $0.id == id }) {
            rooms[index].name = trimmed
            rooms[index].icon = icon
        }

        do {
            try await roomService.updateRoom(id: id, name: trimmed, icon: icon)
            rooms.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteRoom(_ room: Room) async {
        if editingRoomID == room.id { editingRoomID = nil }
        let original = rooms
        rooms.removeAll { $0.id == room.id }
        do {
            try await roomService.deleteRoom(id: room.id)
        } catch {
            rooms = original
            errorMessage = error.localizedDescription
        }
    }

    func isPresetAdded(_ preset: RoomsData.PresetRoom) -> Bool {
        rooms.contains { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
    }

    // MARK: - Group CRUD

    func addGroup(homeId: UUID) async {
        let trimmed = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if groups.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            newGroupDuplicateError = "A group with this name already exists."
            return
        }

        isCreatingGroup = true
        newGroupDuplicateError = nil
        do {
            let created = try await roomService.createRoomGroup(
                CreateRoomGroup(homeID: homeId, name: trimmed, icon: newGroupIcon)
            )
            // Set initial members
            if !newGroupRoomIDs.isEmpty {
                try await roomService.setGroupMembers(groupId: created.id, roomIds: Array(newGroupRoomIDs))
            }
            // Re-fetch groups to get accurate member data
            groups = try await roomService.fetchRoomGroups(for: homeId)

            showingNewGroupForm = false
            newGroupName = ""
            newGroupIcon = RoomsData.groupIconOptions.first?.systemImage ?? "Layers"
            newGroupRoomIDs = []
        } catch {
            errorMessage = error.localizedDescription
        }
        isCreatingGroup = false
    }

    /// Auto-saves group name and icon from the inline edit panel.
    func saveGroupNameAndIcon(id: UUID, name: String, icon: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let index = groups.firstIndex(where: { $0.id == id }) {
            groups[index].name = trimmed
            groups[index].icon = icon
        }
        do {
            try await roomService.updateRoomGroup(id: id, name: trimmed, icon: icon)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Auto-saves group membership from the inline edit panel.
    func saveGroupMembers(id: UUID, roomIds: Set<UUID>) async {
        // Optimistic update
        if let index = groups.firstIndex(where: { $0.id == id }) {
            groups[index].roomGroupMembers = roomIds.map { RoomGroupMember(roomID: $0) }
        }
        do {
            try await roomService.setGroupMembers(groupId: id, roomIds: Array(roomIds))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteGroup(_ group: RoomGroup) async {
        if editingGroupID == group.id { editingGroupID = nil }
        let original = groups
        groups.removeAll { $0.id == group.id }
        do {
            try await roomService.deleteRoomGroup(id: group.id)
        } catch {
            groups = original
            errorMessage = error.localizedDescription
        }
    }

    func cancelNewGroup() {
        showingNewGroupForm = false
        newGroupName = ""
        newGroupIcon = RoomsData.groupIconOptions.first?.systemImage ?? "Layers"
        newGroupRoomIDs = []
        newGroupDuplicateError = nil
    }
}

