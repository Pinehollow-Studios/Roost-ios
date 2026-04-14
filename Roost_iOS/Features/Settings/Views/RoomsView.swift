import SwiftUI

// MARK: - Rooms catalog (icons + presets)

enum RoomsData {
    struct RoomIconOption: Identifiable {
        let name: String
        let systemImage: String
        var id: String { systemImage }
    }

    struct GroupIconOption: Identifiable {
        let name: String
        let systemImage: String
        var id: String { systemImage }
    }

    struct PresetRoom: Identifiable {
        let name: String
        let icon: String
        var id: String { name }
    }

    struct SystemGroup: Identifiable {
        let name: String
        let icon: String
        let subtitle: String?
        var id: String { name }
    }

    static let roomIconOptions: [RoomIconOption] = [
        .init(name: "Home",         systemImage: "Home"),
        .init(name: "Kitchen",      systemImage: "ChefHat"),
        .init(name: "Living Room",  systemImage: "Sofa"),
        .init(name: "Bedroom",      systemImage: "Bed"),
        .init(name: "Double Bed",   systemImage: "BedDouble"),
        .init(name: "Bathroom",     systemImage: "Bath"),
        .init(name: "En Suite",     systemImage: "ShowerHead"),
        .init(name: "Hallway",      systemImage: "DoorOpen"),
        .init(name: "Dining Room",  systemImage: "UtensilsCrossed"),
        .init(name: "Office",       systemImage: "Laptop"),
        .init(name: "Garden",       systemImage: "Trees"),
        .init(name: "Garage",       systemImage: "Car"),
        .init(name: "Laundry",      systemImage: "Shirt"),
        .init(name: "Storage",      systemImage: "Archive"),
        .init(name: "Loft",         systemImage: "Package"),
        .init(name: "Music Room",   systemImage: "Music"),
        .init(name: "Gym",          systemImage: "Dumbbell"),
        .init(name: "Workshop",     systemImage: "Wrench"),
        .init(name: "Art Studio",   systemImage: "Palette"),
        .init(name: "Fireplace",    systemImage: "Flame"),
    ]

    static let groupIconOptions: [GroupIconOption] = [
        .init(name: "Grid",        systemImage: "Layers"),
        .init(name: "Home",        systemImage: "Home"),
        .init(name: "Building",    systemImage: "Building2"),
        .init(name: "Bedroom",     systemImage: "BedDouble"),
        .init(name: "Bathroom",    systemImage: "Bath"),
        .init(name: "Living Room", systemImage: "Sofa"),
        .init(name: "Kitchen",     systemImage: "ChefHat"),
        .init(name: "Garden",      systemImage: "Trees"),
        .init(name: "Garage",      systemImage: "Car"),
        .init(name: "Star",        systemImage: "Star"),
        .init(name: "Heart",       systemImage: "Heart"),
        .init(name: "Flame",       systemImage: "Flame"),
    ]

    static let presetRooms: [PresetRoom] = [
        .init(name: "Kitchen",      icon: "ChefHat"),
        .init(name: "Living Room",  icon: "Sofa"),
        .init(name: "Bedroom",      icon: "Bed"),
        .init(name: "Bathroom",     icon: "Bath"),
        .init(name: "Hallway",      icon: "DoorOpen"),
        .init(name: "En Suite",     icon: "ShowerHead"),
        .init(name: "Bedroom 2",    icon: "BedDouble"),
        .init(name: "Bedroom 3",    icon: "BedDouble"),
        .init(name: "Dining Room",  icon: "UtensilsCrossed"),
        .init(name: "Home Office",  icon: "Laptop"),
        .init(name: "Garden",       icon: "Trees"),
        .init(name: "Garage",       icon: "Car"),
        .init(name: "Utility Room", icon: "Shirt"),
        .init(name: "Loft",         icon: "Package"),
        .init(name: "Basement",     icon: "Archive"),
    ]

    static let systemGroups: [SystemGroup] = [
        .init(name: "All Rooms",     icon: "Home",      subtitle: "Always includes every room you add"),
        .init(name: "All Bedrooms",  icon: "BedDouble", subtitle: nil),
        .init(name: "All Bathrooms", icon: "Bath",      subtitle: nil),
    ]
}

// MARK: - Main View

struct RoomsView: View {
    @Environment(HomeManager.self) private var homeManager

    @State private var viewModel = RoomsViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
                FigmaBackHeader(title: "Rooms")

                Text("Manage the rooms in your home to organise chores and groups.")
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostMutedForeground)
                    .fixedSize(horizontal: false, vertical: true)

                yourRoomsSection
                suggestionsSection
                createCustomRoomSection
                roomGroupsSection
            }
            .padding(.horizontal, DesignSystem.Spacing.page)
            .padding(.bottom, 108)
            .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .swipeBackEnabled()
        .task(id: homeManager.homeId) {
            guard let homeId = homeManager.homeId else { return }
            await viewModel.load(homeId: homeId)
        }
        .overlay(alignment: .bottom) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostCard)
                    .padding(.horizontal, DesignSystem.Spacing.card)
                    .padding(.vertical, 10)
                    .background(Color.roostDestructive, in: Capsule())
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, DesignSystem.Size.toastBottomOffset)
                    .onTapGesture { viewModel.errorMessage = nil }
            }
        }
    }

    // MARK: - Your Rooms

    private var yourRoomsSection: some View {
        RoostCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.section) {
                sectionHeader(
                    icon: "house",
                    title: "Your rooms",
                    subtitle: "Every room in your home. Tap a room to rename it or change its icon."
                )

                if viewModel.isLoading && viewModel.rooms.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(Color.roostPrimary)
                        Spacer()
                    }
                    .padding(.vertical, Spacing.lg)
                } else if viewModel.rooms.isEmpty {
                    Text("No rooms added yet — use the suggestions below.")
                        .font(.roostBody)
                        .foregroundStyle(Color.roostMutedForeground)
                        .padding(.vertical, Spacing.md)
                } else {
                    VStack(spacing: 2) {
                        ForEach(viewModel.rooms) { room in
                            RoomListRow(
                                room: room,
                                isEditing: viewModel.editingRoomID == room.id,
                                onToggleEdit: {
                                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                                        viewModel.editingRoomID = viewModel.editingRoomID == room.id ? nil : room.id
                                    }
                                },
                                onDelete: {
                                    guard homeManager.homeId != nil else { return }
                                    Task { await viewModel.deleteRoom(room) }
                                },
                                onSave: { name, icon in
                                    Task { await viewModel.saveRoom(id: room.id, name: name, icon: icon) }
                                },
                                onClose: {
                                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                                        viewModel.editingRoomID = nil
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Suggestions

    private var suggestionsSection: some View {
        RoostCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.section) {
                sectionHeader(
                    icon: "sparkles",
                    title: "Suggestions",
                    subtitle: "Common rooms in most homes. Tap to add any that apply to yours."
                )

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: DesignSystem.Spacing.inline
                ) {
                    ForEach(RoomsData.presetRooms) { preset in
                        let added = viewModel.isPresetAdded(preset)
                        HStack(spacing: 10) {
                            RoomIconBadge(systemImage: preset.icon, isAdded: added)
                            Text(preset.name)
                                .font(.roostBody.weight(.medium))
                                .foregroundStyle(added ? Color.roostMutedForeground : Color.roostForeground)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                            Spacer(minLength: 0)
                            if added {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.roostSuccess)
                            } else {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.roostPrimary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous)
                                .fill(added ? Color.roostMuted.opacity(0.5) : Color.roostSurface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous)
                                .stroke(Color.roostHairline, lineWidth: 1)
                        )
                        .opacity(added ? 0.6 : 1)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard !added, let homeId = homeManager.homeId else { return }
                            Task { await viewModel.addPresetRoom(name: preset.name, icon: preset.icon, homeId: homeId) }
                        }
                        .animation(.easeInOut(duration: 0.2), value: added)
                    }
                }
            }
        }
    }

    // MARK: - Create Custom Room

    private var createCustomRoomSection: some View {
        RoostCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.section) {
                sectionHeader(
                    icon: "plus.circle",
                    title: "Create a custom room",
                    subtitle: "Name any space in your home and pick an icon that fits."
                )

                CustomRoomCreator(
                    name: Binding(
                        get: { viewModel.newRoomName },
                        set: { viewModel.newRoomName = $0; viewModel.newRoomDuplicateError = nil }
                    ),
                    selectedIcon: Binding(
                        get: { viewModel.newRoomIcon },
                        set: { viewModel.newRoomIcon = $0 }
                    ),
                    duplicateError: viewModel.newRoomDuplicateError,
                    isCreating: viewModel.isCreatingRoom,
                    onAdd: {
                        guard let homeId = homeManager.homeId else { return }
                        Task { await viewModel.addCustomRoom(homeId: homeId) }
                    }
                )
            }
        }
    }

    // MARK: - Room Groups

    private var roomGroupsSection: some View {
        RoostCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.section) {
                // Header + New Group button
                HStack(alignment: .top) {
                    sectionHeader(
                        icon: "square.grid.2x2",
                        title: "Room groups",
                        subtitle: "Assign a chore to multiple rooms at once — \"clean all bathrooms\" or \"tidy the house\"."
                    )

                    Spacer(minLength: 12)

                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                            if viewModel.showingNewGroupForm {
                                viewModel.cancelNewGroup()
                            } else {
                                viewModel.showingNewGroupForm = true
                                viewModel.editingGroupID = nil
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: viewModel.showingNewGroupForm ? "xmark" : "plus")
                                .font(.system(size: 11, weight: .bold))
                            Text(viewModel.showingNewGroupForm ? "Cancel" : "New group")
                                .font(.roostLabel)
                        }
                        .foregroundStyle(viewModel.showingNewGroupForm ? Color.roostMutedForeground : Color.roostPrimary)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 44)
                        .background(
                            Capsule()
                                .fill(viewModel.showingNewGroupForm ? Color.roostInput : Color.roostPrimary.opacity(0.1))
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    viewModel.showingNewGroupForm ? Color.roostHairline : Color.roostPrimary.opacity(0.25),
                                    lineWidth: 1
                                )
                        )
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }

                // System groups (non-editable)
                VStack(spacing: 2) {
                    ForEach(RoomsData.systemGroups) { sg in
                        HStack(spacing: 12) {
                            RoomIconBadge(systemImage: sg.icon, isAdded: false, tint: Color.roostMutedForeground, background: Color.roostMuted.opacity(0.5))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(sg.name)
                                    .font(.roostBody.weight(.medium))
                                    .foregroundStyle(Color.roostForeground)
                                if let subtitle = sg.subtitle {
                                    Text(subtitle)
                                        .font(.roostCaption)
                                        .foregroundStyle(Color.roostMutedForeground)
                                }
                            }

                            Spacer(minLength: 0)

                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                Text("Built-in")
                                    .font(.roostCaption)
                            }
                            .foregroundStyle(Color.roostMutedForeground)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                    }
                }

                // Divider between system and custom groups (if any)
                if !viewModel.groups.isEmpty {
                    Divider()
                        .background(Color.roostHairline)
                }

                // Custom groups
                VStack(spacing: 2) {
                    ForEach(viewModel.groups) { group in
                        let memberNames = group.roomGroupMembers
                            .compactMap { m in viewModel.rooms.first(where: { $0.id == m.roomID })?.name }

                        GroupListRow(
                            group: group,
                            memberNames: memberNames,
                            rooms: viewModel.rooms,
                            isEditing: viewModel.editingGroupID == group.id,
                            onToggleEdit: {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                                    viewModel.showingNewGroupForm = false
                                    viewModel.editingGroupID = viewModel.editingGroupID == group.id ? nil : group.id
                                }
                            },
                            onDelete: {
                                Task { await viewModel.deleteGroup(group) }
                            },
                            onSaveNameIcon: { name, icon in
                                Task { await viewModel.saveGroupNameAndIcon(id: group.id, name: name, icon: icon) }
                            },
                            onSaveMembers: { roomIds in
                                Task { await viewModel.saveGroupMembers(id: group.id, roomIds: roomIds) }
                            },
                            onClose: {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                                    viewModel.editingGroupID = nil
                                }
                            }
                        )
                    }
                }

                // New group inline form
                if viewModel.showingNewGroupForm {
                    NewGroupForm(
                        name: Binding(
                            get: { viewModel.newGroupName },
                            set: { viewModel.newGroupName = $0; viewModel.newGroupDuplicateError = nil }
                        ),
                        selectedIcon: Binding(
                            get: { viewModel.newGroupIcon },
                            set: { viewModel.newGroupIcon = $0 }
                        ),
                        selectedRoomIDs: Binding(
                            get: { viewModel.newGroupRoomIDs },
                            set: { viewModel.newGroupRoomIDs = $0 }
                        ),
                        rooms: viewModel.rooms,
                        duplicateError: viewModel.newGroupDuplicateError,
                        isCreating: viewModel.isCreatingGroup,
                        onCreate: {
                            guard let homeId = homeManager.homeId else { return }
                            Task { await viewModel.addGroup(homeId: homeId) }
                        },
                        onCancel: {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                                viewModel.cancelNewGroup()
                            }
                        }
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    // MARK: - Shared section header builder

    private func sectionHeader(icon: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.roostPrimary)
                Text(title)
                    .font(.roostCardTitle)
                    .foregroundStyle(Color.roostForeground)
            }
            Text(subtitle)
                .font(.roostCaption)
                .foregroundStyle(Color.roostMutedForeground)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Room Icon Badge

private struct RoomIconBadge: View {
    let systemImage: String
    let isAdded: Bool
    var tint: Color = .roostPrimary
    var background: Color = Color.roostPrimary.opacity(0.1)

    var body: some View {
        let sfSymbol = LucideIcon.sfSymbolName(for: systemImage) ?? systemImage
        Image(systemName: sfSymbol)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 34, height: 34)
            .background(background, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

// MARK: - Room List Row (with inline edit panel)

private struct RoomListRow: View {
    let room: Room
    let isEditing: Bool
    let onToggleEdit: () -> Void
    let onDelete: () -> Void
    let onSave: (String, String) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            HStack(spacing: 12) {
                RoomIconBadge(systemImage: room.icon ?? "Home", isAdded: false)

                Text(room.name)
                    .font(.roostBody.weight(.medium))
                    .foregroundStyle(Color.roostForeground)
                    .lineLimit(1)

                Spacer(minLength: 0)

                HStack(spacing: 4) {
                    Button(action: onToggleEdit) {
                        Image(systemName: isEditing ? "chevron.up" : "pencil")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(isEditing ? Color.roostPrimary : Color.roostMutedForeground)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle().fill(isEditing ? Color.roostPrimary.opacity(0.1) : Color.roostInput)
                            )
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.roostDestructive)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.roostDestructive.opacity(0.08)))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .onTapGesture(perform: onToggleEdit)

            // Inline edit panel
            if isEditing {
                RoomEditPanel(room: room, onSave: onSave, onClose: onClose)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: isEditing)
    }
}

// MARK: - Room Edit Panel

private struct RoomEditPanel: View {
    let room: Room
    let onSave: (String, String) -> Void
    let onClose: () -> Void

    @State private var draftName: String
    @State private var draftIcon: String
    @FocusState private var nameFocused: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    init(room: Room, onSave: @escaping (String, String) -> Void, onClose: @escaping () -> Void) {
        self.room = room
        self.onSave = onSave
        self.onClose = onClose
        _draftName = State(initialValue: room.name)
        _draftIcon = State(initialValue: room.icon ?? "Home")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Name field + close button
            HStack(spacing: 8) {
                TextField("Room name", text: $draftName)
                    .focused($nameFocused)
                    .font(.roostBody)
                    .foregroundStyle(Color.roostForeground)
                    .tint(Color.roostPrimary)
                    .submitLabel(.done)
                    .onSubmit {
                        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty { onSave(trimmed, draftIcon) }
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 40)
                    .background(Color.roostBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(nameFocused ? Color.roostPrimary.opacity(0.5) : Color.roostHairline, lineWidth: 1)
                    )
                    .animation(.easeInOut(duration: 0.15), value: nameFocused)

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.roostMutedForeground)
                        .frame(width: 32, height: 32)
                        .background(Color.roostBackground, in: Circle())
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            // Icon picker
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(RoomsData.roomIconOptions) { option in
                    let isSelected = draftIcon == option.systemImage
                    Button {
                        draftIcon = option.systemImage
                        let name = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(name.isEmpty ? room.name : name, option.systemImage)
                    } label: {
                        Image(systemName: LucideIcon.sfSymbolName(for: option.systemImage) ?? option.systemImage)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(isSelected ? Color.roostPrimary : Color.roostMutedForeground)
                            .frame(height: 44)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(isSelected ? Color.roostPrimary.opacity(0.12) : Color.roostBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(isSelected ? Color.roostPrimary.opacity(0.4) : Color.clear, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.12), value: isSelected)
                }
            }

            Text("Changes save automatically")
                .font(.roostCaption)
                .foregroundStyle(Color.roostMutedForeground)
        }
        .padding(DesignSystem.Spacing.card)
        .background(Color.roostInput, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous))
        .task {
            try? await Task.sleep(for: .milliseconds(150))
            nameFocused = true
        }
    }
}

// MARK: - Custom Room Creator

private struct CustomRoomCreator: View {
    @Binding var name: String
    @Binding var selectedIcon: String
    let duplicateError: String?
    let isCreating: Bool
    let onAdd: () -> Void

    @FocusState private var nameFocused: Bool
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.row) {
            // Name
            VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostForeground)

                TextField("e.g. Snug, Playroom, Conservatory…", text: $name)
                    .focused($nameFocused)
                    .font(.roostBody)
                    .foregroundStyle(Color.roostForeground)
                    .tint(Color.roostPrimary)
                    .submitLabel(.done)
                    .onSubmit { if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { onAdd() } }
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(Color.roostInput, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous)
                            .stroke(
                                duplicateError != nil ? Color.roostDestructive.opacity(0.5) :
                                    nameFocused ? Color.roostPrimary.opacity(0.5) : Color.roostHairline,
                                lineWidth: 1
                            )
                    )
                    .animation(.easeInOut(duration: 0.15), value: nameFocused)

                if let error = duplicateError {
                    Text(error)
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostDestructive)
                }
            }

            // Icon picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Icon")
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostForeground)

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(RoomsData.roomIconOptions) { option in
                        let isSelected = selectedIcon == option.systemImage
                        Button { selectedIcon = option.systemImage } label: {
                            Image(systemName: LucideIcon.sfSymbolName(for: option.systemImage) ?? option.systemImage)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(isSelected ? Color.roostPrimary : Color.roostMutedForeground)
                                .frame(height: 44)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(isSelected ? Color.roostPrimary.opacity(0.12) : Color.roostInput)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(isSelected ? Color.roostPrimary.opacity(0.4) : Color.clear, lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.12), value: isSelected)
                    }
                }
            }

            // Preview + Add
            HStack(spacing: 12) {
                if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: LucideIcon.sfSymbolName(for: selectedIcon) ?? selectedIcon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.roostPrimary)
                        Text(name.trimmingCharacters(in: .whitespacesAndNewlines))
                            .font(.roostBody.weight(.medium))
                            .foregroundStyle(Color.roostPrimary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.roostPrimary.opacity(0.1), in: Capsule())
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }

                Spacer(minLength: 0)

                RoostButton(title: "Add room", systemImage: "plus") {
                    nameFocused = false
                    onAdd()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: name.isEmpty)
        }
    }
}

// MARK: - Group List Row

private struct GroupListRow: View {
    let group: RoomGroup
    let memberNames: [String]
    let rooms: [Room]
    let isEditing: Bool
    let onToggleEdit: () -> Void
    let onDelete: () -> Void
    let onSaveNameIcon: (String, String) -> Void
    let onSaveMembers: (Set<UUID>) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            HStack(spacing: 12) {
                Image(systemName: LucideIcon.sfSymbolName(for: group.icon ?? "Layers") ?? "square.grid.2x2")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.roostPrimary)
                    .frame(width: 34, height: 34)
                    .background(Color.roostPrimary.opacity(0.1), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(group.name)
                        .font(.roostBody.weight(.medium))
                        .foregroundStyle(Color.roostForeground)
                        .lineLimit(1)
                    if !memberNames.isEmpty {
                        Text(memberNames.joined(separator: ", "))
                            .font(.roostCaption)
                            .foregroundStyle(Color.roostMutedForeground)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                HStack(spacing: 4) {
                    Button(action: onToggleEdit) {
                        Image(systemName: isEditing ? "chevron.up" : "pencil")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(isEditing ? Color.roostPrimary : Color.roostMutedForeground)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(isEditing ? Color.roostPrimary.opacity(0.1) : Color.roostInput))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.roostDestructive)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.roostDestructive.opacity(0.08)))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .onTapGesture(perform: onToggleEdit)

            // Inline edit panel
            if isEditing {
                GroupEditPanel(
                    group: group,
                    rooms: rooms,
                    onSaveNameIcon: onSaveNameIcon,
                    onSaveMembers: onSaveMembers,
                    onClose: onClose
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: isEditing)
    }
}

// MARK: - Group Edit Panel

private struct GroupEditPanel: View {
    let group: RoomGroup
    let rooms: [Room]
    let onSaveNameIcon: (String, String) -> Void
    let onSaveMembers: (Set<UUID>) -> Void
    let onClose: () -> Void

    @State private var draftName: String
    @State private var draftIcon: String
    @State private var selectedRoomIDs: Set<UUID>
    @FocusState private var nameFocused: Bool

    init(
        group: RoomGroup,
        rooms: [Room],
        onSaveNameIcon: @escaping (String, String) -> Void,
        onSaveMembers: @escaping (Set<UUID>) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.group = group
        self.rooms = rooms
        self.onSaveNameIcon = onSaveNameIcon
        self.onSaveMembers = onSaveMembers
        self.onClose = onClose
        _draftName = State(initialValue: group.name)
        _draftIcon = State(initialValue: group.icon ?? "Layers")
        _selectedRoomIDs = State(initialValue: group.memberRoomIDs)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Name + close
            HStack(spacing: 8) {
                TextField("Group name", text: $draftName)
                    .focused($nameFocused)
                    .font(.roostBody)
                    .foregroundStyle(Color.roostForeground)
                    .tint(Color.roostPrimary)
                    .submitLabel(.done)
                    .onSubmit {
                        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty { onSaveNameIcon(trimmed, draftIcon) }
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 40)
                    .background(Color.roostBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(nameFocused ? Color.roostPrimary.opacity(0.5) : Color.roostHairline, lineWidth: 1)
                    )
                    .animation(.easeInOut(duration: 0.15), value: nameFocused)

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.roostMutedForeground)
                        .frame(width: 32, height: 32)
                        .background(Color.roostBackground, in: Circle())
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            // Icon picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Icon")
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostMutedForeground)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(RoomsData.groupIconOptions) { option in
                            let isSelected = draftIcon == option.systemImage
                            Button {
                                draftIcon = option.systemImage
                                let name = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
                                onSaveNameIcon(name.isEmpty ? group.name : name, option.systemImage)
                            } label: {
                                Image(systemName: LucideIcon.sfSymbolName(for: option.systemImage) ?? option.systemImage)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(isSelected ? Color.roostPrimary : Color.roostMutedForeground)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                                            .fill(isSelected ? Color.roostPrimary.opacity(0.12) : Color.roostBackground)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                                            .stroke(isSelected ? Color.roostPrimary.opacity(0.4) : Color.clear, lineWidth: 1.5)
                                    )
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .animation(.easeInOut(duration: 0.12), value: isSelected)
                        }
                    }
                }
            }

            // Room membership
            if !rooms.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Rooms in this group")
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)

                    RoomChipLayout(spacing: 8) {
                        ForEach(rooms) { room in
                            let isOn = selectedRoomIDs.contains(room.id)
                            Button {
                                if isOn {
                                    selectedRoomIDs.remove(room.id)
                                } else {
                                    selectedRoomIDs.insert(room.id)
                                }
                                onSaveMembers(selectedRoomIDs)
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: LucideIcon.sfSymbolName(for: room.icon ?? "Home") ?? "house")
                                        .font(.system(size: 11, weight: .semibold))
                                    Text(room.name)
                                        .font(.roostCaption.weight(.medium))
                                    if isOn {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                }
                                .foregroundStyle(isOn ? Color.roostPrimary : Color.roostForeground)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule().fill(isOn ? Color.roostPrimary.opacity(0.1) : Color.roostBackground)
                                )
                                .overlay(
                                    Capsule().stroke(
                                        isOn ? Color.roostPrimary.opacity(0.4) : Color.roostHairline,
                                        lineWidth: 1
                                    )
                                )
                            }
                            .buttonStyle(.plain)
                            .animation(.easeInOut(duration: 0.15), value: isOn)
                        }
                    }
                }
            }

            Text("Changes save automatically")
                .font(.roostCaption)
                .foregroundStyle(Color.roostMutedForeground)
        }
        .padding(DesignSystem.Spacing.card)
        .background(Color.roostInput, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous))
        .task {
            try? await Task.sleep(for: .milliseconds(150))
            nameFocused = true
        }
    }
}

// MARK: - New Group Form

private struct NewGroupForm: View {
    @Binding var name: String
    @Binding var selectedIcon: String
    @Binding var selectedRoomIDs: Set<UUID>
    let rooms: [Room]
    let duplicateError: String?
    let isCreating: Bool
    let onCreate: () -> Void
    let onCancel: () -> Void

    @FocusState private var nameFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New group")
                .font(.roostBody.weight(.semibold))
                .foregroundStyle(Color.roostForeground)

            // Name
            VStack(alignment: .leading, spacing: 4) {
                TextField("e.g. Ground Floor, Wet Rooms…", text: $name)
                    .focused($nameFocused)
                    .font(.roostBody)
                    .foregroundStyle(Color.roostForeground)
                    .tint(Color.roostPrimary)
                    .submitLabel(.done)
                    .padding(.horizontal, 12)
                    .frame(height: 40)
                    .background(Color.roostBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(
                                duplicateError != nil ? Color.roostDestructive.opacity(0.5) :
                                    nameFocused ? Color.roostPrimary.opacity(0.5) : Color.roostHairline,
                                lineWidth: 1
                            )
                    )
                    .animation(.easeInOut(duration: 0.15), value: nameFocused)

                if let error = duplicateError {
                    Text(error)
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostDestructive)
                }
            }

            // Icon picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Icon")
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostMutedForeground)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(RoomsData.groupIconOptions) { option in
                            let isSelected = selectedIcon == option.systemImage
                            Button { selectedIcon = option.systemImage } label: {
                                Image(systemName: LucideIcon.sfSymbolName(for: option.systemImage) ?? option.systemImage)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(isSelected ? Color.roostPrimary : Color.roostMutedForeground)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                                            .fill(isSelected ? Color.roostPrimary.opacity(0.12) : Color.roostBackground)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                                            .stroke(isSelected ? Color.roostPrimary.opacity(0.4) : Color.clear, lineWidth: 1.5)
                                    )
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .animation(.easeInOut(duration: 0.12), value: isSelected)
                        }
                    }
                }
            }

            // Room picker
            if !rooms.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Rooms to include")
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)

                    RoomChipLayout(spacing: 8) {
                        ForEach(rooms) { room in
                            let isOn = selectedRoomIDs.contains(room.id)
                            Button {
                                if isOn {
                                    selectedRoomIDs.remove(room.id)
                                } else {
                                    selectedRoomIDs.insert(room.id)
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: LucideIcon.sfSymbolName(for: room.icon ?? "Home") ?? "house")
                                        .font(.system(size: 11, weight: .semibold))
                                    Text(room.name)
                                        .font(.roostCaption.weight(.medium))
                                    if isOn {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                }
                                .foregroundStyle(isOn ? Color.roostPrimary : Color.roostForeground)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule().fill(isOn ? Color.roostPrimary.opacity(0.1) : Color.roostBackground)
                                )
                                .overlay(
                                    Capsule().stroke(
                                        isOn ? Color.roostPrimary.opacity(0.4) : Color.roostHairline,
                                        lineWidth: 1
                                    )
                                )
                            }
                            .buttonStyle(.plain)
                            .animation(.easeInOut(duration: 0.15), value: isOn)
                        }
                    }
                }
            }

            // Actions
            HStack(spacing: 10) {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.roostLabel)
                        .foregroundStyle(Color.roostMutedForeground)
                        .padding(.horizontal, 16)
                        .frame(height: 44)
                        .background(Color.roostBackground, in: Capsule())
                        .overlay(Capsule().stroke(Color.roostHairline, lineWidth: 1))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)

                RoostButton(title: "Create group", systemImage: "plus") {
                    nameFocused = false
                    onCreate()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
            }
        }
        .padding(DesignSystem.Spacing.card)
        .background(Color.roostInput, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous))
        .task {
            try? await Task.sleep(for: .milliseconds(100))
            nameFocused = true
        }
    }
}

// MARK: - Flow Layout (for room chip wrapping)

private struct RoomChipLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let width = proposal.width ?? .infinity
        var height: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > width, rowWidth > 0 {
                height += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
