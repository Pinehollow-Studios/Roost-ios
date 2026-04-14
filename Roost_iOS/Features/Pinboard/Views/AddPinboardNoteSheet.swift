import SwiftUI

struct AddPinboardNoteSheet: View {
    let currentMemberName: String?
    let partnerName: String?
    let rooms: [Room]
    let onAdd: (String, PinboardTargetScope, Bool, Date?, Room?) async -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focusedField: Field?

    @State private var content = ""
    @State private var targetScope: PinboardTargetScope = .everyone
    @State private var notifyOnCreate = true
    @State private var includeExpiry = false
    @State private var expiryDate = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
    @State private var selectedRoomID: UUID?
    @State private var isSaving = false
    @State private var hasAppeared = false

    private enum Field {
        case content
    }

    private var canSubmit: Bool {
        !trimmedContent.isEmpty && !isSaving
    }

    private var selectedRoom: Room? {
        rooms.first(where: { $0.id == selectedRoomID })
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                header
                    .addPinboardEntrance(at: 0, hasAppeared: hasAppeared, reduceMotion: reduceMotion)

                noteBlock
                    .addPinboardEntrance(at: 1, hasAppeared: hasAppeared, reduceMotion: reduceMotion)

                audienceBlock
                    .addPinboardEntrance(at: 2, hasAppeared: hasAppeared, reduceMotion: reduceMotion)

                roomBlock
                    .addPinboardEntrance(at: 3, hasAppeared: hasAppeared, reduceMotion: reduceMotion)

                deliveryBlock
                    .addPinboardEntrance(at: 4, hasAppeared: hasAppeared, reduceMotion: reduceMotion)

                expiryBlock
                    .addPinboardEntrance(at: 5, hasAppeared: hasAppeared, reduceMotion: reduceMotion)

                previewBlock
                    .addPinboardEntrance(at: 6, hasAppeared: hasAppeared, reduceMotion: reduceMotion)
            }
            .padding(.horizontal, addPinboardPageInset)
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
        .swipeBackEnabled()
        .safeAreaInset(edge: .bottom) {
            addBar
        }
        .task {
            NotificationCenter.default.post(name: .roostTabBarHiddenChanged, object: true)
            focusedField = .content
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
                    Text("Pinboard")
                        .font(.roostLabel)
                }
                .foregroundStyle(addPinboardAccent)
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(addPinboardAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(PinboardAddPressStyle(reduceMotion: reduceMotion))

            VStack(alignment: .leading, spacing: 5) {
                Text("ADD NOTE")
                    .font(.roostMeta)
                    .foregroundStyle(addPinboardAccent)
                    .tracking(1.0)

                Text("New note")
                    .font(.roostHero)
                    .foregroundStyle(Color.roostForeground)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
            }
        }
    }

    private var noteBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Message")

            TextField("Stick a note here", text: $content, axis: .vertical)
                .font(.roostCardTitle)
                .foregroundStyle(Color.roostForeground)
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(false)
                .lineLimit(4...8)
                .submitLabel(.done)
                .focused($focusedField, equals: .content)
                .padding(14)
                .frame(minHeight: 132, alignment: .topLeading)
                .background(Color.roostCard, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(focusedField == .content ? addPinboardAccent.opacity(0.62) : Color.roostHairline, lineWidth: focusedField == .content ? 1.5 : 1)
                )

            HStack(spacing: 8) {
                Image(systemName: "pin.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(addPinboardAccent)
                Text("Pinned notes stay visible until they are deleted or expire.")
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostMutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var audienceBlock: some View {
        compactSection(title: "Audience") {
            LazyVGrid(columns: compactColumns, spacing: 8) {
                choiceButton(
                    title: "Everyone",
                    detail: "Whole home",
                    isSelected: targetScope == .everyone,
                    tint: addPinboardAccent
                ) {
                    targetScope = .everyone
                }

                choiceButton(
                    title: currentMemberName ?? "Me",
                    detail: "Private",
                    isSelected: targetScope == .self,
                    tint: addPinboardAccent
                ) {
                    targetScope = .self
                }

                if let partnerName {
                    choiceButton(
                        title: partnerName,
                        detail: "Partner",
                        isSelected: targetScope == .partner,
                        tint: addPinboardAccent
                    ) {
                        targetScope = .partner
                    }
                }
            }
        }
    }

    private var roomBlock: some View {
        compactSection(title: "Room") {
            if rooms.isEmpty {
                Text("Add rooms in Settings to link a note to a place.")
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostMutedForeground)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.roostBackground.opacity(0.62), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                LazyVGrid(columns: compactColumns, spacing: 8) {
                    roomChoiceButton(title: "No room", detail: "General", isSelected: selectedRoomID == nil) {
                        selectedRoomID = nil
                    }

                    ForEach(rooms) { room in
                        roomChoiceButton(title: room.name, detail: "Linked", isSelected: selectedRoomID == room.id) {
                            selectedRoomID = room.id
                        }
                    }
                }
            }
        }
    }

    private var deliveryBlock: some View {
        compactSection(title: "Delivery") {
            LazyVGrid(columns: compactColumns, spacing: 8) {
                choiceButton(
                    title: "Notify",
                    detail: "Send alert",
                    isSelected: notifyOnCreate,
                    tint: notifyAccent
                ) {
                    notifyOnCreate = true
                }

                choiceButton(
                    title: "Silent",
                    detail: "Just pin it",
                    isSelected: !notifyOnCreate,
                    tint: notifyAccent
                ) {
                    notifyOnCreate = false
                }
            }
        }
    }

    private var expiryBlock: some View {
        compactSection(title: "Expiry") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    smallPill("Permanent", isSelected: !includeExpiry, tint: expiryAccent) {
                        includeExpiry = false
                    }
                    smallPill("Set expiry", isSelected: includeExpiry, tint: expiryAccent) {
                        includeExpiry = true
                    }
                }

                if includeExpiry {
                    HStack(spacing: 8) {
                        quickExpiryButton("Tomorrow", date: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
                        quickExpiryButton("1 week", date: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date())
                        quickExpiryButton("1 month", date: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date())
                    }

                    DatePicker("Date", selection: $expiryDate, in: Date()..., displayedComponents: .date)
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostForeground)
                        .padding(.horizontal, 12)
                        .frame(height: 44)
                        .background(Color.roostCard, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.roostHairline, lineWidth: 1)
                        )
                        .tint(expiryAccent)
                }
            }
        }
    }

    private var previewBlock: some View {
        compactSection(title: "Preview") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 7) {
                    previewPill(audienceLabel, systemImage: targetScope == .everyone ? "person.2" : "person")
                    if let selectedRoom {
                        previewPill(selectedRoom.name, systemImage: "link")
                    }
                    if includeExpiry {
                        previewPill(expiryLabel, systemImage: "clock")
                    }
                }

                Text(trimmedContent.isEmpty ? "Your note preview appears here." : trimmedContent)
                    .font(.roostBody)
                    .foregroundStyle(trimmedContent.isEmpty ? Color.roostMutedForeground : Color.roostForeground)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.roostBackground.opacity(0.58), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    private var addBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.roostHairline.opacity(0.65))
                .frame(height: 1)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedRoomLabel)
                        .font(.roostMeta)
                        .foregroundStyle(selectedRoom == nil ? Color.roostMutedForeground : roomAccent)
                        .lineLimit(1)

                    Text(trimmedContent.isEmpty ? "Waiting for a note" : trimmedContent)
                        .font(.roostLabel)
                        .foregroundStyle(Color.roostForeground)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Button {
                    Task { await addAndClose() }
                } label: {
                    Text(isSaving ? "Adding" : "Add note")
                        .font(.roostLabel)
                        .foregroundStyle(Color.roostCard)
                        .padding(.horizontal, 18)
                        .frame(height: 48)
                        .background(canSubmit ? addPinboardAccent : Color.roostMutedForeground.opacity(0.34), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(PinboardAddPressStyle(reduceMotion: reduceMotion))
                .disabled(!canSubmit)
            }
            .padding(.horizontal, addPinboardPageInset)
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
        .buttonStyle(PinboardAddPressStyle(reduceMotion: reduceMotion))
    }

    private func roomChoiceButton(title: String, detail: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.roostEaseOut) {
                action()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.roostCard : roomAccent)

                VStack(alignment: .leading, spacing: 2) {
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

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(height: 50)
            .background(isSelected ? roomAccent : Color.roostCard.opacity(0.82), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? roomAccent.opacity(0.35) : roomAccent.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PinboardAddPressStyle(reduceMotion: reduceMotion))
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
        .buttonStyle(PinboardAddPressStyle(reduceMotion: reduceMotion))
    }

    private func quickExpiryButton(_ title: String, date: Date) -> some View {
        let selected = Calendar.current.isDate(expiryDate, inSameDayAs: date)

        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.roostEaseOut) {
                expiryDate = date
                includeExpiry = true
            }
        } label: {
            Text(title)
                .font(.roostMeta)
                .foregroundStyle(selected ? Color.roostCard : Color.roostForeground)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(selected ? expiryAccent : expiryAccent.opacity(0.09), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(selected ? expiryAccent.opacity(0.28) : expiryAccent.opacity(0.18), lineWidth: 1)
                )
        }
        .buttonStyle(PinboardAddPressStyle(reduceMotion: reduceMotion))
    }

    private func previewPill(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .semibold))
            Text(title)
                .lineLimit(1)
        }
        .font(.roostMeta)
        .foregroundStyle(addPinboardAccent)
        .padding(.horizontal, 9)
        .frame(height: 28)
        .background(addPinboardAccent.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func addAndClose() async {
        let submittedContent = trimmedContent
        guard !submittedContent.isEmpty, !isSaving else { return }
        isSaving = true
        focusedField = nil
        await onAdd(
            submittedContent,
            targetScope,
            notifyOnCreate,
            includeExpiry ? expiryDate : nil,
            selectedRoom
        )
        isSaving = false
        dismiss()
    }

    private var trimmedContent: String {
        content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var audienceLabel: String {
        switch targetScope {
        case .everyone:
            return "For everyone"
        case .self:
            return currentMemberName.map { "For \($0)" } ?? "For me"
        case .partner:
            return partnerName.map { "For \($0)" } ?? "For partner"
        }
    }

    private var selectedRoomLabel: String {
        selectedRoom?.name ?? "No room"
    }

    private var expiryLabel: String {
        "Expires \(expiryDate.formatted(.dateTime.day().month(.abbreviated)))"
    }
}

private let addPinboardPageInset: CGFloat = 12
private let addPinboardAccent = Color.roostShoppingTint
private let roomAccent = Color.roostChoreTint
private let notifyAccent = Color.roostPrimary
private let expiryAccent = Color.roostMoneyTint

private let compactColumns = [
    GridItem(.flexible(), spacing: 8),
    GridItem(.flexible(), spacing: 8)
]

private struct PinboardAddPressStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(reduceMotion ? nil : DesignSystem.Motion.buttonPress, value: configuration.isPressed)
    }
}

private struct AddPinboardEntranceModifier: ViewModifier {
    let index: Int
    let hasAppeared: Bool
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: reduceMotion || hasAppeared ? 0 : CGFloat(16 + (index * 4)))
            .animation(reduceMotion ? nil : .roostSmooth.delay(Double(index) * 0.04), value: hasAppeared)
    }
}

private extension View {
    func addPinboardEntrance(at index: Int, hasAppeared: Bool, reduceMotion: Bool) -> some View {
        modifier(AddPinboardEntranceModifier(index: index, hasAppeared: hasAppeared, reduceMotion: reduceMotion))
    }
}

#Preview("Add Pinboard Note") {
    NavigationStack {
        AddPinboardNoteSheet(
            currentMemberName: "Tom",
            partnerName: "Alex",
            rooms: [
                Room(id: UUID(), homeID: UUID(), name: "Kitchen", icon: nil),
                Room(id: UUID(), homeID: UUID(), name: "Bathroom", icon: nil)
            ]
        ) { _, _, _, _, _ in }
    }
}
