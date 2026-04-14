import SwiftUI

struct AddChoreSheet: View {
    let myName: String
    let partnerName: String?
    let myUserId: UUID
    let partnerUserId: UUID?
    let rooms: [Room]
    let roomGroups: [RoomGroup]
    let onAdd: (String, String?, UUID?, String, Date?, String?) async -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focusedField: Field?

    @State private var title = ""
    @State private var description = ""
    @State private var assignment = "me"
    @State private var frequency = "once"
    @State private var includeDueDate = true
    @State private var dueDate = Date()
    @State private var room = ""
    @State private var isSaving = false
    @State private var hasAppeared = false

    private enum Field {
        case title
        case description
    }

    private let frequencies = [
        ("once", "Once"),
        ("daily", "Daily"),
        ("weekly", "Weekly"),
        ("monthly", "Monthly")
    ]

    private var canSubmit: Bool {
        !trimmedTitle.isEmpty && !isSaving
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                header
                    .addChoreEntrance(at: 0, hasAppeared: hasAppeared, reduceMotion: reduceMotion)

                choreBlock
                    .addChoreEntrance(at: 1, hasAppeared: hasAppeared, reduceMotion: reduceMotion)

                roomBlock
                    .addChoreEntrance(at: 2, hasAppeared: hasAppeared, reduceMotion: reduceMotion)

                assignmentBlock
                    .addChoreEntrance(at: 3, hasAppeared: hasAppeared, reduceMotion: reduceMotion)

                frequencyBlock
                    .addChoreEntrance(at: 4, hasAppeared: hasAppeared, reduceMotion: reduceMotion)

                scheduleBlock
                    .addChoreEntrance(at: 5, hasAppeared: hasAppeared, reduceMotion: reduceMotion)

                notesBlock
                    .addChoreEntrance(at: 6, hasAppeared: hasAppeared, reduceMotion: reduceMotion)
            }
            .padding(.horizontal, addChorePageInset)
            .padding(.top, DesignSystem.Spacing.screenTop)
            .padding(.bottom, 116)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .scrollDismissesKeyboard(.interactively)
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = nil
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            addBar
        }
        .task {
            NotificationCenter.default.post(name: .roostTabBarHiddenChanged, object: true)
            focusedField = .title
            guard !reduceMotion else {
                hasAppeared = true
                return
            }
            if !hasAppeared {
                withAnimation(.roostSmooth) {
                    hasAppeared = true
                }
            }
        }
        .onDisappear {
            NotificationCenter.default.post(name: .roostTabBarHiddenChanged, object: false)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .bold))
                    Text("Chores")
                        .font(.roostLabel)
                }
                .foregroundStyle(addChoreAccent)
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(addChoreAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(AddChorePressStyle(reduceMotion: reduceMotion))

            VStack(alignment: .leading, spacing: 5) {
                Text("ADD CHORE")
                    .font(.roostMeta)
                    .foregroundStyle(addChoreAccent)
                    .tracking(1.0)

                Text("New chore")
                    .font(.roostTitle)
                    .foregroundStyle(Color.roostForeground)
            }
        }
    }

    private var choreBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Task")

            TextField("Take bins out", text: $title)
                .font(.roostCardTitle)
                .foregroundStyle(Color.roostForeground)
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(false)
                .submitLabel(.next)
                .focused($focusedField, equals: .title)
                .onSubmit {
                    focusedField = .description
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 58)
                .background(Color.roostCard, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(focusedField == .title ? addChoreAccent.opacity(0.62) : Color.roostHairline, lineWidth: focusedField == .title ? 1.5 : 1)
                )
        }
    }

    private var roomBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                sectionLabel("Room")
                Spacer(minLength: 0)
                Text(roomValue ?? "Optional")
                    .font(.roostMeta)
                    .foregroundStyle(roomValue == nil ? Color.roostMutedForeground : roomAccent)
                    .lineLimit(1)
            }

            VStack(alignment: .leading, spacing: 10) {
                if roomGroupChoices.isEmpty && roomChoices.isEmpty {
                    Text("Add rooms in Settings to use them here.")
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.roostCard.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                } else {
                    if !roomGroupChoices.isEmpty {
                        roomChoiceSection("Groups", choices: roomGroupChoices, tint: groupAccent)
                    }

                    if !roomChoices.isEmpty {
                        roomChoiceSection("Rooms", choices: roomChoices, tint: roomAccent)
                    }

                    Button {
                        UISelectionFeedbackGenerator().selectionChanged()
                        withAnimation(.roostEaseOut) {
                            room = ""
                        }
                    } label: {
                        Text("No room")
                            .font(.roostMeta)
                            .foregroundStyle(room.isEmpty ? Color.roostCard : Color.roostMutedForeground)
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(room.isEmpty ? addChoreAccent : Color.roostCard.opacity(0.76), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(room.isEmpty ? addChoreAccent.opacity(0.35) : Color.roostHairline, lineWidth: 1)
                            )
                    }
                    .buttonStyle(AddChorePressStyle(reduceMotion: reduceMotion))
                }
            }
            .padding(12)
            .background(
                LinearGradient(
                    colors: [roomAccent.opacity(0.18), groupAccent.opacity(0.11)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(roomAccent.opacity(0.34), lineWidth: 1)
            )
        }
    }

    private var assignmentBlock: some View {
        compactSection(title: "Assigned to") {
            LazyVGrid(columns: compactColumns, spacing: 8) {
                choiceButton(
                    title: myName,
                    detail: "You",
                    isSelected: assignment == "me",
                    tint: addChoreAccent
                ) {
                    assignment = "me"
                }

                if let partnerName {
                    choiceButton(
                        title: partnerName,
                        detail: "Partner",
                        isSelected: assignment == "partner",
                        tint: addChoreAccent
                    ) {
                        assignment = "partner"
                    }
                }

                choiceButton(
                    title: "Unassigned",
                    detail: "Anyone",
                    isSelected: assignment == "unassigned",
                    tint: addChoreAccent
                ) {
                    assignment = "unassigned"
                }
            }
        }
    }

    private var frequencyBlock: some View {
        compactSection(title: "Repeats") {
            LazyVGrid(columns: compactColumns, spacing: 8) {
                ForEach(frequencies, id: \.0) { option in
                    choiceButton(
                        title: option.1,
                        detail: repeatDetail(for: option.0),
                        isSelected: frequency == option.0,
                        tint: repeatAccent
                    ) {
                        frequency = option.0
                    }
                }
            }
        }
    }

    private var scheduleBlock: some View {
        compactSection(title: "Due date") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    smallPill("Due", isSelected: includeDueDate, tint: dateAccent) {
                        includeDueDate = true
                    }
                    smallPill("No date", isSelected: !includeDueDate, tint: dateAccent) {
                        includeDueDate = false
                    }
                }

                if includeDueDate {
                    HStack(spacing: 8) {
                        quickDateButton("Today", date: Date())
                        quickDateButton("Tomorrow", date: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
                        quickDateButton("Next week", date: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date())
                    }

                    DatePicker("Date", selection: $dueDate, displayedComponents: .date)
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostForeground)
                        .padding(.horizontal, 12)
                        .frame(height: 44)
                        .background(Color.roostCard, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.roostHairline, lineWidth: 1)
                        )
                        .tint(dateAccent)
                }
            }
        }
    }

    private var notesBlock: some View {
        compactSection(title: "Notes") {
            TextField("Optional details", text: $description, axis: .vertical)
                .font(.roostBody)
                .foregroundStyle(Color.roostForeground)
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(false)
                .lineLimit(2...4)
                .submitLabel(.done)
                .focused($focusedField, equals: .description)
                .onSubmit {
                    focusedField = nil
                }
                .padding(12)
                .frame(minHeight: 76, alignment: .topLeading)
                .background(Color.roostCard, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(focusedField == .description ? addChoreAccent.opacity(0.54) : Color.roostHairline, lineWidth: focusedField == .description ? 1.5 : 1)
                )
        }
    }

    private var addBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.roostHairline.opacity(0.65))
                .frame(height: 1)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(roomValue ?? "No room")
                        .font(.roostMeta)
                        .foregroundStyle(roomValue == nil ? Color.roostMutedForeground : roomAccent)
                        .lineLimit(1)

                    Text(trimmedTitle.isEmpty ? "Waiting for a chore" : trimmedTitle)
                        .font(.roostLabel)
                        .foregroundStyle(Color.roostForeground)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Button {
                    Task { await addAndClose() }
                } label: {
                    Text(isSaving ? "Adding" : "Add chore")
                        .font(.roostLabel)
                        .foregroundStyle(Color.roostCard)
                        .padding(.horizontal, 18)
                        .frame(height: 48)
                        .background(canSubmit ? addChoreButtonAccent : Color.roostMutedForeground.opacity(0.34), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(AddChorePressStyle(reduceMotion: reduceMotion))
                .disabled(!canSubmit)
            }
            .padding(.horizontal, addChorePageInset)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .background(Color.roostBackground.opacity(0.98))
        }
    }

    private func compactSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(title)
            content()
        }
        .padding(12)
        .background(Color.roostCard.opacity(0.74), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.roostHairline, lineWidth: 1)
        )
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.roostMeta)
            .foregroundStyle(Color.roostMutedForeground)
            .tracking(0.8)
    }

    private func choiceButton(
        title: String,
        detail: String,
        isSelected: Bool,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.roostEaseOut) {
                action()
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.roostLabel)
                    .foregroundStyle(isSelected ? Color.roostCard : Color.roostForeground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(detail)
                    .font(.roostMeta)
                    .foregroundStyle(isSelected ? Color.roostCard.opacity(0.76) : Color.roostMutedForeground)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 50)
            .padding(.horizontal, 12)
            .background(isSelected ? tint : tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? tint.opacity(0.25) : tint.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(AddChorePressStyle(reduceMotion: reduceMotion))
    }

    private func roomChoiceSection(_ title: String, choices: [RoomChoice], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.roostMeta)
                .foregroundStyle(Color.roostMutedForeground)

            LazyVGrid(columns: compactColumns, spacing: 8) {
                ForEach(choices) { choice in
                    roomChoiceButton(choice, tint: tint)
                }
            }
        }
    }

    private func roomChoiceButton(_ choice: RoomChoice, tint: Color) -> some View {
        let selected = room.caseInsensitiveCompare(choice.name) == .orderedSame

        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.roostEaseOut) {
                room = selected ? "" : choice.name
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: choice.systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(selected ? Color.roostCard : tint)
                    .frame(width: 28, height: 28)
                    .background(selected ? Color.roostCard.opacity(0.14) : tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(choice.name)
                        .font(.roostLabel)
                        .foregroundStyle(selected ? Color.roostCard : Color.roostForeground)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text(choice.detail)
                        .font(.roostMeta)
                        .foregroundStyle(selected ? Color.roostCard.opacity(0.76) : Color.roostMutedForeground)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(height: 50)
            .background(selected ? tint : Color.roostCard.opacity(0.82), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(selected ? tint.opacity(0.35) : tint.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(AddChorePressStyle(reduceMotion: reduceMotion))
    }

    private func smallPill(_ title: String, isSelected: Bool, tint: Color, action: @escaping () -> Void) -> some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.roostEaseOut) {
                action()
            }
        } label: {
            Text(title)
                .font(.roostMeta)
                .foregroundStyle(isSelected ? Color.roostCard : Color.roostForeground)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(isSelected ? tint : tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isSelected ? tint.opacity(0.28) : tint.opacity(0.18), lineWidth: 1)
                )
        }
        .buttonStyle(AddChorePressStyle(reduceMotion: reduceMotion))
    }

    private func quickDateButton(_ title: String, date: Date) -> some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.roostEaseOut) {
                dueDate = date
                includeDueDate = true
            }
        } label: {
            Text(title)
                .font(.roostMeta)
                .foregroundStyle(Calendar.current.isDate(dueDate, inSameDayAs: date) ? Color.roostCard : Color.roostForeground)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(
                    Calendar.current.isDate(dueDate, inSameDayAs: date) ? dateAccent : dateAccent.opacity(0.09),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(dateAccent.opacity(0.18), lineWidth: 1)
                )
        }
        .buttonStyle(AddChorePressStyle(reduceMotion: reduceMotion))
    }

    private func repeatDetail(for value: String) -> String {
        switch value {
        case "daily":
            return "Every day"
        case "weekly":
            return "Each week"
        case "monthly":
            return "Each month"
        default:
            return "No repeat"
        }
    }

    private func addAndClose() async {
        guard canSubmit else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.68)
        isSaving = true
        focusedField = nil
        await onAdd(
            trimmedTitle,
            descriptionValue,
            resolvedAssignedUserId,
            frequency,
            includeDueDate ? dueDate : nil,
            roomValue
        )
        isSaving = false
        dismiss()
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var descriptionValue: String? {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var roomValue: String? {
        let trimmed = room.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var resolvedAssignedUserId: UUID? {
        switch assignment {
        case "me":
            return myUserId
        case "partner":
            return partnerUserId
        default:
            return nil
        }
    }

    private var roomChoices: [RoomChoice] {
        rooms.map {
            RoomChoice(
                id: "room-\($0.id.uuidString)",
                name: $0.name,
                detail: "Room",
                systemImage: mappedIcon($0.icon ?? "Home")
            )
        }
    }

    private var roomGroupChoices: [RoomChoice] {
        let systemChoices = RoomsData.systemGroups.map {
            RoomChoice(
                id: "system-\($0.name)",
                name: $0.name,
                detail: "Built-in",
                systemImage: mappedIcon($0.icon)
            )
        }

        let customChoices = roomGroups.map {
            RoomChoice(
                id: "group-\($0.id.uuidString)",
                name: $0.name,
                detail: groupDetail(for: $0),
                systemImage: mappedIcon($0.icon ?? "Layers")
            )
        }

        return systemChoices + customChoices
    }

    private var compactColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
    }

    private func groupDetail(for group: RoomGroup) -> String {
        let count = group.memberRoomIDs.count
        if count == 1 { return "1 room" }
        return "\(count) rooms"
    }

    private func mappedIcon(_ icon: String) -> String {
        LucideIcon.sfSymbolName(for: icon) ?? icon
    }
}

private let addChorePageInset: CGFloat = 12
private let addChoreAccent = Color.roostChoreTint
private let roomAccent = Color.roostChoreTint
private let groupAccent = Color.roostMoneyTint
private let repeatAccent = Color.roostShoppingTint
private let dateAccent = Color.roostShoppingTint
private let addChoreButtonAccent = Color(hex: 0xD76446)

private struct RoomChoice: Identifiable {
    let id: String
    let name: String
    let detail: String
    let systemImage: String
}

private struct AddChorePressStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(reduceMotion ? nil : DesignSystem.Motion.buttonPress, value: configuration.isPressed)
    }
}

private struct AddChoreEntranceModifier: ViewModifier {
    let index: Int
    let hasAppeared: Bool
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: reduceMotion || hasAppeared ? 0 : CGFloat(14 + (index * 3)))
            .animation(reduceMotion ? nil : .roostSmooth.delay(Double(index) * 0.035), value: hasAppeared)
    }
}

private extension View {
    func addChoreEntrance(at index: Int, hasAppeared: Bool, reduceMotion: Bool) -> some View {
        modifier(AddChoreEntranceModifier(index: index, hasAppeared: hasAppeared, reduceMotion: reduceMotion))
    }
}

#Preview("Add Chore") {
    NavigationStack {
        AddChoreSheet(
            myName: "Tom",
            partnerName: "Alex",
            myUserId: UUID(),
            partnerUserId: UUID(),
            rooms: [
                Room(id: UUID(), homeID: UUID(), name: "Kitchen", icon: "ChefHat"),
                Room(id: UUID(), homeID: UUID(), name: "Bathroom", icon: "Bath"),
                Room(id: UUID(), homeID: UUID(), name: "Hallway", icon: "DoorOpen")
            ],
            roomGroups: []
        ) { _, _, _, _, _, _ in }
    }
}
